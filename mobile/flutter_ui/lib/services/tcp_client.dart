import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';

enum ConnectionStateX {
  disconnected,
  connecting,
  handshaking,
  pairing,
  connected,
  error,
}

class ConnectedDevice {
  final String id;
  final String name;
  final String host;
  final int port;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });
}

class ConnectionManager extends ChangeNotifier {
  ConnectionStateX _state = ConnectionStateX.disconnected;
  Socket? _socket;
  String? error;

  ConnectionStateX get state => _state;

  void _setState(ConnectionStateX newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> connect(String host, int port) async {
    _setState(ConnectionStateX.connecting);

    try {
      _socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      _setState(ConnectionStateX.handshaking);

      _listen();
      _sendHello();
    } catch (e) {
      error = e.toString();
      _setState(ConnectionStateX.error);
    }
  }

  void _listen() {
    _socket!.listen(
      (data) {
        _handleMessage(String.fromCharCodes(data));
      },
      onDone: () {
        _setState(ConnectionStateX.disconnected);
      },
      onError: (e) {
        error = e.toString();
        _setState(ConnectionStateX.error);
      },
    );
  }

  void _sendHello() {
    final msg = {
      "type": "hello",
      "deviceId": "phone-uuid",
      "deviceName": "My Android",
      "protocol": 1,
    };

    _socket!.write(jsonEncode(msg));
  }

  void _handleMessage(String raw) {
    final msg = jsonDecode(raw);

    switch (msg["type"]) {
      case "hello_ack":
        if (msg["paired"] == true) {
          _setState(ConnectionStateX.connected);
        } else {
          _setState(ConnectionStateX.pairing);
        }
        break;

      case "pairing_done":
        _setState(ConnectionStateX.connected);
        break;
    }
  }

  void disconnect() {
    _socket?.destroy();
    _setState(ConnectionStateX.disconnected);
  }
}
