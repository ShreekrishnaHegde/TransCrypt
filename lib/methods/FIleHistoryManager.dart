import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transcrypt/models/FileHistory.dart';

class FileHistoryManager {
  static const String _key = 'file_history';

  static Future<List<FileHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => FileHistory.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> addHistory(FileHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    data.add(jsonEncode(history.toJson()));
    await prefs.setStringList(_key, data);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
