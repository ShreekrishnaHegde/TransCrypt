import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:transcrypt/methods/Decryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';

class FileReceiver {
  static const int SERVER_PORT = 5051;

  static Future<void> downloadFile(String serverIp, String savePath) async {
    try {
      // Step 1: Fetch server public key
      final publicResponse =
      await http.get(Uri.parse('http://$serverIp:$SERVER_PORT/publicKey'));
      final publicKeyEncoded = jsonDecode(publicResponse.body)['public-key'];
      final serverPublicKey = SimplePublicKey(
        base64Decode(publicKeyEncoded),
        type: KeyPairType.x25519,
      );

      // Step 2: Generate client key pair
      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      // Step 3: Connect to file server and receive file stream
      final request = await HttpClient().getUrl(Uri.parse('http://$serverIp:$SERVER_PORT/file'));
      request.headers.add('client-public-key', base64Encode(keysPair.publicKey.bytes));

      final response = await request.close();
      if (response.statusCode != 200) {
        print("File request failed: ${response.statusCode}");
        return;
      }

      final file = File(savePath);
      final sink = file.openWrite();

      await for (var line in response.transform(utf8.decoder).transform(const LineSplitter())) {
        try {
          final decryptedChunk = await Decryption.decryptBytes(
            line,
            serverPublicKey,
            keysPair.privateKey,
          );
          sink.add(decryptedChunk);
        } catch (e) {
          print("Decryption error on chunk: $e");
        }
      }

      await sink.close();
      print("File saved to $savePath");
    } catch (e) {
      print("File download error: $e");
    }
  }
}
