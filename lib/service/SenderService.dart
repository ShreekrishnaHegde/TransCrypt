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
    return await info.getWifiIP() ?? "Unknown IP";
  }

  static Future<void> startFileServerMultiple(
      List<File> files, BuildContext context) async {
    HttpServer? server;

    try {
      final ip = await findIp();
      server = await HttpServer.bind(InternetAddress.anyIPv4, 5051);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server running at http://$ip:5051"),
          backgroundColor: Colors.green,
        ),
      );

      final keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      await for (HttpRequest request in server) {
        final path = request.uri.path;
        final clientIp = request.connectionInfo?.remoteAddress.address;

        if (path == '/publicKey') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'public-key': base64Encode(keysPair.publicKey.bytes),
          }));
          await request.response.close();
          continue;
        }

        if (path != '/file') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        final allowed = await RequestDialog.show(context, clientIp ?? "Unknown");
        if (!allowed) {
          request.response
            ..statusCode = 403
            ..write("Access denied");
          await request.response.close();
          continue;
        }

        final clientPubKeyStr = request.headers.value('client-public-key');
        if (clientPubKeyStr == null) {
          request.response
            ..statusCode = 400
            ..write("Missing client public key");
          await request.response.close();
          continue;
        }

        final clientPublicKey = SimplePublicKey(
          base64Decode(clientPubKeyStr),
          type: KeyPairType.x25519,
        );

        for (final file in files) {
          if (!await file.exists()) continue;

          final fileName = file.uri.pathSegments.last;
          final fileSize = await file.length();

          final header = jsonEncode({
            "fileName": fileName,
            "fileSize": fileSize,
          });
          request.response.writeln(header);

          final chunkSize = 64 * 1024;
          final reader = file.openRead();
          final buffer = <int>[];

          await for (final chunk in reader) {
            buffer.addAll(chunk);
            if (buffer.length >= chunkSize) {
              final encrypted = await Encrypt.encryptBytes(
                  buffer, clientPublicKey, keysPair.privateKey);
              request.response.writeln(jsonEncode(encrypted));
              buffer.clear();
            }
          }

          if (buffer.isNotEmpty) {
            final encrypted = await Encrypt.encryptBytes(
                buffer, clientPublicKey, keysPair.privateKey);
            request.response.writeln(jsonEncode(encrypted));
          }
        }

        await request.response.close();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Files sent to $clientIp")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      await server?.close(force: true);
      await KeysPair.deleteKeysPair();
    }
  }
}
