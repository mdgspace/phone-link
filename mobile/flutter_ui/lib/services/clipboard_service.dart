import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/packet.dart';
import '../data/local_device.dart';
import 'connection_manager.dart';

class ClipboardService extends ChangeNotifier {
  final ConnectionManager _connection;
  final LocalDeviceConfigService _localConfig;

  String? _lastSynced;

  ClipboardService(this._connection, this._localConfig) {
    _connection.packets.listen(_onPacket);
  }

  String? get lastSynced => _lastSynced;

  /// Push current clipboard content to the desktop
  Future<void> pushToDesktop() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    _connection.send(Packet(
      type: PacketType.clipboardPush,
      from: _localConfig.config.deviceId,
      payload: {'text': text},
    ));

    _lastSynced = text;
    notifyListeners();
  }

  void _onPacket(Packet packet) async {
    if (packet.type == PacketType.clipboardPush) {
      final text = packet.payload['text'] as String? ?? '';
      if (text.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: text));
      _lastSynced = text;
      notifyListeners();
    }
  }
}
