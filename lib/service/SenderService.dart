import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transcrypt/RequestDialogue.dart';
import 'package:transcrypt/methods/Encryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';
import 'package:transcrypt/methods/methods.dart';

class SenderService {
  static const int SERVER_PORT = 4040;

  // Save a file chunk to Downloads/TransCrypt
  static Future<void> saveFileChunk(Uint8List chunk, String fileName) async {
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      print("HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHhhhh");
      return;
    }
    Directory downloads;
    if (Platform.isWindows) {
      downloads = Directory('${Platform.environment['USERPROFILE']}\\Downloads\\TransCrypt');

    } else {
      downloads = Directory('${(await getExternalStorageDirectory())!.path}/TransCrypt');

    }
    if (!downloads.existsSync()) downloads.createSync(recursive: true);
    final file = File('${downloads.path}/$fileName');
    // Uint8List is acceptable directly
    await file.writeAsBytes(chunk, mode: FileMode.append);
  }

  static Future<void> share(String filePath, BuildContext context) async {
    bool hasPermission = await RequestDialog().requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Storage permission is required to save files"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final deviceInfo = await Methods.getDeviceInfo();

    HttpServer? server;
    try {
      final ip = deviceInfo.wifiIP;
      if (ip == null || ip.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot start server: No IP found"), backgroundColor: Colors.red),
        );
        return;
      }

      // Bind server
      server = await HttpServer.bind(ip, SERVER_PORT);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server running at http://$ip:$SERVER_PORT"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // generate keys and persist
      final keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final fileLength = file.lengthSync();

      // Serve requests in a loop
      await for (HttpRequest request in server) {
        // handle each request inside try/catch to keep server alive on errors
        try {
          final path = request.uri.path;
          final clientIp = request.connectionInfo?.remoteAddress.address;

          if (path == '/info') {
            final responseData = {
              'ip': deviceInfo.wifiIP,
              'wifiName': deviceInfo.wifiName,
              'port': SERVER_PORT,
              'name': Platform.localHostname,
            };
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode(responseData));
            await request.response.close();
            continue;
          } else if (path == '/publicKey') {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'public-key': base64Encode(keysPair.publicKey.bytes)}));
            await request.response.close();
            continue;
          } else if (path == '/') {
            // Expect client headers
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
            // decode signature (base64Decode returns Uint8List)
            final signatureBytes = base64Decode(clientSignature);

            final isVerified = await verifyClientSignature(clientPubKey, signatureBytes);
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

            // Ask user permission on UI
            final allow = await RequestDialog.show(context, clientIp ?? 'unknown');
            if (!allow) {
              request.response
                ..statusCode = 403
                ..write('Request denied by user');
              await request.response.close();
              continue;
            }

            // Prepare to stream encrypted file chunks
            request.response.headers.contentType = ContentType.binary;
            // Optionally set Transfer-Encoding chunked (server will do this automatically if content-length not set)

            // Open file for reading (synchronous read is fine here but keep it short)
            final raf = file.openSync(mode: FileMode.read);
            const int chunkSize = 64 * 1024; // 64KB
            int offset = 0;

            try {
              while (offset < fileLength) {
                final size = (offset + chunkSize > fileLength) ? fileLength - offset : chunkSize;
                final chunk = raf.readSync(size); // returns List<int>
                // ensure Uint8List when encrypting
                final chunkBytes = Uint8List.fromList(chunk);
                final encryptedChunk = await Encryption.encryptBytes(chunkBytes, clientPubKey, keysPair.privateKey);

                // send encrypted chunk
                request.response.add(base64Decode(encryptedChunk)); // add accepts List<int>/Uint8List
                offset += size;
                // allow event loop to process if needed
                await Future<void>.delayed(Duration.zero);
              }
            } finally {
              raf.closeSync();
            }

            await request.response.close();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("File sent to $clientIp"), backgroundColor: Colors.green),
            );
            continue;
          } else {
            // Unknown route
            request.response
              ..statusCode = 404
              ..write('Not Found');
            await request.response.close();
            continue;
          }
        } catch (reqErr) {
          // Handle per-request exceptions so server loop continues
          try {
            request.response
              ..statusCode = 500
              ..write('Server request error: $reqErr');
            await request.response.close();
          } catch (_) {}
        }
      } // end await for
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      // ensure server is closed on exit
      try {
        await server?.close(force: true);
      } catch (_) {}
    }
  }

  /// Stub: actually verify signature properly using Ed25519 (or other)
  static Future<bool> verifyClientSignature(SimplePublicKey clientPublicKey, Uint8List signature) async {
    // TODO: implement real signature verification (e.g. Ed25519.verify)
    return true;
  }
}
