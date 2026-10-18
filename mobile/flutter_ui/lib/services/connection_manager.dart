import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/packet.dart';
import '../data/discovered_device.dart';
import '../data/local_device.dart';
import '../data/paired_device.dart';
import '../utils/helpers.dart';
import 'mdns_discovery.dart';
import 'pairing_service.dart';

const String _phoneLinkServerCertificate = r'''-----BEGIN CERTIFICATE-----
MIIDGTCCAgGgAwIBAgIUUEwBNAdDF2NhtoBlBjVq9BgqEQowDQYJKoZIhvcNAQEL
BQAwHDEaMBgGA1UEAwwRUGhvbmVMaW5rIERlc2t0b3AwHhcNMjYxMDE3MTQ1ODI3
WhcNMzYxMDE0MTQ1ODI3WjAcMRowGAYDVQQDDBFQaG9uZUxpbmsgRGVza3RvcDCC
ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALvrxIE3ONPe9qGWe8LOo8sG
cfV7pFF0TFJPREFiERjMVdPWz9hmH2DRf7v5av8lCzrCNfow7hm9IgTbVpLNxkdN
w+zcpDO8yyFrzq3yweL8H32aT4cHtkwCJguyP+Gg/OBJVzPRnqWKMCHLd72K1ChU
0hz3W38HVfOfQzaVe7zInBv75hHQFm7L4/ltNObTsC5JzVbJcsH1ykK1gmbrEjX/
ZcH29J2Vc/6OpOt4nyg38zGoTaiVUf9tAGgs25dOgVlvDdINUQA175dQmF5bRL/7
EBXJ6+t1MBXkmQnZeJFi9G8Iukv6IUbyNIxXgvm7YUIIsvp4Ps4lrVa+Hg02PF0C
AwEAAaNTMFEwHQYDVR0OBBYEFEAFv73bfN4q5uEYUBnF/otzgDV7MB8GA1UdIwQY
MBaAFEAFv73bfN4q5uEYUBnF/otzgDV7MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAEgYq0h/rQq8p346eygf5JP/ZgIsfJyO4O62KhKZFAhoEXuQ
8yUT78IXAt+jwGSMszNZ32SddFSXlu1+CRpaeJrWsj/KuKyFx9h6QWObOI+P2ZMf
0tzcwz17pDmSvQdHxyG7/E9BHOy0S8DjUlfeva3t3a3nH+owdbKvR7waqiSTkttS
KOoCmsHM64YiQqYiCoWntnsqiqFCbrcccU4+qr2eonCmXllew+A5R22aCmz+Yc4n
U52pEAvCWP/0xXvSksOxX5Ris+lgxo8t4YCJr5yMoDcya9Jh3EwETm0UqSVCg9hq
FUTFEdgmWq4woatJqDVKtH8E+oCvtNk+217ed40=
-----END CERTIFICATE-----
''';

Future<Socket> _defaultOpenSocket(String host, int port) {
  return SecureSocket.connect(
    host,
    port,
    timeout: const Duration(seconds: 6),
    onBadCertificate: (certificate) {
      debugPrint('========== SERVER CERTIFICATE ==========');
      debugPrint(certificate.pem);
      debugPrint('========================================');
      debugPrint(
        'SHA256: ${certificate.der.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );

      return certificate.pem.trim() == _phoneLinkServerCertificate.trim();
    },
  );
}

enum ConnectionState {
  disconnected,
  connecting,
  handshaking,
  pairing,
  connected,
  reconnecting,
  waitingForNetwork,
  error,
}

class ConnectionManager extends ChangeNotifier {
  static const _defaultBackoff = [2, 4, 8, 16, 30];

  final LocalDeviceConfigService _localConfig;
  final PairingService _pairingService;
  final MdnsDiscoveryController _discovery;
  final Future<Socket> Function(String host, int port) _openSocket;
  final Stream<bool> Function() _networkEvents;
  final Future<bool> Function() _networkCheck;
  final Duration _heartbeatInterval;
  final Duration _heartbeatAckTimeout;
  final Duration _discoverWindow;
  final List<int> _backoffSteps;

  ConnectionState _state = ConnectionState.disconnected;
  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSub;
  Timer? _heartbeatTimer;
  Timer? _ackTimeout;
  Timer? _reconnectTimer;
  StreamSubscription<bool>? _networkSub;
  String? _errorMessage;

  PairedDevice? _activeDevice;
  DiscoveredDevice? _targetDevice;
  String? _targetDeviceId;

  bool _wantsSession = false;
  bool _networkUp = false;
  int _backoffIndex = 0;
  int _connectGeneration = 0;
  bool _handlingDisconnect = false;

  // Streams for each feature to subscribe to
  final _packetController = StreamController<Packet>.broadcast();
  Stream<Packet> get packets => _packetController.stream;

  ConnectionState get state => _state;
  PairedDevice? get activeDevice => _activeDevice;
  bool get isConnected => _state == ConnectionState.connected;
  String? get errorMessage => _errorMessage;

  ConnectionManager(
    this._localConfig,
    this._pairingService,
    this._discovery, {
    Future<Socket> Function(String host, int port)? openSocket,
    Stream<bool> Function()? networkEvents,
    Future<bool> Function()? networkCheck,
    Duration? heartbeatInterval,
    Duration? heartbeatAckTimeout,
    Duration? discoverWindow,
    List<int>? backoffSteps,
  })  : _openSocket = openSocket ?? _defaultOpenSocket,
        _networkEvents = networkEvents ?? wifiAvailableStream,
        _networkCheck = networkCheck ?? isLocalNetworkUsable,
        _heartbeatInterval = heartbeatInterval ?? const Duration(seconds: 20),
        _heartbeatAckTimeout =
            heartbeatAckTimeout ?? const Duration(seconds: 25),
        _discoverWindow = discoverWindow ?? const Duration(seconds: 4),
        _backoffSteps = backoffSteps ?? _defaultBackoff {
    _watchNetwork();
  }

  /// Dial the desktop saved from the last session that reached `connected`.
  /// No-op when the user disconnected or nothing has been paired yet.
  Future<void> restoreLastSession() async {
    final saved = _pairingService.resumeDevice;
    if (saved == null || saved.lastKnownIp.isEmpty || saved.port == 0) return;

    _wantsSession = true;
    _backoffIndex = 0;
    _targetDeviceId = saved.deviceId;
    _targetDevice = DiscoveredDevice(
      instanceName: saved.deviceName,
      deviceName: saved.deviceName,
      ipv4: InternetAddress(saved.lastKnownIp),
      port: saved.port,
      txt: {'id': saved.deviceId, 'name': saved.deviceName},
    );

    _networkUp = await _networkCheck();
    if (!_wantsSession) return;
    if (!_networkUp) {
      _setState(ConnectionState.waitingForNetwork);
      return;
    }
    await _attemptReconnect();
  }

  void _watchNetwork() {
    _networkSub = _networkEvents().listen((up) {
      final becameUp = up && !_networkUp;
      _networkUp = up;
      if (!up) {
        _reconnectTimer?.cancel();
        if (!_wantsSession) return;
        // A backoff wait sits in `disconnected`. Still tell the user we are
        // paused on the radio, and abort a dial that is already in flight.
        if (_state != ConnectionState.disconnected &&
            _state != ConnectionState.waitingForNetwork) {
          _connectGeneration++;
          _dropSocket();
        }
        _setState(ConnectionState.waitingForNetwork);
        return;
      }
      if (becameUp && _wantsSession && !isConnected) {
        _attemptReconnect();
      }
    }, onError: (Object _) {});
  }

  Future<void> connectTo(
    DiscoveredDevice device, {
    bool userInitiated = true,
  }) async {
    if (_state == ConnectionState.connecting ||
        _state == ConnectionState.handshaking ||
        _state == ConnectionState.pairing) {
      return;
    }
    if (!userInitiated && !_wantsSession) return;

    if (userInitiated) {
      _wantsSession = true;
      _backoffIndex = 0;
    }

    final generation = ++_connectGeneration;
    _targetDevice = device;
    final txtId = device.txt['id'];
    if (txtId != null && txtId.isNotEmpty) {
      _targetDeviceId = txtId;
    }
    _reconnectTimer?.cancel();
    _dropSocket();
    _errorMessage = null;
    _setState(ConnectionState.connecting);

    try {
      final socket = await _openSocket(device.ipv4.address, device.port);
      if (generation != _connectGeneration) {
        socket.destroy();
        return;
      }
      _socket = socket;
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      _listen();
      _sendHello();
      _setState(ConnectionState.handshaking);
    } catch (e) {
      if (generation != _connectGeneration) return;
      _errorMessage = e.toString();
      _dropSocket();
      _setState(ConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _listen() {
    final socket = _socket;
    if (socket == null) return;

    // Buffer across TCP frames — packets may arrive split or merged
    final buffer = StringBuffer();

    _socketSub = socket.listen(
      (data) {
        if (_socket != socket) return;
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
      onDone: () {
        if (_socket != socket) return;
        _onDisconnected();
      },
      onError: (e) {
        if (_socket != socket) return;
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
        _onHeartbeatAck();
      default:
        // Forward everything else to feature services via the stream
        _packetController.add(packet);
    }
  }

  void _onHelloAck(Packet packet) {
    final remoteId = packet.payload['device_id'] as String? ?? '';

    if (_pairingService.isTrusted(remoteId)) {
      // Already paired — go straight to connected and remember this address.
      final known = _pairingService.getDevice(remoteId);
      final updated = (known ??
              PairedDevice(
                deviceId: remoteId,
                deviceName: _targetDevice?.deviceName ?? 'Desktop',
                platform: 'desktop',
                lastKnownIp: _targetDevice?.ipv4.address ?? '',
                port: _targetDevice?.port ?? 0,
              ))
          .copyWith(
        lastKnownIp: _targetDevice?.ipv4.address ?? known?.lastKnownIp ?? '',
        port: _targetDevice?.port ?? known?.port,
      );
      _activeDevice = updated;
      if (remoteId.isNotEmpty) _targetDeviceId = remoteId;
      unawaited(_pairingService.trustDevice(updated));
      _backoffIndex = 0;
      _setState(ConnectionState.connected);
      _startHeartbeat();
      unawaited(_pairingService.setResumeDevice(remoteId));
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
    if (remoteId.isNotEmpty) _targetDeviceId = remoteId;
    await _pairingService.setResumeDevice(remoteId);
    _activeDevice = device;
    _backoffIndex = 0;
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
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  void _sendHeartbeat() {
    _sendPacket(Packet(
      type: PacketType.heartbeat,
      from: _localConfig.config.deviceId,
      payload: {},
    ));
    _armAckTimeout();
  }

  void _armAckTimeout() {
    _ackTimeout?.cancel();
    _ackTimeout = Timer(_heartbeatAckTimeout, _onDisconnected);
  }

  void _onHeartbeatAck() {
    _ackTimeout?.cancel();
    _ackTimeout = null;
    _backoffIndex = 0;
  }

  void _onDisconnected() {
    if (_handlingDisconnect) return;
    _handlingDisconnect = true;
    _dropSocket();
    _activeDevice = null;
    _handlingDisconnect = false;

    if (!_wantsSession) {
      _setState(ConnectionState.disconnected);
      return;
    }
    if (!_networkUp) {
      _setState(ConnectionState.waitingForNetwork);
      return;
    }
    _setState(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _dropSocket() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _ackTimeout?.cancel();
    _ackTimeout = null;
    final sub = _socketSub;
    _socketSub = null;
    final socket = _socket;
    _socket = null;
    if (sub != null) unawaited(sub.cancel());
    socket?.destroy();
  }

  void _scheduleReconnect() {
    if (!_wantsSession || _targetDevice == null) return;
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: _backoffSteps[_backoffIndex]);
    _backoffIndex = min(_backoffIndex + 1, _backoffSteps.length - 1);
    _reconnectTimer = Timer(delay, () {
      if (!_wantsSession) return;
      if (!_networkUp) {
        _setState(ConnectionState.waitingForNetwork);
        return;
      }
      _attemptReconnect();
    });
  }

  Future<void> _attemptReconnect() async {
    if (!_wantsSession || _targetDevice == null) return;
    if (_state == ConnectionState.connecting ||
        _state == ConnectionState.handshaking ||
        _state == ConnectionState.pairing ||
        _state == ConnectionState.reconnecting ||
        _state == ConnectionState.connected) {
      return;
    }

    _setState(ConnectionState.reconnecting);
    final fresh = await _discoverTarget();
    if (!_wantsSession || _targetDevice == null) return;
    if (!_networkUp) {
      _setState(ConnectionState.waitingForNetwork);
      return;
    }
    if (_state != ConnectionState.reconnecting) return;
    await connectTo(fresh ?? _targetDevice!, userInitiated: false);
  }

  Future<DiscoveredDevice?> _discoverTarget() async {
    final id = _targetDeviceId;
    if (id == null || id.isEmpty) return null;

    try {
      await _discovery.start();
    } catch (_) {
      return null;
    }

    final existing = _discovery.findByDeviceId(id);
    if (existing != null) return existing;

    final done = Completer<DiscoveredDevice?>();
    void listener() {
      final found = _discovery.findByDeviceId(id);
      if (found != null && !done.isCompleted) done.complete(found);
    }

    _discovery.addListener(listener);
    try {
      return await done.future.timeout(
        _discoverWindow,
        onTimeout: () => null,
      );
    } finally {
      _discovery.removeListener(listener);
    }
  }

  Future<void> disconnect() async {
    _wantsSession = false;
    _connectGeneration++;
    _reconnectTimer?.cancel();
    _targetDevice = null;
    _targetDeviceId = null;
    _backoffIndex = 0;
    await _pairingService.setResumeDevice(null);
    _sendPacket(Packet(
      type: PacketType.disconnect,
      from: _localConfig.config.deviceId,
      payload: {},
    ));
    _dropSocket();
    _activeDevice = null;
    _setState(ConnectionState.disconnected);
  }

  void _setState(ConnectionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    // Do not call disconnect(): that clears resume_device_id, and the next
    // launch would stay offline. Closing the app must keep the saved desktop.
    _wantsSession = false;
    _connectGeneration++;
    _reconnectTimer?.cancel();
    _networkSub?.cancel();
    _dropSocket();
    _packetController.close();
    super.dispose();
  }
}
