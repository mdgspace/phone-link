import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isServiceEnabled = true;

  bool get isServiceEnabled => _isServiceEnabled;

  /// Loads the active settings from local storage.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isServiceEnabled = _prefs?.getBool('isServiceEnabled') ?? true;
    notifyListeners();
  }

  /// Toggles the master switch for the Phone-Link service.
  Future<void> toggleService(bool value) async {
    _isServiceEnabled = value;
    await _prefs?.setBool('isServiceEnabled', value);
    notifyListeners();
  }
}