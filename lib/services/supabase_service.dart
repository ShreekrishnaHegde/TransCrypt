import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Fetch transfer history
  Future<List<Map<String, dynamic>>> fetchTransferHistory() async {
    final response = await _supabase
        .from('transfer_history')
        .select()
        .order('created_at', ascending: false);

    return response;
  }
}
