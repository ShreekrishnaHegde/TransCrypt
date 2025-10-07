import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:transcrypt/models/DeviceInfoModel.dart';
import 'package:transcrypt/service/ReceiverService.dart';
import 'package:transcrypt/service/SenderService.dart';

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  List<String> _selectedFiles = [];
  bool _isServerRunning = false;
  bool _isReceiving = false;
  bool _scanning = false;
  List<DeviceInfo> _foundServers = [];
  DeviceInfo? _selectedServer;
  double _transferSpeed = 0.0;
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
                ),
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "File Transfer",
              style: TextStyle(
                color: _isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isDark ? Icons.wb_sunny : Icons.nightlight_round, color: _isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569)),
            onPressed: () => setState(() => _isDark = !_isDark),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEND FILE SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.upload_file, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Send Files",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedFiles.isEmpty ? Icons.attach_file : Icons.folder_open,
                              color: const Color(0xFF3B82F6),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFiles.isEmpty
                                    ? "Tap to select files"
                                    : "${_selectedFiles.length} file(s) selected",
                                style: TextStyle(
                                  color: _isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selected Files:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._selectedFiles.take(3).map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.insert_drive_file, size: 14, color: _isDark ? Colors.white54 : Colors.black45),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f.split('/').last,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isDark ? Colors.white60 : Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (_selectedFiles.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "and ${_selectedFiles.length - 3} more...",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: _isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedFiles.isEmpty || _isServerRunning ? null : _startFileServer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          disabledBackgroundColor: const Color(0xFF64748B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isServerRunning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Start Server", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // RECEIVE FILE SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.download, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Receive Files",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _scanning ? null : _scanNetwork,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: const Color(0xFF64748B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _scanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Scan Network", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    if (_scanning)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator(
                          backgroundColor: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    if (_foundServers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Available Servers:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: _foundServers.map((server) => Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: RadioListTile<DeviceInfo>(
                              value: server,
                              groupValue: _selectedServer,
                              onChanged: (val) => setState(() => _selectedServer = val),
                              title: Text(
                                server.wifiIP,
                                style: TextStyle(
                                  color: _isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.router, color: Color(0xFF10B981), size: 20),
                              ),
                              activeColor: const Color(0xFF10B981),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _selectedServer == null || _isReceiving ? null : _receiveFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            disabledBackgroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: _isReceiving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.download, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text("Receive Files", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // TRANSFER PROGRESS SECTION
              if (_isReceiving) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.speed, color: Color(0xFF8B5CF6), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Transfer Progress",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar with Speed
                      Stack(
                        children: [
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              minHeight: 60,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF10B981).withOpacity(0.3),
                              ),
                            ),
                          ),
                          Container(
                            height: 60,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.download_rounded,
                                      color: _isDark ? Colors.white : Colors.black87,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Receiving...",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(_transferSpeed * 8 / 1000000).toStringAsFixed(2)} Mbps",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpeedStat(
                            "Download Speed",
                            "${(_transferSpeed / 1024 / 1024).toStringAsFixed(2)} MB/s",
                            Icons.download,
                            const Color(0xFF10B981),
                          ),
                          _buildSpeedStat(
                            "Network",
                            "${(_transferSpeed * 8 / 1000000).toStringAsFixed(1)} Mbps",
                            Icons.network_check,
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: _isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveFiles() async {
    if (_selectedServer == null) return;
    setState(() {
      _isReceiving = true;
      _transferSpeed = 0;
    });

    final saveDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Select Folder to Save Files");
    if (saveDir != null) {
      await FileReceiver.downloadMultipleFiles(
        _selectedServer!.wifiIP,
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

    setState(() => _isReceiving = false);
  }

  // PICK MULTIPLE FILES
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _selectedFiles = result.files.map((f) => f.path!).toList());
    }
  }

  // START FILE SERVER (MULTIPLE FILES)
  Future<void> _startFileServer() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _isServerRunning = true);

    final files = _selectedFiles.map((path) => File(path)).toList();
    await FileSender.startFileServerMultiple(files, context);

    setState(() => _isServerRunning = false);
  }

  // SCAN NETWORK
  Future<void> _scanNetwork() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) return;

    final subnet = FileReceiver.getSubnet(ip);

    setState(() {
      _scanning = true;
      _foundServers.clear();
    });

    final devices = await FileReceiver.scanForServers(subnet);
    setState(() {
      _foundServers = devices;
      _scanning = false;
    });
  }
}