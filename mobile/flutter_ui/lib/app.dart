import 'package:flutter/material.dart';
import 'package:flutter_ui/services/mdns_registration.dart';
import 'package:provider/provider.dart';
import 'data/local_device.dart';
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
      home: MultiProvider(
        providers: [
          // 1. Provide the Service itself (in case other widgets need it)
          Provider.value(value: configService),

          // 2. Provide the Controller and inject the Service
          ChangeNotifierProvider(
            create: (_) => MdnsRegistrationController(configService),
          ),
        ],
        child: const HomePage(),
      ),
    );
  }
}
