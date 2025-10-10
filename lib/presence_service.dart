import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for online user data
class OnlineUser {
  final String id;
  final String email;
  final String? fullName;
  final bool isOnline;
  final DateTime lastSeen;

  OnlineUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.isOnline,
    required this.lastSeen,
  });

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    return OnlineUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: DateTime.parse(json['last_seen'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}

/// Service to manage user presence and online status
class PresenceService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _presenceChannel;
  Timer? _heartbeatTimer;
  StreamSubscription? _authSubscription;

  // List of currently online users
  final List<OnlineUser> _onlineUsers = [];
  List<OnlineUser> get onlineUsers => List.unmodifiable(_onlineUsers);

  // Error state
  String? _error;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the presence service
  /// Should be called after user authentication
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _error = null;

      // Listen to auth state changes
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _handleSignIn(session.user);
        } else if (event == AuthChangeEvent.signedOut) {
          _handleSignOut();
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          // Keep presence alive on token refresh
          _updateHeartbeat();
        }
      });

      // If user is already signed in, handle it
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await _handleSignIn(currentUser);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize presence: $e';
      notifyListeners();
      debugPrint('PresenceService initialization error: $e');
    }
  }

  /// Handle user sign in
  Future<void> _handleSignIn(User user) async {
    try {
      _error = null;

      // Upsert user profile with online status
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });

      // Setup realtime presence channel
      await _setupPresenceChannel(user.id);

      // Start heartbeat to keep last_seen updated
      _startHeartbeat();

      // Load initial online users
      await _loadOnlineUsers();

      notifyListeners();
    } catch (e) {
      _error = 'Failed to set online status: $e';
      notifyListeners();
      debugPrint('Sign in handler error: $e');
    }
  }

  /// Handle user sign out
  Future<void> _handleSignOut() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        // Mark user as offline
        await _supabase
            .from('profiles')
            .update({
              'is_online': false,
              'last_seen': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);
      }

      // Clean up
      await _cleanup();

      notifyListeners();
    } catch (e) {
      debugPrint('Sign out handler error: $e');
      // Still cleanup even if update fails
      await _cleanup();
    }
  }

  /// Setup Realtime presence channel
  Future<void> _setupPresenceChannel(String userId) async {
    // Remove existing channel if any
    if (_presenceChannel != null) {
      await _supabase.removeChannel(_presenceChannel!);
      _presenceChannel = null;
    }

    // Create new presence channel
    _presenceChannel = _supabase.channel(
      'online-users',
      opts: const RealtimeChannelConfig(
        self: true, // Include own presence
      ),
    );

    // Track this user's presence
    _presenceChannel!
        .onPresenceSync((_) {
          _handlePresenceSync();
        })
        .onPresenceJoin((payload) {
          _handlePresenceJoin(payload);
        })
        .onPresenceLeave((payload) {
          _handlePresenceLeave(payload);
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track current user
            await _presenceChannel!.track({
              'user_id': userId,
              'online_at': DateTime.now().toIso8601String(),
            });
          } else if (status == RealtimeSubscribeStatus.channelError) {
            _error = 'Presence channel error: $error';
            notifyListeners();
            debugPrint('Presence channel error: $error');
          }
        });

    // Also listen to database changes for profile updates
    _presenceChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        _handleProfileUpdate(payload);
      },
    );
  }

  /// Handle presence sync (full state)
  void _handlePresenceSync() {
    if (_presenceChannel == null) return;

    final state = _presenceChannel!.presenceState();
    debugPrint('Presence sync: ${state.length} users online');
  }

  /// Handle new user joining
  void _handlePresenceJoin(RealtimePresencePayload payload) {
    debugPrint('User joined: ${payload.event}');
    // Reload online users to get latest data
    _loadOnlineUsers();
  }

  /// Handle user leaving
  void _handlePresenceLeave(RealtimePresencePayload payload) {
    debugPrint('User left: ${payload.event}');
    // Reload online users to get latest data
    _loadOnlineUsers();
  }

  /// Handle profile updates from database
  void _handleProfileUpdate(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final userId = newRecord['id'] as String;
      final isOnline = newRecord['is_online'] as bool?;

      // Update local list
      final index = _onlineUsers.indexWhere((u) => u.id == userId);

      if (isOnline == true && index == -1) {
        // User came online, add to list
        _onlineUsers.add(OnlineUser.fromJson(newRecord));
        notifyListeners();
      } else if (isOnline == false && index != -1) {
        // User went offline, remove from list
        _onlineUsers.removeAt(index);
        notifyListeners();
      } else if (index != -1) {
        // User data updated, refresh
        _onlineUsers[index] = OnlineUser.fromJson(newRecord);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling profile update: $e');
    }
  }

  /// Load online users from database
  Future<void> _loadOnlineUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('is_online', true)
          .order('last_seen', ascending: false);

      _onlineUsers.clear();
      _onlineUsers.addAll(
        (response as List).map((json) => OnlineUser.fromJson(json)),
      );

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load online users: $e';
      notifyListeners();
      debugPrint('Load online users error: $e');
    }
  }

  /// Start heartbeat timer to update last_seen
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // Update last_seen every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateHeartbeat();
    });
  }

  /// Update last_seen timestamp
  Future<void> _updateHeartbeat() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('profiles')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('id', currentUser.id);
    } catch (e) {
      debugPrint('Heartbeat update error: $e');
      // Don't throw, just log - heartbeat failures shouldn't break the app
    }
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_presenceChannel != null) {
      try {
        await _supabase.removeChannel(_presenceChannel!);
      } catch (e) {
        debugPrint('Error removing presence channel: $e');
      }
      _presenceChannel = null;
    }

    _onlineUsers.clear();
    _error = null;
  }

  /// Manually refresh online users list
  Future<void> refresh() async {
    await _loadOnlineUsers();
  }

  @override
  void dispose() {
    _cleanup();
    _authSubscription?.cancel();
    super.dispose();
  }
}
