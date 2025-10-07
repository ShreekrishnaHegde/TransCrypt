import 'dart:convert';
import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/methods/Decryption.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class ReceiverService{
  static const int SERVER_PORT=4040;
  static String getSubnet(String ip){
    final parts=ip.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
  static Future<SimplePublicKey?> getServerPublicKey(String serverIp) async {
    final response = await http.get(Uri.parse('http://$serverIp:$SERVER_PORT/publicKey'));
    if (response.statusCode == 200) {
      final key = jsonDecode(response.body)['public-key'];
      return SimplePublicKey(base64Decode(key), type: KeyPairType.x25519);
    }
    return null;
  }
  // ----------------------------------------------------------------------
  static Future<List<DeviceInfo>> scanForServers(String subnet) async {

    List<DeviceInfo> devices = [];
    List<Future<DeviceInfo?>> futures = [];
    for (int i =1;i<= 255;i++){
      final ip = '$subnet.$i';
      futures.add(checkSingleDevice(ip, SERVER_PORT));
    }

    final results = await Future.wait(futures);
    for (var device in results) {
      if (device != null) devices.add(device);
    }

    return devices;
  }
  static Future<DeviceInfo?> checkSingleDevice(String ip,int port)async{
    try{
      final socket=await Socket.connect(ip, port,timeout: Duration(milliseconds: 300));
      await socket.close();
      final uri = Uri.parse('http://$ip:$port/info');
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return DeviceInfo(
          wifiIP: data['ip'],
          wifiName: data['wifiName'],
          port: data['port'],
          name: data['name'],
        );
      }
    }
    catch(e){
      return null;
    }
  }
  static Future<void> downloadFile(String serverIp, String saveFileName, BuildContext context) async {
    try {
      final serverPublicKey = await getServerPublicKey(serverIp);
      if (serverPublicKey == null) throw Exception("Server public key not found");

      // Generate client keys
      final clientKeys = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(clientKeys.publicKey, clientKeys.privateKey);

      final uri = Uri.parse('http://$serverIp:$SERVER_PORT');
      final headers = {'client-public-key': base64Encode(clientKeys.publicKey.bytes)};

      final request = await HttpClient().getUrl(uri);
      headers.forEach((k, v) => request.headers.add(k, v));
      final response = await request.close();

      if (response.statusCode != 200) throw Exception("Failed to connect");

      // Prepare file path
      Directory downloads;
      if (Platform.isWindows) {
        downloads = Directory('${Platform.environment['USERPROFILE']}\\Downloads\\TransCrypt');
      } else {
        downloads = Directory('${(await getExternalStorageDirectory())!.path}/TransCrypt');
      }
      if (!downloads.existsSync()) downloads.createSync(recursive: true);
      final file = File('${downloads.path}/$saveFileName');
      if (file.existsSync()) file.deleteSync();

      // Read chunks
      await for (Uint8List chunk in response) {
        final decryptedChunk = await Decryption.decryptBytes(chunk, serverPublicKey, clientKeys.privateKey);
        await file.writeAsBytes(decryptedChunk, mode: FileMode.append);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File downloaded: $saveFileName"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}