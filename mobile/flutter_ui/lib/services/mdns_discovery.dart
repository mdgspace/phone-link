import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

import '../data/discovered_device.dart';

class MdnsDiscoveryController extends ChangeNotifier {
  Discovery? _discovery;
  String? _errorMessage;
  bool _starting = false;

  List<Service> get _rawServices => _discovery?.services ?? [];
  bool get isRunning => _discovery != null;
  bool get isStarting => _starting;
  String? get errorMessage => _errorMessage;

  List<DiscoveredDevice> get devices {
    final result = <DiscoveredDevice>[];
    final seen = <String>{};

    for (final service in _rawServices) {
      final ipv4 = service.addresses
          ?.where((a) => a.type == InternetAddressType.IPv4)
          .firstOrNull;

      if (ipv4 == null || service.port == null || service.port == 0) continue;

      final txt = <String, String>{};
      service.txt?.forEach((key, value) {
        if (value != null) {
          txt[key] = utf8.decode(value, allowMalformed: true);
        }
      });

      final device = DiscoveredDevice(
        instanceName: service.name ?? 'Unknown',
        deviceName: txt['name'] ?? service.name ?? 'Unknown Device',
        ipv4: ipv4,
        port: service.port!,
        txt: txt,
      );

      final key = '${device.ipv4.address}:${device.port}:${device.instanceName}';
      if (seen.add(key)) result.add(device);
    }

    return result;
  }

  Future<void> start() async {
    if (_discovery != null || _starting) return;

    _starting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final discovery = await startDiscovery(
        '_phonelink._tcp',
        ipLookupType: IpLookupType.any,
      );
      _discovery = discovery;
      discovery.addListener(notifyListeners);
    } catch (e) {
      _errorMessage = _friendlyError(e);
      debugPrint('mDNS discovery failed: $e');
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('multicast') || lower.contains('permission')) {
      return 'Local-network discovery is blocked. Check Wi-Fi/multicast '
          'permission for Phone Link.';
    }
    return 'Could not start device discovery: $text';
  }

  Future<void> stop() async {
    final discovery = _discovery;
    if (discovery == null) return;

    discovery.removeListener(notifyListeners);
    try {
      await stopDiscovery(discovery);
    } catch (e) {
      debugPrint('mDNS discovery stop failed: $e');
    }
    _discovery = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
