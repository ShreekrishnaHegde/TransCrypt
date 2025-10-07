import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:cryptography/cryptography.dart';

class Encryption{
    static Future<String> encryptBytes(
    Uint8List plainBytes,
    SimplePublicKey receiverPublicKey,
    KeyPair senderPrivateKey) async {

      // Generate shared secret using X25519
      SecretKey sharedSecretKey = await X25519().sharedSecretKey(
        keyPair: senderPrivateKey,
        remotePublicKey: receiverPublicKey,
      );

      // AEAD algorithm
      final algo = Xchacha20.poly1305Aead();

      // Generate nonce
      final nonce = algo.newNonce();

      // Encrypt bytes
      final secretBox = await algo.encrypt(
        plainBytes as List<int>,
        secretKey: sharedSecretKey,
        nonce: nonce,
      );

      // Prepare payload
      final payload = {
        'nonce': base64Encode(secretBox.nonce),
        'cipherText': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      };

      return jsonEncode(payload); // You can send this as a string over HTTP
    }
}