import 'package:flutter/material.dart';
import 'package:transcrypt/methods/FIleHistoryManager.dart';
import 'package:transcrypt/models/FileHistory.dart';

class FileHistoryPage extends StatefulWidget {
  const FileHistoryPage({super.key});

  @override
  State<FileHistoryPage> createState() => _FileHistoryPageState();
}

class _FileHistoryPageState extends State<FileHistoryPage> {
  List<FileHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final history = await FileHistoryManager.getHistory();
    setState(() => _history = history.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("File Transfer History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await FileHistoryManager.clearHistory();
              _loadHistory();
            },
          )
        ],
      ),
      body: _history.isEmpty
          ? const Center(child: Text("No history yet"))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return ListTile(
            leading: Icon(item.status == 'Sent'
                ? Icons.upload_file
                : Icons.download),
            title: Text(item.fileName),
            subtitle: Text(
                "${item.fileFormat.toUpperCase()} • ${item.fileSize} bytes\n${item.dateTime} • IP: ${item.remoteIp ?? 'Local'}"),
            trailing: Text(item.status,
                style: TextStyle(
                    color: item.status == 'Sent'
                        ? Colors.green
                        : Colors.blue)),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
