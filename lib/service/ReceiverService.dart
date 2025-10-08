import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/methods/Decryption.dart';
import 'package:transcrypt/methods/keyManaget.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class FileReceiver {
  static const int serverPort = 5051;

  static Future<void> downloadMultipleFiles(String serverIp, String saveDir) async {
    try {
      final pubRes =
      await http.get(Uri.parse('http://$serverIp:$serverPort/publicKey'));
      if (pubRes.statusCode != 200) throw "Server key unavailable";

      final serverPubKey = SimplePublicKey(
        base64Decode(jsonDecode(pubRes.body)['public-key']),
        type: KeyPairType.x25519,
      );

      final keysPair = await KeysPair.generateKeyPair();
      await KeysPair.storeKeyPairs(keysPair.publicKey, keysPair.privateKey);

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://$serverIp:$serverPort/file'));
      req.headers.add('client-public-key', base64Encode(keysPair.publicKey.bytes));

      final res = await req.close();
      if (res.statusCode != 200) throw "Server rejected connection";

      File? currentFile;
      IOSink? sink;

      await for (final line in res.transform(utf8.decoder).transform(LineSplitter())) {
        final decoded = jsonDecode(line);

        // header
        if (decoded is Map && decoded.containsKey('fileName')) {
          await sink?.close();
          final fileName = decoded['fileName'];
          currentFile = File('$saveDir/$fileName');
          sink = currentFile.openWrite();
          continue;
        }

        // encrypted chunk
        if (currentFile != null && sink != null) {
          final decrypted = await Decryption.decryptBytes(
              decoded, serverPubKey, keysPair.privateKey);
          sink.add(decrypted);
        }
      }

      await sink?.close();
      print("Files saved to $saveDir");
    } catch (e) {
      print("Download failed: $e");
    }
  }

  static String getSubnet(String ip) {
    final parts = ip.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  static Future<List<DeviceInfo>> scanForServers(String subnet) async {
    final info = NetworkInfo();
    final localIp = await info.getWifiIP();
    if (localIp == null) return [];

    final devices = <DeviceInfo>[];
    final futures = <Future<DeviceInfo?>>[];

    // Limit concurrency to avoid lag
    const maxConcurrent = 40;
    final ports = List.generate(255, (i) => i + 1);

    for (int i = 0; i < ports.length; i += maxConcurrent) {
      final batch = ports.skip(i).take(maxConcurrent);
      for (final j in batch) {
        final ip = '$subnet.$j';

        // Skip own device
        if (ip == localIp) continue;

        futures.add(checkSingleDevice(ip, serverPort));
      }

      final results = await Future.wait(futures);
      devices.addAll(results.whereType<DeviceInfo>());
      futures.clear();
    }

    return devices;
  }

  static Future<DeviceInfo?> checkSingleDevice(String ip, int port) async {
    try {
      final socket =
      await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
      await socket.close();

      // Verify it's a TransCrypt server (check /publicKey)
      final response = await HttpClient()
          .getUrl(Uri.parse('http://$ip:$port/publicKey'))
          .then((req) => req.close());

      if (response.statusCode == 200) {
        return DeviceInfo(wifiIP: ip);
      }
    } catch (_) {
      // Ignore unreachable hosts
    }
    return null;
  }

}
