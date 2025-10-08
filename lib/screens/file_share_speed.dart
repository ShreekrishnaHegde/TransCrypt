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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransCrypt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const TransCryptHome(),
    );
  }
}

class TransCryptHome extends StatefulWidget {
  const TransCryptHome({Key? key}) : super(key: key);
  
  @override
  State<TransCryptHome> createState() => _TransCryptHomeState();
}

class _TransCryptHomeState extends State<TransCryptHome> with TickerProviderStateMixin {
  bool _scanningDevices = false;
  late AnimationController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (index) {
                    return Transform.scale(
                      scale: 0.5 + (_searchController.value * 0.5) + (index * 0.2),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3 - (index * 0.1)),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.radar,
                      size: 50,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Scanning for devices...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Looking for nearby devices',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 64,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    _buildButton(
                      label: 'Sender',
                      icon: Icons.send_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FileUploadScreen(isDarkMode: true),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildButton(
                      label: 'Receiver',
                      icon: Icons.download_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        setState(() => _scanningDevices = true);
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() => _scanningDevices = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FileReceiverScreen(isDarkMode: true),
                              ),
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_scanningDevices) _buildScanningAnimation(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  const FileUploadScreen({Key? key, this.isDarkMode = true}) : super(key: key);
  
  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> with SingleTickerProviderStateMixin {
  late bool isDark;
  File? _file;
  bool _uploading = false;
  KeysPair? _keyPair;
  String _status = '';
  double _progress = 0.0;
  late AnimationController _uploadController;

  @override
  void initState() {
    super.initState();
    isDark = widget.isDarkMode;
    _uploadController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    KeysPair.generateKeyPair().then((k) {
      if (mounted) {
        setState(() => _keyPair = k);
      }
    });
  }

  @override
  void dispose() {
    _uploadController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result?.files.single.path != null) {
      setState(() => _file = File(result!.files.single.path!));
    }
  }

  Future<void> _sendFile() async {
    if (_file == null || _keyPair == null) return;
    setState(() {
      _uploading = true;
      _status = 'Uploading...';
      _progress = 0;
    });
    _uploadController.repeat();

    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _progress = i / 100);
    }

    try {
      await ApiService.uploadFile(_file!, _keyPair!);
      if (mounted) {
        setState(() => _status = 'Success!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _uploading = false;
          _file = null;
          _progress = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Failed: $e';
          _uploading = false;
        });
      }
    } finally {
      _uploadController.stop();
      _uploadController.reset();
    }
  }

  Widget _buildUploadAnimation() {
    return AnimatedBuilder(
      animation: _uploadController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload_rounded,
                        size: 40,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Send File',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_keyPair != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'End-to-end Encrypted',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _uploading ? null : _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _file != null
                            ? const Color(0xFF3B82F6)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _file == null ? Icons.upload_file_rounded : Icons.insert_drive_file_rounded,
                          size: 56,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _file == null ? 'Tap to select file' : path.basename(_file!.path),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_uploading) _buildUploadAnimation(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              if (_file != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _uploading ? null : _sendFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send File',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
class FileReceiverScreen extends StatelessWidget {
  final bool isDarkMode;
  const FileReceiverScreen({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Receive File',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable receiver body
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              size: 72,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Waiting for files...',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Files sent to you will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
