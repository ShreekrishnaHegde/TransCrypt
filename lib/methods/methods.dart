import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class Methods {
  static Future<DeviceInfo> getDeviceInfo() async {
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    final wifiIP = await info.getWifiIP();
    final wifiSubmask = await info.getWifiSubmask();

    return DeviceInfo(
      wifiIP: wifiIP ?? 'Unknown IP',
      wifiName: wifiName ?? 'Unknown Wi-Fi',
      wifiSubmask: wifiSubmask ?? 'Unknown Subnet',
      port: '5051', // optional default port
      name: 'Device', // optional device name
    );
  }
}
