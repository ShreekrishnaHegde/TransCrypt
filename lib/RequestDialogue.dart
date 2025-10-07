import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
class RequestDialog {
  static Future<bool> show(BuildContext context, String ip) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Incoming request"),
        content: Text("Allow request from $ip?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Deny"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Allow"),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
  Future<bool> requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) return true;

    // If denied, open settings
    await openAppSettings();
    return false;
  }
}