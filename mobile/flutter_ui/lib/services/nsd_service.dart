import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;

class NsdService extends ChangeNotifier {
  nsd.Discovery? _discovery;
  final List<nsd.Service> _discoveredServices = [];
  bool _isDiscovering = false;

  List<nsd.Service> get discoveredServices => _discoveredServices;
  bool get isDiscovering => _isDiscovering;

  /// The service type identifier that the Qt Desktop app will broadcast.
  final String serviceType = '_phonelink._tcp';

  /// Starts discovering the Phone-Link desktop application on the local network.
  Future<void> startScanning() async {
    if (_isDiscovering) return;

    try {
      _isDiscovering = true;
      _discoveredServices.clear();
      notifyListeners();

      _discovery = await nsd.startDiscovery(serviceType, ipLookupType: nsd.IpLookupType.any);

      _discovery!.addListener(() {
        _discoveredServices.clear();
        _discoveredServices.addAll(_discovery!.services);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error starting NSD discovery: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Stops the discovery process.
  Future<void> stopScanning() async {
    if (!_isDiscovering || _discovery == null) return;

    try {
      await nsd.stopDiscovery(_discovery!);
      _isDiscovering = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping NSD discovery: $e');
    }
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }
}