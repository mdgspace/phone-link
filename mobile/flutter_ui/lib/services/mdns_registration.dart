import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

import '../data/local_device.dart';

class MdnsRegistrationController extends ChangeNotifier {
  final LocalDeviceConfigService _configService;
  Registration? _registration;
  bool _starting = false;
  String? _errorMessage;

  MdnsRegistrationController(this._configService);

  bool get isRegistered => _registration != null;
  bool get isStarting => _starting;
  String? get errorMessage => _errorMessage;
  Service? get service => _registration?.service;
  LocalDeviceConfig get config => _configService.config;

  Future<void> start() async {
    if (_registration != null || _starting) return;

    _starting = true;
    _errorMessage = null;
    notifyListeners();

    final current = config;
    final service = Service(
      name: current.deviceName,
      type: current.serviceType,
      port: current.port,
      txt: {
        'name': Uint8List.fromList(current.deviceName.codeUnits),
        'id': Uint8List.fromList(current.deviceId.codeUnits),
        'proto': Uint8List.fromList(
          current.protocolVersion.toString().codeUnits,
        ),
        'plat': Uint8List.fromList('android'.codeUnits),
      },
    );

    try {
      _registration = await register(service);
    } catch (e) {
      _errorMessage = 'mDNS registration failed: $e';
      debugPrint(_errorMessage);
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final registration = _registration;
    if (registration == null) return;

    try {
      await unregister(registration);
    } catch (e) {
      debugPrint('mDNS unregistration failed: $e');
    } finally {
      _registration = null;
      notifyListeners();
    }
  }

  Future<void> updateDeviceName(String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) return;

    await _configService.updateName(cleaned);

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
