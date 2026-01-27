import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import '../data/local_device.dart'; // Ensure this path is correct

class MdnsRegistrationController extends ChangeNotifier {
  final LocalDeviceConfigService _configService;
  Registration? _registration;

  MdnsRegistrationController(this._configService);

  bool get isRegistered => _registration != null;
  Service? get service => _registration?.service;

  /// Helper to get the latest config directly from the service
  LocalDeviceConfig get config => _configService.config;

  Future<void> start() async {
    if (_registration != null) return;

    // Use values directly from the provided LocalDeviceConfig
    final service = Service(
      name: config.deviceName,
      type: config.serviceType,
      port: config.port,
      txt: {
        'id': Uint8List.fromList(config.deviceId.codeUnits),
        'proto':
            Uint8List.fromList(config.protocolVersion.toString().codeUnits),
        'plat': Uint8List.fromList('android'.codeUnits),
      },
    );

    try {
      _registration = await register(service);
      notifyListeners();
    } catch (e) {
      debugPrint('mDNS Registration failed: $e');
    }
  }

  Future<void> stop() async {
    if (_registration == null) return;
    await unregister(_registration!);
    _registration = null;
    notifyListeners();
  }

  /// Updates the name in storage and restarts mDNS to broadcast the new name
  Future<void> updateDeviceName(String newName) async {
    await _configService.updateName(newName);

    // If we are currently advertising, we must restart to update the network name
    if (isRegistered) {
      await stop();
      await start();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
