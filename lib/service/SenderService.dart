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
    try {
      final ip = await findIp();

      final server = await HttpServer.bind(ip, 5051); // separate port for file transfer

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server running at http://$ip:5051"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Generate and store keys
      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);
      print("File server public key: ${keysPair.publicKey}");

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

        final file = File(filePath);
        if (!await file.exists()) {
          request.response
            ..statusCode = 404
            ..write("File not found");
          await request.response.close();
          continue;
        }

        final fileStream = file.openRead();
        final chunkSize = 64 * 1024; // 64 KB per chunk
        final bytes = <int>[];

        await for (final chunk in fileStream) {
          bytes.addAll(chunk);

          if (bytes.length >= chunkSize) {
            final payload = await Encrypt.encryptBytes(
              bytes,
              clientPublicKey,
              keysPair.privateKey,
            );
            request.response.write("${jsonEncode(payload)}\n"); // newline separates chunks
            bytes.clear();
          }
        }

        // Send remaining bytes if any
        if (bytes.isNotEmpty) {
          final payload = await Encrypt.encryptBytes(
            bytes,
            clientPublicKey,
            keysPair.privateKey,
          );
          request.response.write("${jsonEncode(payload)}\n");
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
          content: Text("File server error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
