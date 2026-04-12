import 'dart:convert';

class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String lastKnownIp;
  final int port;
  final int pairedAt;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.lastKnownIp,
    required this.port,
    int? pairedAt,
  }) : pairedAt = pairedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  PairedDevice copyWith({String? lastKnownIp, String? deviceName}) {
    return PairedDevice(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform,
      lastKnownIp: lastKnownIp ?? this.lastKnownIp,
      port: port,
      pairedAt: pairedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'last_known_ip': lastKnownIp,
        'port': port,
        'paired_at': pairedAt,
      };

  factory PairedDevice.fromJson(Map<String, dynamic> json) => PairedDevice(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String,
        platform: json['platform'] as String? ?? 'unknown',
        lastKnownIp: json['last_known_ip'] as String,
        port: json['port'] as int,
        pairedAt: json['paired_at'] as int? ?? 0,
      );

  static List<PairedDevice> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PairedDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<PairedDevice> devices) =>
      jsonEncode(devices.map((d) => d.toJson()).toList());
}
