import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

class MdnsRegistrationController extends ChangeNotifier {
  Registration? _registration;

  // Current advertised values (in-memory)
  String deviceName;
  int port;
  String serviceType;

  MdnsRegistrationController({
    required this.deviceName,
    required this.port,
    required this.serviceType,
  });

  bool get isRegistered => _registration != null;

  Service? get service => _registration?.service;

  /// Start advertising (only if not already running)
  Future<void> start() async {
    if (_registration != null) return;

    final service = Service(
      name: deviceName,
      type: serviceType,
      port: port,
      txt: {
        'id': null,
      },
    );

    _registration = await register(service);
    notifyListeners();
  }

  /// Stop advertising
  Future<void> stop() async {
    if (_registration == null) return;

    await unregister(_registration!);
    _registration = null;
    notifyListeners();
  }

  /// Update advertised values (restart registration if needed)
  Future<void> update({
    required String newName,
    required int newPort,
  }) async {
    deviceName = newName;
    port = newPort;

    if (_registration != null) {
      // restart registration with new values
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
