import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as p;
import 'package:cryptography/cryptography.dart';

// Encryption class
class Encryption {
  static Future<String> encryptBytes(
    Uint8List plainBytes,
    SimplePublicKey receiverPublicKey,
    KeyPair senderPrivateKey,
  ) async {
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
    return jsonEncode(payload);
  }
}

// KeysPair class
class KeysPair {
  SimplePublicKey publicKey;
  KeyPair privateKey;

  KeysPair({
    required this.privateKey,
    required this.publicKey,
  });

  // Generate new key pair
  static Future<KeysPair> generateKeyPair() async {
    final algo = X25519();
    final keyPair = await algo.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return KeysPair(privateKey: keyPair, publicKey: publicKey);
  }
}

Future<void> main() async {
  // Generate server key pair (or load from storage)
  final serverKeyPair = await KeysPair.generateKeyPair();
  print('🔑 Server public key: ${base64Encode(serverKeyPair.publicKey.bytes)}');

  final app = Router();

  // Endpoint to get server public key
  app.get('/public-key', (Request request) {
    return Response.ok(
      jsonEncode({
        'publicKey': base64Encode(serverKeyPair.publicKey.bytes),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Upload endpoint with encryption
  app.post('/upload', (Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType == null || !contentType.contains('multipart/form-data')) {
      return Response(400, body: 'Invalid content type');
    }

    String? clientPublicKeyBase64;
    String? uploadedFilePath;

    final formData = await request.multipartFormData;
    await for (final formPart in formData) {
      // Get client's public key
      if (formPart.name == 'publicKey') {
        clientPublicKeyBase64 = await formPart.part.readString();
      }
      
      // Handle file upload
      if (formPart.name == 'file' && formPart.filename != null) {
        final uploadDir = Directory('uploads');
        if (!await uploadDir.exists()) await uploadDir.create();
        final filePath = p.join(uploadDir.path, formPart.filename!);
        final file = File(filePath);
        final sink = file.openWrite();
        await formPart.part.pipe(sink);
        await sink.close();
        uploadedFilePath = filePath;
      }
    }

    if (uploadedFilePath == null) {
      return Response(400, body: 'No file uploaded');
    }

    if (clientPublicKeyBase64 == null) {
      return Response(400, body: 'Client public key not provided');
    }

    // Parse client public key
    final clientPublicKey = SimplePublicKey(
      base64Decode(clientPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    // Split and encrypt the uploaded file
    await splitAndEncryptFile(
      uploadedFilePath,
      clientPublicKey: clientPublicKey,
      serverPrivateKey: serverKeyPair.privateKey,
      chunkSize: 2 * 1024 * 1024, // 2MB chunks
    );

    return Response.ok(jsonEncode({
      'message': 'File uploaded, chunked, and encrypted successfully',
      'fileName': p.basename(uploadedFilePath),
    }), headers: {'Content-Type': 'application/json'});
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('✅ Server running at http://${server.address.host}:${server.port}');
}

Future<void> splitAndEncryptFile(
  String filePath, {
  required SimplePublicKey clientPublicKey,
  required KeyPair serverPrivateKey,
  int chunkSize = 1024 * 1024,
}) async {
  final file = File(filePath);
  final fileName = p.basenameWithoutExtension(filePath);
  final extension = p.extension(filePath);
  final bytes = await file.readAsBytes();
  final totalChunks = (bytes.length / chunkSize).ceil();

  final chunkDir = Directory('chunks/$fileName');
  if (!await chunkDir.exists()) await chunkDir.create(recursive: true);

  print('📦 Splitting and encrypting file into $totalChunks chunks...');

  for (int i = 0; i < totalChunks; i++) {
    final start = i * chunkSize;
    final end = (i + 1) * chunkSize;
    final chunk = bytes.sublist(start, end > bytes.length ? bytes.length : end);

    // Encrypt the chunk
    final encryptedData = await Encryption.encryptBytes(
      Uint8List.fromList(chunk),
      clientPublicKey,
      serverPrivateKey,
    );

    // Save encrypted chunk as JSON
    final chunkFile = File(
      p.join(chunkDir.path, '${fileName}_chunk_$i.encrypted'),
    );
    await chunkFile.writeAsString(encryptedData);

    print('✓ Chunk $i/${totalChunks - 1} encrypted');
  }

  print('✅ File split into $totalChunks encrypted chunks');
  
  // Optionally delete the original unencrypted file
  // await file.delete();
}