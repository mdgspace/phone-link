import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

Future<String?> getLocalIPv4() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return null;
}

Stream<bool> wifiAvailableStream() async* {
  // Emit initial state
  yield await _isWifiUsable();

  // Listen for connectivity changes
  await for (final _ in Connectivity().onConnectivityChanged) {
    yield await _isWifiUsable();
  }
}

Future<bool> _isWifiUsable() async {
  final connectivity = await Connectivity().checkConnectivity();

  if (connectivity == ConnectivityResult.none) {
    return false;
  }

  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
  );

  for (final interface in interfaces) {
    if (interface.name == 'wlan0') {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return true;
        }
      }
    }
  }

  return false;
}
