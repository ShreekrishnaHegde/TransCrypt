import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/RequestDialogue.dart';
import 'package:transcrypt/methods/Encryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';


class FileSender {
  static Future<String?> findIp() async {
    final info = NetworkInfo();
    return await info.getWifiIP() ?? "IP not available";
  }

  static Future<void> startFileServerMultiple(List<File> files, BuildContext context) async {
    try {
      final ip = await findIp();
      final server = await HttpServer.bind(ip, 5051);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server running at http://$ip:5051"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      await for (HttpRequest request in server) {
        final path = request.uri.path;
        final clientIp = request.connectionInfo?.remoteAddress.address;

        if (path == '/publicKey') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'public-key': base64Encode(keysPair.publicKey.bytes)}));
          await request.response.close();
          continue;
        }

        bool allow = await RequestDialog.show(context, clientIp!);
        if (!allow) {
          request.response
            ..statusCode = 403
            ..write('Request Denied');
          await request.response.close();
          continue;
        }

        final clientPublicKeyString = request.headers.value('client-public-key');
        if (clientPublicKeyString == null) {
          request.response
            ..statusCode = 400
            ..write("Client Public Key Missing");
          await request.response.close();
          continue;
        }

        final clientPublicKey = SimplePublicKey(
          base64Decode(clientPublicKeyString),
          type: KeyPairType.x25519,
        );

        // Sequentially send files
        for (final file in files) {
          if (!await file.exists()) continue;

          final fileName = file.uri.pathSegments.last;
          final fileSize = await file.length();

          // Send header (file info)
          final header = jsonEncode({"fileName": fileName, "fileSize": fileSize});
          request.response.write("$header\n");

          final chunkSize = 64 * 1024;
          final bytes = <int>[];
          await for (final chunk in file.openRead()) {
            bytes.addAll(chunk);
            if (bytes.length >= chunkSize) {
              final payload = await Encrypt.encryptBytes(bytes, clientPublicKey, keysPair.privateKey);
              request.response.write("${jsonEncode(payload)}\n");
              bytes.clear();
            }
          }

          if (bytes.isNotEmpty) {
            final payload = await Encrypt.encryptBytes(bytes, clientPublicKey, keysPair.privateKey);
            request.response.write("${jsonEncode(payload)}\n");
          }
        }

        await request.response.close();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Files sent to $clientIp"),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await KeysPair.deleteKeysPair();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<void> startFileServer(String s, BuildContext context) async {}
}
