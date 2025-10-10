import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Enhanced AuthService that integrates with presence/profile system
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Ensure profile exists and is marked online
      if (response.user != null) {
        await _ensureProfileExists(response.user!);
      }

      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      // Create profile for new user
      if (response.user != null) {
        await _createProfile(
          user: response.user!,
          fullName: fullName,
        );
      }

      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Mark user as offline before signing out
      if (currentUser != null) {
        await _markOffline(currentUser!.id);
      }

      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Reset password for email
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Update password error: $e');
      rethrow;
    }
  }

  /// Update user profile information
  Future<void> updateProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      // Update auth metadata if needed
      if (fullName != null || email != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            email: email,
            data: fullName != null ? {'full_name': fullName} : null,
          ),
        );
      }

      // Update profile table
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (email != null) updates['email'] = email;

      if (updates.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(updates)
            .eq('id', currentUserId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  /// Ensure profile exists for user (called on sign in)
  Future<void> _ensureProfileExists(User user) async {
    try {
      // Check if profile exists
      final existing = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // Create profile if it doesn't exist
        await _createProfile(user: user);
      } else {
        // Update existing profile to mark online
        await _supabase.from('profiles').update({
          'is_online': true,
          'last_seen': DateTime.now().toIso8601String(),
          'email': user.email ?? existing['email'],
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Ensure profile exists error: $e');
      // Don't throw - profile creation shouldn't block authentication
    }
  }

  /// Create a new profile for user
  Future<void> _createProfile({
    required User user,
    String? fullName,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': fullName ?? user.userMetadata?['full_name'],
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create profile error: $e');
      // Don't throw - profile creation shouldn't block authentication
    }
  }

  /// Mark user as offline
  Future<void> _markOffline(String userId) async {
    try {
      await _supabase.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Mark offline error: $e');
      // Don't throw - this shouldn't block sign out
    }
  }

  /// Get profile for specific user
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }
} 