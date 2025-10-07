import 'dart:convert';
import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transcrypt/RequestDialogue.dart';
import 'package:transcrypt/methods/Encryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';
import 'package:transcrypt/methods/methods.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';
class SenderService{
  static const int SERVER_PORT = 4040;
  // Save a file chunk to Downloads/TransCrypt
  static Future<void> saveFileChunk(Uint8List chunk, String fileName) async {
    Directory downloads;
    if (Platform.isWindows) {
      downloads = Directory('${Platform.environment['USERPROFILE']}\\Downloads\\TransCrypt');
    } else {
      downloads = Directory('${(await getExternalStorageDirectory())!.path}/TransCrypt');
    }
    if (!downloads.existsSync()) downloads.createSync(recursive: true);
    final file = File('${downloads.path}/$fileName');
    await file.writeAsBytes(chunk as List<int>, mode: FileMode.append);
  }
  static Future<void> share(String filePath,BuildContext context) async {

    DeviceInfo deviceInfo=await Methods.getDeviceInfo();
    try {
      final ip = deviceInfo.wifiIP;
      //starting server
      final server = await HttpServer.bind(ip, 4040);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server running at http://$ip:4040"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      //generating key pairs
      final keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);
      // Read file bytes
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final fileLength = file.lengthSync();
      final raf = file.openSync();
      //Exposing device info API
      await for (HttpRequest request in server) {
        //client information
        final path = request.uri.path;
        final clientIp = request.connectionInfo?.remoteAddress.address;
        //to get the device info
        if (request.uri.path == '/info') {
          final ip=deviceInfo.wifiIP;
          final wifiName=deviceInfo.wifiName;
          final port=4040;
          final responseData = {
            'ip': ip,
            'wifiName':wifiName,
            'port':port,
            'name': Platform.localHostname
          };

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responseData));
          await request.response.close();
        } else {
          request.response
            ..statusCode = 404
            ..write('Not Found')
            ..close();
        }
        // Send server public key
        if (path == '/publicKey') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'public-key': base64Encode(keysPair.publicKey.bytes)}));
          await request.response.close();
          continue;
        }
        final clientPubString = request.headers.value('client-public-key');
        final clientSignature = request.headers.value('client-signature');
        if (clientPubString == null || clientSignature == null) {
          request.response
            ..statusCode = 400
            ..write('Missing client public key or signature');
          await request.response.close();
          continue;
        }
        final clientPubKey = SimplePublicKey(base64Decode(clientPubString), type: KeyPairType.x25519);
        // Verify client signature before asking user
        final isVerified = await verifyClientSignature(clientPubKey, base64Decode(clientSignature) as Uint8List);
        if (!isVerified) {
          request.response
            ..statusCode = 403
            ..write('Client verification failed');
          await request.response.close();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Client verification failed: $clientIp"), backgroundColor: Colors.red),
          );
          continue;
        }
        // Ask user for permission
        bool allow = await RequestDialog.show(context, clientIp!);
        if (!allow) {
          request.response
            ..statusCode = 403
            ..write('Request denied by user');
          await request.response.close();
          continue;
        }
        // Send file in chunks
        const int chunkSize = 64 * 1024; // 64 KB
        int offset = 0;
        while (offset < fileLength) {
          final size = (offset + chunkSize > fileLength) ? fileLength - offset : chunkSize;
          final chunk = raf.readSync(size);
          final encryptedChunk = await Encryption.encryptBytes(chunk as Uint8List, clientPubKey, keysPair.privateKey);

          request.response
            ..headers.contentType = ContentType.binary
            ..add(encryptedChunk as List<int>); // send chunk
          offset += size;
        }
        await request.response.close();
        raf.closeSync();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File sent to $clientIp"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  static Future<bool> verifyClientSignature(SimplePublicKey clientPublicKey, Uint8List signature) async {
    return true;
  }
}