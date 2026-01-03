import 'package:flutter/material.dart';
import 'package:flutter_ui/services/mdns_registration.dart';
import 'package:provider/provider.dart';
import 'ui/home.dart';

class PhoneLinkApp extends StatelessWidget {
  const PhoneLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => MdnsRegistrationController(
                deviceName: "Phone",
                port: 5000,
                serviceType: "_phonelink._tcp"),
          ),
        ],
        child: const HomePage(),
      ),
    );
  }
}
