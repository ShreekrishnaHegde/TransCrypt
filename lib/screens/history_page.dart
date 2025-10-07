import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HistoryPage extends StatefulWidget {
  final bool isDarkMode;
  const HistoryPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _supabaseService.fetchTransferHistory();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return _emptyHistory(dark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, i) {
            final item = history[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF1E293B).withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    color: dark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['filename'] ?? 'Unknown File',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['size']}  •  ${item['status']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item['created_at']
                            ?.toString()
                            .substring(0, 10)
                            .replaceAll('-', '/') ??
                        '',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyHistory(bool dark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: dark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Transfer History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start sharing files to see them here!',
              style: TextStyle(
                color: dark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
