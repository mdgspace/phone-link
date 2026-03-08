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
    return _rawServices.map((service) {
      // Find IPv4 address safely
      final ipv4Address = service.addresses
          ?.where((addr) => addr.type == InternetAddressType.IPv4)
          .firstOrNull;

      // Convert TXT records safely
      final Map<String, String> cleanTxt = {};
      service.txt?.forEach((key, value) {
        if (value != null) {
          cleanTxt[key] = utf8.decode(value);
        }
      });

      final ip = ipv4Address?.address ?? "0.0.0.0";
      final port = service.port ?? 0;

      return DiscoveredDevice(
        instanceName: service.name ?? 'Unknown',
        deviceName: cleanTxt["name"] ?? service.name ?? "Unknown Device",
        ipv4: ipv4Address ?? InternetAddress("0.0.0.0"),
        port: port,
        txt: cleanTxt,
        connected: _activeConnections.containsKey("$ip:$port"),
      );
    }).toList();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    final key = "${device.ipv4.address}:${device.port}";

    if (_activeConnections.containsKey(key)) return;

    try {
      final socket = await Socket.connect(
        device.ipv4.address,
        device.port,
        timeout: const Duration(seconds: 5),
      );

      socket.setOption(SocketOption.tcpNoDelay, true);

      _activeConnections[key] = socket;

      debugPrint("Connected to ${device.deviceName}");

      socket.listen(
        (data) => _handleIncomingData(device, data),
        onError: (e) {
          debugPrint("Socket error: $e");
          disconnectFromDevice(device);
        },
        onDone: () {
          debugPrint("Disconnected from ${device.deviceName}");
          disconnectFromDevice(device);
        },
      );

      notifyListeners();
    } catch (e) {
      debugPrint("Connection failed to ${device.deviceName}: $e");
    }
  }

  Future<void> disconnectFromDevice(DiscoveredDevice device) async {
    final key = "${device.ipv4.address}:${device.port}";

    final socket = _activeConnections.remove(key);

    await socket?.close();

    notifyListeners();
  }

  void _handleIncomingData(DiscoveredDevice device, List<int> data) {
    final message = utf8.decode(data);

    debugPrint("Message from ${device.deviceName}: $message");

    // Example: JSON protocol
    try {
      final decoded = jsonDecode(message);
      debugPrint("Parsed message: $decoded");
    } catch (_) {
      // ignore if not JSON
    }
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
