import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

Future<String?> getLocalIPv4() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  // Do not assume the interface is named wlan0; Android OEMs vary.
  final preferred = <NetworkInterface>[
    ...interfaces.where((i) {
      final n = i.name.toLowerCase();
      return n.contains('wlan') || n.contains('wifi') || n.contains('ap');
    }),
    ...interfaces,
  ];

  final seen = <String>{};
  for (final interface in preferred) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          !addr.isLoopback &&
          seen.add(addr.address)) {
        return addr.address;
      }
    }
  }
  return null;
}

Stream<bool> wifiAvailableStream() async* {
  yield await _isLocalNetworkUsable();

  await for (final _ in Connectivity().onConnectivityChanged) {
    yield await _isLocalNetworkUsable();
  }
}

Future<bool> _isLocalNetworkUsable() async {
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return false;

    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    return interfaces.any(
      (interface) => interface.addresses.any(
        (addr) => addr.type == InternetAddressType.IPv4 && !addr.isLoopback,
      ),
    );
  } catch (_) {
    return false;
  }
}
