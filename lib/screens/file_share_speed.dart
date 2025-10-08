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
  List<String> selectedFiles = [];
  bool isServerRunning = false;
  bool isReceiving = false;
  bool isScanning = false;
  List<DeviceInfo> foundServers = [];
  DeviceInfo? selectedServer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TransCrypt File Transfer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFilePicker(),
              const Divider(),
              _buildScanner(),
              const Divider(),
              _buildReceiver(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        title: Text(selectedFiles.isEmpty
            ? "No files selected"
            : "${selectedFiles.length} file(s) selected"),
        trailing: IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: _pickFiles,
        ),
      ),
      ...selectedFiles.map((p) => Text(p.split('/').last)),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: Text(isServerRunning ? "Server Running..." : "Send Files"),
        onPressed:
        selectedFiles.isEmpty || isServerRunning ? null : _startServer,
      ),
    ],
  );

  Widget _buildScanner() => Column(
    children: [
      ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: const Text("Scan for Servers"),
        onPressed: isScanning ? null : _scanNetwork,
      ),
      if (isScanning) const LinearProgressIndicator(),
      if (foundServers.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Available Servers:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...foundServers.map((s) => ListTile(
              leading: const Icon(Icons.router),
              title: Text(s.wifiIP),
              trailing: Radio<DeviceInfo>(
                value: s,
                groupValue: selectedServer,
                onChanged: (v) => setState(() => selectedServer = v),
              ),
            )),
          ],
        ),
    ],
  );

  Widget _buildReceiver() => ElevatedButton.icon(
    icon: const Icon(Icons.download),
    label: Text(isReceiving ? "Receiving..." : "Receive Files"),
    onPressed: selectedServer == null || isReceiving ? null : _receiveFiles,
  );

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => selectedFiles = result.paths.whereType<String>().toList());
    }
  }

  Future<void> _startServer() async {
    setState(() => isServerRunning = true);
    final files = selectedFiles.map((p) => File(p)).toList();
    await FileSender.startFileServerMultiple(files, context);
    if (mounted) setState(() => isServerRunning = false);
  }

  Future<void> _scanNetwork() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) return;

    final subnet = FileReceiver.getSubnet(ip);
    setState(() => isScanning = true);
    final devices = await FileReceiver.scanForServers(subnet);
    if (mounted) {
      setState(() {
        foundServers = devices;
        isScanning = false;
      });
    }
  }

  Future<void> _receiveFiles() async {
    setState(() => isReceiving = true);
    final saveDir =
    await FilePicker.platform.getDirectoryPath(dialogTitle: "Select Save Folder");
    if (saveDir != null) {
      await FileReceiver.downloadMultipleFiles(selectedServer!.wifiIP, saveDir);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Saved to $saveDir")));
      }
    }
    if (mounted) setState(() => isReceiving = false);
  }
}
