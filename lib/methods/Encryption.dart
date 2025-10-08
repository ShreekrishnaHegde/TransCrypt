import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class Encrypt {
  static Future<Map<String, String>> encryptBytes(
      List<int> data,
      SimplePublicKey receiverPublicKey,
      KeyPair senderPrivateKey,
      ) async {
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: senderPrivateKey,
      remotePublicKey: receiverPublicKey,
    );

    final algo = Xchacha20.poly1305Aead();
    final nonce = algo.newNonce();

    final secretBox = await algo.encrypt(
      data,
      secretKey: sharedSecret,
      nonce: nonce,
    );

    return {
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }
}
