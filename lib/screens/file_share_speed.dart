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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TransCrypt File Transfer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // FILE PICKER + SEND
              ListTile(
                title: Text(_selectedFiles.isEmpty
                    ? "No files selected"
                    : "${_selectedFiles.length} file(s) selected"),
                trailing: IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFiles,
                ),
              ),
              if (_selectedFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedFiles.map((f) => Text(f.split('/').last)).toList(),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(_isServerRunning ? "Server Running..." : "Send Files"),
                onPressed: _selectedFiles.isEmpty || _isServerRunning
                    ? null
                    : _startFileServer,
              ),
              const Divider(height: 32),

              // SCAN NETWORK + LIST SERVERS
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Scan for Servers"),
                onPressed: _scanning ? null : _scanNetwork,
              ),
              if (_scanning)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const LinearProgressIndicator(),
                ),
              const SizedBox(height: 10),
              if (_foundServers.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Available Servers:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._foundServers.map((server) => ListTile(
                      leading: const Icon(Icons.router),
                      title: Text(server.wifiIP),
                      trailing: Radio<DeviceInfo>(
                        value: server,
                        groupValue: _selectedServer,
                        onChanged: (val) => setState(() => _selectedServer = val),
                      ),
                    )),
                  ],
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(_isReceiving ? "Receiving..." : "Receive File(s)"),
                onPressed: _selectedServer == null || _isReceiving ? null : _receiveFiles,
              ),
              if (_isReceiving)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Speed: ${(_transferSpeed * 8 / 1000000).toStringAsFixed(2)} Mbps",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                ),
            ],
          ),
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
    await FileSender.startFileServerMultiple(files, context); // Use new multi-file server function

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

// RECEIVE FILES

}

