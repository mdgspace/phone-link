import 'dart:io';

class DiscoveredDevice {
  final String instanceName; // service.name
  final String deviceName;
  final InternetAddress ipv4;
  final int port;
  final Map<String, String> txt;
  bool connected;

  DiscoveredDevice({
    required this.instanceName,
    required this.deviceName,
    required this.ipv4,
    required this.port,
    required this.txt,
    this.connected = false,
  });
}
