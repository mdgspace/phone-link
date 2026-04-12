import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

import '../data/discovered_device.dart';

class MdnsDiscoveryController extends ChangeNotifier {
  Discovery? _discovery;

  List<Service> get _rawServices => _discovery?.services ?? [];
  bool get isRunning => _discovery != null;

  List<DiscoveredDevice> get devices {
    return _rawServices.map((service) {
      final ipv4 = service.addresses
          ?.where((a) => a.type == InternetAddressType.IPv4)
          .firstOrNull;

      final Map<String, String> txt = {};
      service.txt?.forEach((key, value) {
        if (value != null) txt[key] = utf8.decode(value);
      });

      return DiscoveredDevice(
        instanceName: service.name ?? 'Unknown',
        deviceName: txt['name'] ?? service.name ?? 'Unknown Device',
        ipv4: ipv4 ?? InternetAddress('0.0.0.0'),
        port: service.port ?? 0,
        txt: txt,
      );
    }).toList();
  }

  Future<void> start() async {
    if (_discovery != null) return;
    _discovery = await startDiscovery('_phonelink._tcp');
    _discovery!.addListener(notifyListeners);
    notifyListeners();
  }

  Future<void> stop() async {
    if (_discovery == null) return;
    _discovery!.removeListener(notifyListeners);
    await stopDiscovery(_discovery!);
    _discovery = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
