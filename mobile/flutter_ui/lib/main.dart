import 'package:flutter/material.dart';
import 'app.dart';
import 'data/local_device.dart';

void main() async {
  // Required when calling async code before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the local device config service
  final configService = LocalDeviceConfigService();
  await configService.load();

  runApp(
    PhoneLinkApp(configService: configService),
  );
}
