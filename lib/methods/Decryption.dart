import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
class Decryption{
  static Future<Uint8List> decryptBytes(
      String encryptedPayload,
      SimplePublicKey senderPublicKey,
      KeyPair receiverPrivateKey) async {
    final Map<String, dynamic> payload = jsonDecode(encryptedPayload);
    final nonce = base64Decode(payload['nonce']);
    final cipherText = base64Decode(payload['cipherText']);
    final macBytes = base64Decode(payload['mac']);
    final algo = Xchacha20.poly1305Aead();
    final sharedSecretKey = await X25519().sharedSecretKey(
      keyPair: receiverPrivateKey,
      remotePublicKey: senderPublicKey,
    );
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final decrypted = await algo.decrypt(secretBox, secretKey: sharedSecretKey);
    return Uint8List.fromList(decrypted);
  }
}