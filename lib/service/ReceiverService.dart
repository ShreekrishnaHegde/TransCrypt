import 'dart:convert';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class ReceiverService{
  static const int SERVER_PORT=4040;
  static String getSubnet(String ip){
    final parts=ip.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
  // ----------------------------------------------------------------------
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
      final socket=await Socket.connect(ip, port,timeout: Duration(milliseconds: 300));
      await socket.close();
      final uri = Uri.parse('http://$ip:$port/info');
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return DeviceInfo(
          wifiIP: data['ip'],
          wifiName: data['wifiName'],
          port: data['port'],
          name: data['name'],
        );
      }
    }
    catch(e){
      return null;
    }
  }
}