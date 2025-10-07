class FileHistory {
  final String fileName;
  final int fileSize;
  final String fileFormat;
  final DateTime dateTime;
  final String status; // "Sent", "Received", "Failed"
  final String? remoteIp; // client/server IP

  FileHistory({
    required this.fileName,
    required this.fileSize,
    required this.fileFormat,
    required this.dateTime,
    required this.status,
    this.remoteIp,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileSize': fileSize,
    'fileFormat': fileFormat,
    'dateTime': dateTime.toIso8601String(),
    'status': status,
    'remoteIp': remoteIp,
  };

  factory FileHistory.fromJson(Map<String, dynamic> json) => FileHistory(
    fileName: json['fileName'],
    fileSize: json['fileSize'],
    fileFormat: json['fileFormat'],
    dateTime: DateTime.parse(json['dateTime']),
    status: json['status'],
    remoteIp: json['remoteIp'],
  );
}
