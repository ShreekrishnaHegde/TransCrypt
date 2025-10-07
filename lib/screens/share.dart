import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';

void main() => runApp(const TransCryptApp());

class KeysPair {
  SimplePublicKey publicKey;
  KeyPair privateKey;
  KeysPair({required this.privateKey, required this.publicKey});

  static Future<KeysPair> generateKeyPair() async {
    final algo = X25519();
    final keyPair = await algo.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return KeysPair(privateKey: keyPair, publicKey: publicKey);
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<SimplePublicKey> getServerPublicKey() async {
    final response = await http.get(Uri.parse('$baseUrl/public-key'));
    final data = jsonDecode(response.body);
    return SimplePublicKey(base64Decode(data['publicKey']), type: KeyPairType.x25519);
  }

  static Future<Map<String, dynamic>> uploadFile(File file, KeysPair clientKeyPair) async {
    await getServerPublicKey();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['publicKey'] = base64Encode(clientKeyPair.publicKey.bytes);
    var response = await http.Response.fromStream(await request.send());
    return jsonDecode(response.body);
  }
}

class TransCryptApp extends StatelessWidget {
  const TransCryptApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TransCrypt', debugShowCheckedModeBanner: false, home: const TransCryptHome());
}

class TransCryptHome extends StatefulWidget {
  const TransCryptHome({Key? key}) : super(key: key);
  @override
  State<TransCryptHome> createState() => _TransCryptHomeState();
}

class _TransCryptHomeState extends State<TransCryptHome> {
  bool isDark = true;

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [color, color.withOpacity(0.7)])),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    appBar: AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)])),
          child: const Center(child: Text('T', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Text('TransCrypt', style: TextStyle(color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
      actions: [IconButton(icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round), onPressed: () => setState(() => isDark = !isDark))],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.swap_horiz, size: 48, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(height: 40),
        Row(children: [
          _buildButton('Sender', Icons.send, const Color(0xFF3B82F6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileUploadScreen(isDarkMode: isDark)))),
          const SizedBox(width: 12),
          _buildButton('Receiver', Icons.download, const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileReceiverScreen(isDarkMode: isDark)))),
        ]),
      ]),
    ),
  );
}

class FileUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  const FileUploadScreen({Key? key, this.isDarkMode = true}) : super(key: key);
  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  late bool isDark;
  File? _file;
  bool _uploading = false;
  KeysPair? _keyPair;
  String _status = '';

  @override
  void initState() {
    super.initState();
    isDark = widget.isDarkMode;
    KeysPair.generateKeyPair().then((k) => setState(() => _keyPair = k));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path != null) setState(() => _file = File(result!.files.single.path!));
  }

  Future<void> _sendFile() async {
    if (_file == null || _keyPair == null) return;
    setState(() { _uploading = true; _status = 'Uploading...'; });
    try {
      await ApiService.uploadFile(_file!, _keyPair!);
      setState(() => _status = 'Success!');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded!')));
      await Future.delayed(const Duration(seconds: 1));
      setState(() { _uploading = false; _file = null; });
    } catch (e) {
      setState(() { _status = 'Failed: $e'; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    appBar: AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      title: const Text('Send File'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (_keyPair != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
          child: const Row(children: [Icon(Icons.lock, color: Colors.green, size: 16), SizedBox(width: 8), Text('Encrypted')]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _uploading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(_file == null ? Icons.upload_file : Icons.insert_drive_file, size: 60, color: const Color(0xFF3B82F6)),
              const SizedBox(height: 16),
              Text(_file == null ? 'Tap to select file' : path.basename(_file!.path), style: const TextStyle(fontSize: 16)),
            ]),
          ),
        ),
        if (_uploading) Padding(padding: const EdgeInsets.all(16), child: Text(_status)),
        const Spacer(),
        if (_file != null) SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: _uploading ? null : _sendFile,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _uploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send File', style: TextStyle(color: Colors.white)),
          ),
        ),
      ]),
    ),
  );
}

class FileReceiverScreen extends StatelessWidget {
  final bool isDarkMode;
  const FileReceiverScreen({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    appBar: AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      title: const Text('Receive File'),
    ),
    body: Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.download_rounded, size: 80, color: Color(0xFF10B981)),
          SizedBox(height: 24),
          Text('Waiting for files...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Text('Files sent to you will appear here', textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}