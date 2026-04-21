import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/network_service.dart';
import 'services/notification_service.dart';
import 'services/nsd_service.dart';
import 'services/settings_service.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkService()),
        ChangeNotifierProvider(create: (_) => NsdService()),
        ChangeNotifierProvider(create: (_) => SettingsService()..init()),
        // ProxyProvider safely injects NetworkService into NotificationService
        ChangeNotifierProxyProvider<NetworkService, NotificationService>(
          create: (context) => NotificationService(networkService: context.read<NetworkService>()),
          update: (context, networkService, previous) => previous ?? NotificationService(networkService: networkService),
        ),
      ],
      child: child,
    );
  }
}