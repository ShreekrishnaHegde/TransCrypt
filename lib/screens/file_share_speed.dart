import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:transcrypt/models/DeviceInfoModel.dart';
import 'package:transcrypt/service/ReceiverService.dart';
import 'package:transcrypt/service/SenderService.dart';

void main() => runApp(const TransCryptApp());

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
          brightness: Brightness.dark,
        ),
      ),
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
                            builder: (context) => const SenderScreen(),
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
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() => _scanningDevices = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReceiverScreen(),
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

// SENDER SCREEN
class SenderScreen extends StatefulWidget {
  const SenderScreen({Key? key}) : super(key: key);
  
  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  List<String> _selectedFiles = [];
  bool _isServerRunning = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _selectedFiles = result.files.map((f) => f.path!).toList());
    }
  }

  Future<void> _startFileServer() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _isServerRunning = true);

    final files = _selectedFiles.map((path) => File(path)).toList();
    await FileSender.startFileServerMultiple(files, context);

    setState(() => _isServerRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Send Files',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // File Picker Box
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isServerRunning ? null : _pickFiles,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedFiles.isNotEmpty
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF334155),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _selectedFiles.isEmpty
                                    ? Icons.upload_file_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 56,
                                color: const Color(0xFF3B82F6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFiles.isEmpty
                                    ? 'Tap to select files'
                                    : '${_selectedFiles.length} file(s) selected',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // File List
                    if (_selectedFiles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Files:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_selectedFiles.length > 5
                                ? _selectedFiles.take(5).toList()
                                : _selectedFiles)
                                .map((filePath) {
                              final fileName = filePath.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Color(0xFF60A5FA),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (_selectedFiles.length > 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '+ ${_selectedFiles.length - 5} more files',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    // Start Server Button
                    if (_selectedFiles.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isServerRunning ? null : _startFileServer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            _isServerRunning ? Icons.stop_circle : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isServerRunning ? 'Server Running...' : 'Start Server',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Server Status
                    if (_isServerRunning)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Server is running. Waiting for receiver to connect...',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// RECEIVER SCREEN
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({Key? key}) : super(key: key);
  
  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  bool _scanning = false;
  List<DeviceInfo> _foundServers = [];
  DeviceInfo? _selectedServer;
  bool _isReceiving = false;
  double _transferSpeed = 0.0;

  Future<void> _scanNetwork() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get WiFi IP. Please check your connection.')),
        );
      }
      return;
    }

    final subnet = FileReceiver.getSubnet(ip);

    setState(() {
      _scanning = true;
      _foundServers.clear();
      _selectedServer = null;
    });

    final devices = await FileReceiver.scanForServers(subnet);
    
    if (mounted) {
      setState(() {
        _foundServers = devices;
        _scanning = false;
      });

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No servers found. Make sure sender has started the server.')),
        );
      }
    }
  }

  Future<void> _receiveFiles(DeviceInfo server) async {
    setState(() {
      _selectedServer = server;
      _isReceiving = true;
      _transferSpeed = 0;
    });

    final saveDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select Folder to Save Files",
    );
    
    if (saveDir != null) {
      await FileReceiver.downloadMultipleFiles(
        server.wifiIP,
        saveDir,
        onSpeedUpdate: (speed) {
          if (mounted) {
            setState(() {
              _transferSpeed = speed;
            });
          }
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Files saved to $saveDir")),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isReceiving = false;
        _selectedServer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Receive Files',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Scan Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _scanning || _isReceiving ? null : _scanNetwork,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _scanning ? Icons.hourglass_empty : Icons.radar,
                          color: Colors.white,
                        ),
                        label: Text(
                          _scanning ? 'Scanning...' : 'Scan for Devices',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Scanning Progress
                    if (_scanning)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              backgroundColor: Color(0xFF334155),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Scanning network for available devices...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    // Device List
                    if (_foundServers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Devices (${_foundServers.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _foundServers.length,
                        itemBuilder: (context, index) {
                          final server = _foundServers[index];
                          final isSelected = _selectedServer?.wifiIP == server.wifiIP;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.computer_rounded,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Device',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          server.wifiIP,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: _isReceiving
                                          ? null
                                          : () => _receiveFiles(server),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        disabledBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Connect',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    // Receiving Status
                    if (_isReceiving) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Receiving Files...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Speed: ${(_transferSpeed * 8 / 1000000).toStringAsFixed(2)} Mbps',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Empty State
                    if (!_scanning && _foundServers.isEmpty) ...[
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Scan for Devices" to find available senders',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}