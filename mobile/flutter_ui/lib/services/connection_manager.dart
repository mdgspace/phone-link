import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/packet.dart';
import '../data/discovered_device.dart';
import '../data/local_device.dart';
import '../data/paired_device.dart';
import 'pairing_service.dart';

enum ConnectionState {
  disconnected,
  connecting,
  handshaking,
  pairing,
  connected,
  reconnecting,
  error,
}

class ConnectionManager extends ChangeNotifier {
  final LocalDeviceConfigService _localConfig;
  final PairingService _pairingService;

  ConnectionState _state = ConnectionState.disconnected;
  Socket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _errorMessage;

  PairedDevice? _activeDevice;
  DiscoveredDevice? _targetDevice; // kept for reconnection

  // Streams for each feature to subscribe to
  final _packetController = StreamController<Packet>.broadcast();
  Stream<Packet> get packets => _packetController.stream;

  ConnectionState get state => _state;
  PairedDevice? get activeDevice => _activeDevice;
  bool get isConnected => _state == ConnectionState.connected;
  String? get errorMessage => _errorMessage;

  ConnectionManager(this._localConfig, this._pairingService);

  Future<void> connectTo(DiscoveredDevice device) async {
    if (_state == ConnectionState.connecting ||
        _state == ConnectionState.connected) return;

    _targetDevice = device;
    _setState(ConnectionState.connecting);

    try {
      _socket = await Socket.connect(
        device.ipv4.address,
        device.port,
        timeout: const Duration(seconds: 6),
      );
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      _listen();
      _sendHello();
      _setState(ConnectionState.handshaking);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _listen() {
    // Buffer across TCP frames — packets may arrive split or merged
    final buffer = StringBuffer();

    _socket!.listen(
      (data) {
        buffer.write(utf8.decode(data, allowMalformed: true));
        // Try to pull out newline-delimited packets
        final raw = buffer.toString();
        final lines = raw.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final packet = Packet.tryDecode(line);
          if (packet != null) _handlePacket(packet);
        }
        // Keep whatever's left (incomplete packet)
        buffer.clear();
        if (lines.last.isNotEmpty) buffer.write(lines.last);
      },
      onDone: _onDisconnected,
      onError: (e) {
        _errorMessage = e.toString();
        _onDisconnected();
      },
    );
  }

  void _handlePacket(Packet packet) {
    switch (packet.type) {
      case PacketType.helloAck:
        _onHelloAck(packet);
      case PacketType.pairingPin:
        _onPairingPin(packet);
      case PacketType.pairingAccepted:
        _onPairingAccepted(packet);
      case PacketType.pairingRejected:
        _errorMessage = 'Pairing rejected by remote device';
        _setState(ConnectionState.error);
      case PacketType.heartbeatAck:
        break; // just alive
      default:
        // Forward everything else to feature services via the stream
        _packetController.add(packet);
    }
  }

  void _onHelloAck(Packet packet) {
    final remoteId = packet.payload['device_id'] as String? ?? '';

    if (_pairingService.isTrusted(remoteId)) {
      // Already paired — go straight to connected
      _activeDevice = _pairingService.getDevice(remoteId)?.copyWith(
            lastKnownIp: _targetDevice?.ipv4.address ?? '',
          );
      _setState(ConnectionState.connected);
      _startHeartbeat();
    } else {
      // Need to pair first — send pairing request with our generated PIN
      final pin = _pairingService.generatePin(remoteId);
      _sendPacket(Packet(
        type: PacketType.pairingRequest,
        from: _localConfig.config.deviceId,
        payload: {'pin': pin},
      ));
      _setState(ConnectionState.pairing);
    }
  }

  void _onPairingPin(Packet packet) {
    // Remote sent a PIN — we just echo it back (user confirms on both screens)
    final pin = packet.payload['pin'] as String? ?? '';
    if (_pairingService.confirmPin(pin)) {
      _sendPacket(Packet(
        type: PacketType.pairingAccepted,
        from: _localConfig.config.deviceId,
        payload: {},
      ));
    }
  }

  Future<void> _onPairingAccepted(Packet packet) async {
    final remoteId = packet.from;
    final remoteName =
        packet.payload['device_name'] as String? ?? 'Unknown Device';

    final device = PairedDevice(
      deviceId: remoteId,
      deviceName: remoteName,
      platform: packet.payload['platform'] as String? ?? 'unknown',
      lastKnownIp: _targetDevice?.ipv4.address ?? '',
      port: _targetDevice?.port ?? 0,
    );

    await _pairingService.trustDevice(device);
    _activeDevice = device;
    _setState(ConnectionState.connected);
    _startHeartbeat();
  }

  void _sendHello() {
    _sendPacket(Packet(
      type: PacketType.hello,
      from: _localConfig.config.deviceId,
      payload: {
        'device_name': _localConfig.config.deviceName,
        'protocol': _localConfig.config.protocolVersion,
        'platform': 'android',
      },
    ));
  }

  void send(Packet packet) {
    if (!isConnected) return;
    _sendPacket(packet);
  }

  void _sendPacket(Packet packet) {
    try {
      _socket?.write('${packet.encode()}\n');
    } catch (e) {
      debugPrint('Send failed: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 20), (_) {
      _sendPacket(Packet(
        type: PacketType.heartbeat,
        from: _localConfig.config.deviceId,
        payload: {},
      ));
    });
  }

  void _onDisconnected() {
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _activeDevice = null;
    _setState(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_targetDevice == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 8), () {
      if (_state == ConnectionState.disconnected ||
          _state == ConnectionState.error) {
        _setState(ConnectionState.reconnecting);
        connectTo(_targetDevice!);
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _targetDevice = null;
    _sendPacket(Packet(
      type: PacketType.disconnect,
      from: _localConfig.config.deviceId,
      payload: {},
    ));
    _socket?.destroy();
    _socket = null;
    _activeDevice = null;
    _setState(ConnectionState.disconnected);
  }

  void _setState(ConnectionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _packetController.close();
    super.dispose();
  }
}
