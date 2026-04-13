import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/packet.dart';
import '../data/local_device.dart';
import '../data/phone_notification.dart';
import 'connection_manager.dart';

const _channel = MethodChannel('com.example.flutter_ui/notifications');

class NotificationService extends ChangeNotifier {
  final ConnectionManager _connection;
  final LocalDeviceConfigService _localConfig;

  final List<PhoneNotification> _notifications = [];
  bool _listenerActive = false;

  NotificationService(this._connection, this._localConfig) {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  List<PhoneNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get listenerActive => _listenerActive;

  /// Opens Android notification access settings so the user can grant permission
  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('openNotificationSettings error: $e');
    }
  }

  Future<void> checkListenerActive() async {
    try {
      _listenerActive =
          await _channel.invokeMethod<bool>('isListenerActive') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  void dismiss(String key) {
    _notifications.removeWhere((n) => n.key == key);
    notifyListeners();
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationPosted':
        final notif = PhoneNotification.fromJson(
            Map<String, dynamic>.from(call.arguments as Map));
        _notifications.insert(0, notif);
        if (_notifications.length > 100) _notifications.removeLast();
        notifyListeners();

        _connection.send(Packet(
          type: PacketType.notificationPosted,
          from: _localConfig.config.deviceId,
          payload: notif.toJson(),
        ));

      case 'onNotificationRemoved':
        final key = (call.arguments as Map)['key'] as String? ?? '';
        _notifications.removeWhere((n) => n.key == key);
        notifyListeners();

        _connection.send(Packet(
          type: PacketType.notificationDismissed,
          from: _localConfig.config.deviceId,
          payload: {'key': key},
        ));
    }
  }
}
