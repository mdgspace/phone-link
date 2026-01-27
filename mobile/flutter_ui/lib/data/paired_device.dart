class PairedDevice {
  final String deviceId; // stable UUID
  final String deviceName;
  final String platform; // linux
  // final List<String> caps; // sms, notif
  final String lastKnownIp;
  final int port;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    // required this.caps,
    required this.lastKnownIp,
    required this.port,
  });
}
