import 'package:network_info_plus/network_info_plus.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';

class Methods{
  static Future<DeviceInfo> getDeviceInfo()async{
    final info=NetworkInfo();
    final wifiName = await info.getWifiName();
    final wifiIP = await info.getWifiIP();
    final wifiSubmask = await info.getWifiSubmask();
    return DeviceInfo(wifiIP: wifiIP!,wifiName: wifiName!,wifiSubmask: wifiSubmask!);
  }
}