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

  static Future<void> startFileServer(String filePath, BuildContext context) async {
    await RequestDialog.requestPermissions();

    try {
      final ip = await findIp();
      final server = await HttpServer.bind(ip, 5051); // different port for file transfer

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server running at http://$ip:5051"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Generate key pair
      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      await for (HttpRequest request in server) {
        final path = request.uri.path;
        final clientIp = request.connectionInfo?.remoteAddress.address;

        // Step 1: Provide server public key
        if (path == '/publicKey') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'public-key': base64Encode(keysPair.publicKey.bytes)
            }));
          await request.response.close();
          continue;
        }

        // Step 2: Validate client request
        bool allow = await RequestDialog.show(context, clientIp!);
        if (!allow) {
          request.response
            ..statusCode = 403
            ..write("Request Denied");
          await request.response.close();
          continue;
        }

        // Step 3: Get client public key
        final clientPublicKeyString = request.headers.value('client-public-key');
        if (clientPublicKeyString == null) {
          request.response
            ..statusCode = 400
            ..write("Missing client public key");
          await request.response.close();
          continue;
        }

        final clientPublicKey = SimplePublicKey(
          base64Decode(clientPublicKeyString),
          type: KeyPairType.x25519,
        );

        // Step 4: Stream file in encrypted chunks
        final file = File(filePath);
        if (!await file.exists()) {
          request.response
            ..statusCode = 404
            ..write("File not found");
          await request.response.close();
          continue;
        }

        request.response.headers.contentType = ContentType.binary;

        final raf = await file.openRead();
        final chunkSize = 64 * 1024; // 64 KB chunks
        await for (var chunk in raf) {
          final encryptedChunk =
          await Encryption.encryptBytes(chunk, clientPublicKey, keysPair.privateKey);
          request.response.add(encryptedChunk);
        }

        await request.response.close();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File sent to $clientIp"),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await KeysPair.deleteKeysPair();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File Server Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
