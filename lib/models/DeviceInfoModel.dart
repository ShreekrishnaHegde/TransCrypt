class DeviceInfo{
  late  String? wifiName;
  late  String wifiIP;
  late  String? wifiSubmask;
  late String? port;
  late String? name;
  DeviceInfo({
    this.wifiName,
    required this.wifiIP,
    this.wifiSubmask,
    this.port,
    this.name
  });
}