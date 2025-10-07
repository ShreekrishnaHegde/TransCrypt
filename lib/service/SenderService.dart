import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:transcrypt/methods/methods.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';
class SenderService{

  static Future<void> start(BuildContext context) async {
    DeviceInfo deviceInfo=await Methods.getDeviceInfo();
    try {
      final ip = deviceInfo.wifiIP;
      //starting server
      final server = await HttpServer.bind(ip, 4040);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server running at http://$ip:4040"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      //Exposing device info API
      await for (HttpRequest request in server) {
        if (request.uri.path == '/info') {
          final ip=deviceInfo.wifiIP;
          final wifiName=deviceInfo.wifiName;
          final port=4040;

          final responseData = {
            'ip': ip,
            'wifiName':wifiName,
            'port':port,
            'name': Platform.localHostname
          };

          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(responseData));
          await request.response.close();
        } else {
          request.response
            ..statusCode = 404
            ..write('Not Found')
            ..close();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}