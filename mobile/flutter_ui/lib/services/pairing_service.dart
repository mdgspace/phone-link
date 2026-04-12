import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/paired_device.dart';

const _kPairedDevicesKey = 'paired_devices';

class PairingService extends ChangeNotifier {
  List<PairedDevice> _paired = [];
  String? _pendingPin;
  String? _pendingDeviceId;

  List<PairedDevice> get pairedDevices => List.unmodifiable(_paired);
  String? get pendingPin => _pendingPin;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPairedDevicesKey);
    if (raw != null && raw.isNotEmpty) {
      _paired = PairedDevice.listFromJson(raw);
    }
  }

  bool isTrusted(String deviceId) =>
      _paired.any((d) => d.deviceId == deviceId);

  PairedDevice? getDevice(String deviceId) {
    try {
      return _paired.firstWhere((d) => d.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  /// Generates a PIN for outgoing pairing request and stashes the target device id
  String generatePin(String targetDeviceId) {
    _pendingDeviceId = targetDeviceId;
    _pendingPin = (Random().nextInt(900000) + 100000).toString();
    notifyListeners();
    return _pendingPin!;
  }

  /// Called when the remote side confirms by echoing back the same PIN
  bool confirmPin(String pin) => pin == _pendingPin;

  Future<void> trustDevice(PairedDevice device) async {
    // Update lastKnownIp if already paired
    final existing = _paired.indexWhere((d) => d.deviceId == device.deviceId);
    if (existing >= 0) {
      _paired[existing] = device;
    } else {
      _paired.add(device);
    }
    _pendingPin = null;
    _pendingDeviceId = null;
    await _persist();
    notifyListeners();
  }

  Future<void> removeDevice(String deviceId) async {
    _paired.removeWhere((d) => d.deviceId == deviceId);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kPairedDevicesKey, PairedDevice.listToJson(_paired));
  }

  void cancelPairing() {
    _pendingPin = null;
    _pendingDeviceId = null;
    notifyListeners();
  }
}
