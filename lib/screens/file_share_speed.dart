import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';

void main() => runApp(const TransCryptApp());

/// --- Encryption Key Pair ---
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

/// --- API SERVICE ---
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

/// --- APP ROOT ---
class TransCryptApp extends StatelessWidget {
  const TransCryptApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransCrypt',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

/// --- HOME SCREEN ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 80, color: Color(0xFF3B82F6)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Sender"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
                backgroundColor: const Color(0xFF3B82F6),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SenderScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Receiver"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 50),
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiverScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- SENDER SCREEN ---
class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});
  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  File? _selectedFile;
  KeysPair? _keyPair;
  bool _startingServer = false;
  String _status = "Idle";

  @override
  void initState() {
    super.initState();
    KeysPair.generateKeyPair().then((k) => setState(() => _keyPair = k));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path != null) {
      setState(() => _selectedFile = File(result!.files.single.path!));
    }
  }

  Future<void> _startServer() async {
    if (_selectedFile == null || _keyPair == null) return;
    setState(() {
      _startingServer = true;
      _status = "Uploading file...";
    });

    try {
      await ApiService.uploadFile(_selectedFile!, _keyPair!);
      setState(() => _status = "File uploaded successfully!");
    } catch (e) {
      setState(() => _status = "Upload failed: $e");
    } finally {
      setState(() => _startingServer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("Sender")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  color: const Color(0xFF1E293B),
                ),
                child: Center(
                  child: _selectedFile == null
                      ? const Text("Tap to select file", style: TextStyle(color: Colors.white))
                      : Text(
                          path.basename(_selectedFile!.path),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedFile != null)
              Text(
                "Path: ${_selectedFile!.path}",
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startingServer ? null : _startServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_startingServer ? "Starting..." : "Start Server"),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// --- RECEIVER SCREEN ---
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});
  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  bool _scanning = false;
  List<Map<String, String>> _devices = [];

  Future<void> _scanDevices() async {
    setState(() {
      _scanning = true;
      _devices = [];
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate scanning

    setState(() {
      _scanning = false;
      _devices = [
        {"name": "Preetham's Laptop", "ip": "192.168.1.12"},
        {"name": "Office-PC", "ip": "192.168.1.45"},
      ];
    });
  }

  Future<void> _connectToDevice(String ip) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to $ip. Saving to $result")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("Receiver")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _scanning ? null : _scanDevices,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_scanning ? "Scanning..." : "Scan for Devices"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        _scanning ? "Scanning devices..." : "No devices found.",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          child: ListTile(
                            title: Text(device['name']!, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(device['ip']!, style: const TextStyle(color: Colors.grey)),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToDevice(device['ip']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                              ),
                              child: const Text("Connect"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
