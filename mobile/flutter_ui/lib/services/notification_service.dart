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
    _connection.packets.listen(_onPacket);
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
    final index = _notifications.indexWhere((n) => n.key == key);
    if (index < 0) return;

    _notifications.removeAt(index);
    notifyListeners();
  }

  Future<void> _onPacket(Packet packet) async {
    if (packet.type != PacketType.notificationDismiss) return;

    final key = packet.payload['key'] as String? ?? '';
    if (key.isEmpty) return;

    try {
      await _channel.invokeMethod('dismissNotification', {'key': key});
    } catch (e) {
      debugPrint('dismissNotification error: $e');
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationPosted':
        final notif = PhoneNotification.fromJson(
            Map<String, dynamic>.from(call.arguments as Map));

        // Android reuses the same StatusBarNotification key when an existing
        // notification is updated (for example, a message notification
        // receiving another message). Do not keep multiple copies with the
        // same key: Dismissible/Provider removal would otherwise remove every
        // copy at once.
        final existingIndex =
            _notifications.indexWhere((n) => n.key == notif.key);

        if (existingIndex >= 0) {
          _notifications[existingIndex] = notif;
        } else {
          _notifications.insert(0, notif);
        }

        if (_notifications.length > 100) {
          _notifications.removeLast();
        }

        notifyListeners();

        _connection.send(Packet(
          type: PacketType.notificationPosted,
          from: _localConfig.config.deviceId,
          payload: notif.toJson(),
        ));

      case 'onNotificationRemoved':
        final key = (call.arguments as Map)['key'] as String? ?? '';
        final index = _notifications.indexWhere((n) => n.key == key);

        if (index >= 0) {
          _notifications.removeAt(index);
          notifyListeners();
        }

        _connection.send(Packet(
          type: PacketType.notificationDismissed,
          from: _localConfig.config.deviceId,
          payload: {'key': key},
        ));
    }
  }
}
