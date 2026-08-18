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
    // Providers are intentionally ABOVE MaterialApp. Modal routes created by
    // its Navigator must be able to access ConnectionManager.
    return MultiProvider(
      providers: [
        Provider<LocalDeviceConfigService>.value(value: configService),
        ChangeNotifierProvider<MdnsRegistrationController>(
          create: (_) => MdnsRegistrationController(configService),
        ),
        ChangeNotifierProvider<PairingService>(
          create: (_) => PairingService()..load(),
        ),
        ChangeNotifierProxyProvider<PairingService, ConnectionManager>(
          create: (ctx) => ConnectionManager(
            configService,
            ctx.read<PairingService>(),
          ),
          update: (_, pairing, previous) {
            // Keep the same ConnectionManager instance. It owns the TCP
            // connection state and must not be recreated on rebuilds.
            if (previous != null) {
              return previous;
            }
            return ConnectionManager(configService, pairing);
          },
        ),
        ChangeNotifierProxyProvider<ConnectionManager, SmsService>(
          create: (ctx) => SmsService(ctx.read<ConnectionManager>(), configService),
          update: (_, conn, previous) =>
              previous ?? SmsService(conn, configService),
        ),
        ChangeNotifierProxyProvider<ConnectionManager, NotificationService>(
          create: (ctx) =>
              NotificationService(ctx.read<ConnectionManager>(), configService),
          update: (_, conn, previous) =>
              previous ?? NotificationService(conn, configService),
        ),
        ChangeNotifierProxyProvider<ConnectionManager, ClipboardService>(
          create: (ctx) =>
              ClipboardService(ctx.read<ConnectionManager>(), configService),
          update: (_, conn, previous) =>
              previous ?? ClipboardService(conn, configService),
        ),
        ChangeNotifierProxyProvider<ConnectionManager, FileTransferService>(
          create: (ctx) =>
              FileTransferService(ctx.read<ConnectionManager>(), configService),
          update: (_, conn, previous) =>
              previous ?? FileTransferService(conn, configService),
        ),
      ],
      child: MaterialApp(
        title: 'Phone Link',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
