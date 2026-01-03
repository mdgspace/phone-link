import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart';

class MdnsDiscoveryController extends ChangeNotifier {
  Discovery? _discovery;

  List<Service> get services => _discovery?.services ?? [];

  bool get isRunning => _discovery != null;

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
