import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../storage/secure_storage.dart';
class KeysPair{
  SimplePublicKey publicKey;
  KeyPair privateKey;
  KeysPair({
    required this.privateKey,
    required this.publicKey,
  });
  static final storage=SecureStorage.instance;
  //to generate the keys
  static Future<KeysPair> generateKeyPair() async{
    final algo=X25519();
    final keyPair= await algo.newKeyPair();
    final publicKey=await keyPair.extractPublicKey();
    return KeysPair(privateKey: keyPair, publicKey: publicKey);
  }
  static Future<void> deleteKeysPair() async{
    await storage.delete(key: 'public-key');
    await storage.delete(key: 'private-key');
  }
  static Future<void> storeKeyPairs(SimplePublicKey publicKey,KeyPair privateKey)async{
    await storage.write(key: 'public-key', value: base64Encode(publicKey.bytes));
    if(privateKey is SimpleKeyPairData){
      final privateKeyData= privateKey;
      await storage.write(key: 'private-key', value: base64Encode(privateKeyData.bytes));
    }
    else{
      throw Exception("Private Key is not SimpleKeyPaitDAta");
    }
  }
  //to read from the storage
  Future<KeysPair> readKeyPairs() async{
    final publicEncoded=await storage.read(key: 'public-key');
    final privateEncoded=await storage.read(key: 'private-key');
    if(privateEncoded==null || publicEncoded==null){
      throw Exception("No Keys Found");
    }
    final publicKey=SimplePublicKey(base64Decode(publicEncoded), type:KeyPairType.x25519);
    final privateKey = SimpleKeyPairData(
        base64Decode(privateEncoded),type: KeyPairType.x25519,publicKey: publicKey);
    return KeysPair(privateKey: privateKey, publicKey: publicKey);
  }
}