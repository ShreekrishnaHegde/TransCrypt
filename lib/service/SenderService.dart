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
      final server = await HttpServer.bind(InternetAddress.anyIPv4, 5051);
      final ip = await findIp();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server running at http://$ip:5051"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      await for (HttpRequest request in server) {
        final path = request.uri.path;
        final clientIp = request.connectionInfo?.remoteAddress.address;

        // Serve public key
        if (path == '/publicKey') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'public-key': base64Encode(keysPair.publicKey.bytes)}));
          await request.response.close();
          continue;
        }

        // Ask user to allow request
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

        // Only respond to /file endpoint
        if (path == '/file') {
          request.response.headers.contentType = ContentType.text;

          for (final file in files) {
            if (!await file.exists()) continue;

            final fileName = file.uri.pathSegments.last;
            final fileSize = await file.length();

            // Send file header
            request.response.write(jsonEncode({"fileName": fileName, "fileSize": fileSize}) + '\n');

            final chunkSize = 64 * 1024;
            final stream = file.openRead();
            final buffer = <int>[];

            await for (final chunk in stream) {
              buffer.addAll(chunk);
              if (buffer.length >= chunkSize) {
                final payload = await Encrypt.encryptBytes(buffer, clientPublicKey, keysPair.privateKey);
                request.response.write(jsonEncode(payload) + '\n');
                buffer.clear();
              }
            }

            if (buffer.isNotEmpty) {
              final payload = await Encrypt.encryptBytes(buffer, clientPublicKey, keysPair.privateKey);
              request.response.write(jsonEncode(payload) + '\n');
            }
          }

          await request.response.close();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Files sent to $clientIp"),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          request.response
            ..statusCode = 404
            ..write("Endpoint not found");
          await request.response.close();
        }
      }

      await KeysPair.deleteKeysPair();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File server error: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
