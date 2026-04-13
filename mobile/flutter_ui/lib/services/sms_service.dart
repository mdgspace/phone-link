import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/packet.dart';
import '../data/local_device.dart';
import '../data/sms_message.dart';
import 'connection_manager.dart';

const _channel = MethodChannel('com.example.flutter_ui/sms');

class SmsService extends ChangeNotifier {
  final ConnectionManager _connection;
  final LocalDeviceConfigService _localConfig;

  // address → messages
  final Map<String, List<SmsMessage>> _threads = {};
  bool _permissionGranted = false;

  SmsService(this._connection, this._localConfig) {
    _connection.packets.listen(_onPacket);
    _channel.setMethodCallHandler(_onNativeCall);
  }

  Map<String, List<SmsMessage>> get threads => Map.unmodifiable(_threads);
  bool get hasPermission => _permissionGranted;

  List<SmsThread> get threadList {
    final result = _threads.entries
        .map((e) => SmsThread(address: e.key, messages: e.value))
        .toList();
    result.sort((a, b) =>
        b.latest.timestamp.compareTo(a.latest.timestamp));
    return result;
  }

  Future<bool> requestPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestSmsPermission') ?? false;
      _permissionGranted = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      debugPrint('SMS permission error: $e');
      return false;
    }
  }

  Future<void> fetchAllSms() async {
    try {
      final List<dynamic> raw =
          await _channel.invokeMethod('getAllSms') ?? [];
      _threads.clear();
      for (final item in raw) {
        final msg = SmsMessage.fromJson(Map<String, dynamic>.from(item as Map));
        _threads.putIfAbsent(msg.address, () => []).add(msg);
      }
      // Sort each thread oldest → newest
      for (final thread in _threads.values) {
        thread.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchAllSms error: $e');
    }
  }

  Future<void> sendSms(String address, String body) async {
    try {
      await _channel
          .invokeMethod('sendSms', {'address': address, 'body': body});
      // Optimistically add to local thread
      final msg = SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        address: address,
        body: body,
        isIncoming: false,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      _threads.putIfAbsent(address, () => []).add(msg);
      notifyListeners();
    } catch (e) {
      debugPrint('sendSms error: $e');
    }
  }

  // Handle a new SMS arriving from desktop (sms_send packet)
  void _onPacket(Packet packet) {
    if (packet.type == PacketType.smsSend) {
      final address = packet.payload['address'] as String? ?? '';
      final body = packet.payload['body'] as String? ?? '';
      sendSms(address, body);
    }
  }

  // Handle incoming SMS from Kotlin (new message arrived on phone)
  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      final msg = SmsMessage.fromJson(
          Map<String, dynamic>.from(call.arguments as Map));
      _threads.putIfAbsent(msg.address, () => []).add(msg);
      notifyListeners();

      // Forward to desktop if connected
      _connection.send(Packet(
        type: PacketType.smsReceived,
        from: _localConfig.config.deviceId,
        payload: msg.toJson(),
      ));
    }
  }
}
