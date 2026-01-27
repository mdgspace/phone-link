import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

import '../data/discovered_device.dart';

class MdnsDiscoveryController extends ChangeNotifier {
  Discovery? _discovery;

  // Track active sockets using the IP address as the key
  final Map<String, Socket> _activeConnections = {};

  List<Service> get _rawServices => _discovery?.services ?? [];
  bool get isRunning => _discovery != null;

  /// Returns a list of processed [DiscoveredDevice] objects
  List<DiscoveredDevice> get devices {
    return _rawServices
        .map((service) {
          // 1. Find the first IPv4 address
          final ipv4Address = service.addresses?.firstWhere(
            (addr) => addr.type == InternetAddressType.IPv4,
            orElse: () => InternetAddress('0.0.0.0'), // Fallback
          );

          // 2. Convert TXT records from Map<String, Uint8List?> to Map<String, String>
          final Map<String, String> cleanTxt = {};
          service.txt?.forEach((key, value) {
            if (value != null) {
              cleanTxt[key] = String.fromCharCodes(value);
            }
          });

          return DiscoveredDevice(
            instanceName: service.name ?? 'Unknown',
            // In mDNS, the 'name' is often the human-readable device name
            deviceName: service.name ?? 'Unknown Device',
            ipv4: ipv4Address ?? InternetAddress('0.0.0.0'),
            port: service.port ?? 0,
            txt: cleanTxt,
            connected: _activeConnections.containsKey(ipv4Address?.address),
          );
        })
        .where((device) => device.port != 0)
        .toList();
    // Filter out invalid devices that haven't fully resolved yet
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (_activeConnections.containsKey(device.ipv4.address)) return;

    try {
      final socket = await Socket.connect(device.ipv4, device.port,
          timeout: const Duration(seconds: 5));

      _activeConnections[device.ipv4.address] = socket;

      // Listen for data or disconnectes
      socket.listen(
        (data) => _handleIncomingData(device, data),
        onError: (e) => disconnectFromDevice(device),
        onDone: () => disconnectFromDevice(device),
      );

      notifyListeners();
    } catch (e) {
      debugPrint("Connection failed to ${device.deviceName} : $e");
    }
  }

  Future<void> disconnectFromDevice(DiscoveredDevice device) async {
    final socket = _activeConnections.remove(device.ipv4.address);
    await socket?.close();
    notifyListeners();
  }

  void _handleIncomingData(DiscoveredDevice device, List<int> data) {
    final message = utf8.decode(data);
    debugPrint("Message from ${device.deviceName} : $message");
  }

  Future<void> start() async {
    if (_discovery != null) return;

    // Use the same service type defined in your config
    _discovery = await startDiscovery('_phonelink._tcp');
    _discovery!.addListener(notifyListeners);
    notifyListeners();
  }

  Future<void> stop() async {
    if (_discovery == null) return;

    _discovery!.removeListener(notifyListeners);
    await stopDiscovery(_discovery!);
    _discovery = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
