import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local_device.dart';
import 'services/clipboard_service.dart';
import 'services/connection_manager.dart';
import 'services/file_transfer_service.dart';
import 'services/mdns_registration.dart';
import 'services/notification_service.dart';
import 'services/pairing_service.dart';
import 'services/sms_service.dart';
import 'ui/home.dart';

class PhoneLinkApp extends StatelessWidget {
  final LocalDeviceConfigService configService;

  const PhoneLinkApp({Key? key, required this.configService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _AppProviders(configService: configService),
    );
  }
}

/// Sets up the full provider tree so every service is available app-wide
class _AppProviders extends StatelessWidget {
  final LocalDeviceConfigService configService;
  const _AppProviders({required this.configService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Config
        Provider.value(value: configService),

        // mDNS registration
        ChangeNotifierProvider(
          create: (_) => MdnsRegistrationController(configService),
        ),

        // Pairing — must be above ConnectionManager
        ChangeNotifierProvider(
          create: (_) => PairingService()..load(),
        ),

        // Connection (depends on PairingService)
        ChangeNotifierProxyProvider<PairingService, ConnectionManager>(
          create: (ctx) => ConnectionManager(
            configService,
            ctx.read<PairingService>(),
          ),
          update: (_, pairing, prev) =>
              prev ?? ConnectionManager(configService, pairing),
        ),

        // Feature services (all depend on ConnectionManager)
        ChangeNotifierProxyProvider<ConnectionManager, SmsService>(
          create: (ctx) => SmsService(
            ctx.read<ConnectionManager>(),
            configService,
          ),
          update: (_, conn, prev) =>
              prev ?? SmsService(conn, configService),
        ),

        ChangeNotifierProxyProvider<ConnectionManager, NotificationService>(
          create: (ctx) => NotificationService(
            ctx.read<ConnectionManager>(),
            configService,
          ),
          update: (_, conn, prev) =>
              prev ?? NotificationService(conn, configService),
        ),

        ChangeNotifierProxyProvider<ConnectionManager, ClipboardService>(
          create: (ctx) => ClipboardService(
            ctx.read<ConnectionManager>(),
            configService,
          ),
          update: (_, conn, prev) =>
              prev ?? ClipboardService(conn, configService),
        ),

        ChangeNotifierProxyProvider<ConnectionManager, FileTransferService>(
          create: (ctx) => FileTransferService(
            ctx.read<ConnectionManager>(),
            configService,
          ),
          update: (_, conn, prev) =>
              prev ?? FileTransferService(conn, configService),
        ),
      ],
      child: const HomePage(),
    );
  }
}
