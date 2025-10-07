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
  String? _selectedFilePath;
  bool _isServerRunning = false;
  bool _isReceiving = false;
  bool _scanning = false;
  List<DeviceInfo> _foundServers = [];
  DeviceInfo? _selectedServer;

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
                title: Text(_selectedFilePath ?? "No file selected"),
                trailing: IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(_isServerRunning ? "Server Running..." : "Send File"),
                onPressed: _selectedFilePath == null || _isServerRunning ? null : _startFileServer,
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
                label: Text(_isReceiving ? "Receiving..." : "Receive File"),
                onPressed: _selectedServer == null || _isReceiving ? null : _receiveFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PICK FILE TO SEND
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFilePath = result.files.single.path);
    }
  }

  // START FILE SERVER
  Future<void> _startFileServer() async {
    if (_selectedFilePath == null) return;
    setState(() => _isServerRunning = true);

    await FileSender.startFileServer(_selectedFilePath!, context);

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

  // RECEIVE FILE
  Future<void> _receiveFile() async {
    if (_selectedServer == null) return;
    setState(() => _isReceiving = true);

    final saveResult = await FilePicker.platform.saveFile(
      dialogTitle: "Save Received File As",
      fileName: "received_file",
    );

    if (saveResult != null) {
      await FileReceiver.downloadFile(_selectedServer!.wifiIP, saveResult);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File saved to $saveResult")),
        );
      }
    }

    setState(() => _isReceiving = false);
  }
}
