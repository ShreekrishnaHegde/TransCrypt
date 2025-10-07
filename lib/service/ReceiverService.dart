import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:transcrypt/methods/Decryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class FileReceiver {
  static const int SERVER_PORT = 5051;

  static Future<void> downloadMultipleFiles(
      String serverIp, String saveDir,
      {Function(double speed)? onSpeedUpdate}) async {
    try {
      final publicResponse =
      await http.get(Uri.parse('http://$serverIp:$SERVER_PORT/publicKey'));
      final serverPublicKey = SimplePublicKey(
        base64Decode(jsonDecode(publicResponse.body)['public-key']),
        type: KeyPairType.x25519,
      );

      KeysPair keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      final request = await HttpClient().getUrl(Uri.parse('http://$serverIp:$SERVER_PORT/file'));
      request.headers.add('client-public-key', base64Encode(keysPair.publicKey.bytes));

      final response = await request.close();
      if (response.statusCode != 200) return;

      File? currentFile;
      IOSink? sink;
      int totalBytes = 0;
      final stopwatch = Stopwatch()..start();

      await for (var line in response.transform(utf8.decoder).transform(const LineSplitter())) {
        final decoded = jsonDecode(line);

        // Check for file header
        if (decoded is Map && decoded.containsKey("fileName")) {
          await sink?.close();
          final fileName = decoded['fileName'];
          currentFile = File('$saveDir/$fileName');
          sink = currentFile.openWrite();
          totalBytes = 0;
          stopwatch.reset();
          continue;
        }

        // Encrypted chunk
        if (currentFile != null && sink != null) {
          final decryptedChunk = await Decryption.decryptBytes(line, serverPublicKey, keysPair.privateKey);
          sink.add(decryptedChunk);

          // Update speed
          totalBytes += decryptedChunk.length;
          if (stopwatch.elapsedMilliseconds >= 500) { // update every 0.5s
            final speed = totalBytes / stopwatch.elapsedMilliseconds * 1000; // bytes/sec
            if (onSpeedUpdate != null) onSpeedUpdate(speed);
            totalBytes = 0;
            stopwatch.reset();
          }
        }
      }

      await sink?.close();
      print("All files saved to $saveDir");
    } catch (e) {
      print("File download error: $e");
    }
  }


  static String getSubnet(String ip){
    final parts=ip.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
  static Future<List<DeviceInfo>> scanForServers(String subnet) async {
    List<DeviceInfo> devices = [];
    List<Future<DeviceInfo?>> futures = [];
    for (int i =1;i<= 255;i++){
      final ip = '$subnet.$i';
      futures.add(checkSingleDevice(ip, SERVER_PORT));
    }
    final results = await Future.wait(futures);
    for (var device in results) {
      if (device != null) devices.add(device);
    }

    return devices;
  }
  static Future<DeviceInfo?> checkSingleDevice(String ip,int port)async{
    try{
      final scoket=await Socket.connect(ip, port,timeout: Duration(milliseconds: 300));
      await scoket.close();
      return DeviceInfo(wifiIP: ip);
    }
    catch(e){
      return null;
    }
  }

  static Future<void> downloadFile(String wifiIP, String saveResult) async {}
}
