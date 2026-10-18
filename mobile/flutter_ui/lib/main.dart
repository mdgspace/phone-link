import 'package:flutter/material.dart';
import 'app.dart';
import 'data/local_device.dart';
import 'services/pairing_service.dart';

void main() async {
  // Required when calling async code before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the local device config service
  final configService = LocalDeviceConfigService();
  await configService.load();

  // Paired desktops and resume_device_id must be loaded before the first
  // frame, or ConnectionManager.restoreLastSession() sees an empty list.
  final pairingService = PairingService();
  await pairingService.load();

  runApp(
    PhoneLinkApp(
      configService: configService,
      pairingService: pairingService,
    ),
  );
}
