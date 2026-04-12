import 'dart:io';

class DiscoveredDevice {
  final String instanceName;
  final String deviceName;
  final InternetAddress ipv4;
  final int port;
  final Map<String, String> txt;

  DiscoveredDevice({
    required this.instanceName,
    required this.deviceName,
    required this.ipv4,
    required this.port,
    required this.txt,
  });
}
