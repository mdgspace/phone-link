import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class NetworkService extends ChangeNotifier {
  Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Connects to the desktop server using the provided [host] IP and [port].
  Future<void> connect(String host, int port) async {
    if (_isConnected) return;

    try {
      debugPrint('Connecting to $host:$port...');
      // Attempt to establish a TCP connection
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _isConnected = true;
      notifyListeners();

      debugPrint('Connected successfully to $host:$port');

      // Listen for incoming messages or connection drops from the desktop server
      _socket!.listen(
        (List<int> data) {
          final response = utf8.decode(data);
          debugPrint('Received from server: $response');
        },
        onError: (error) {
          debugPrint('Socket error: $error');
          disconnect();
        },
        onDone: () {
          debugPrint('Socket closed by server.');
          disconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect: $e');
      _isConnected = false;
      notifyListeners();
      // Rethrow to let the UI layer handle the error (e.g., showing a snackbar)
      rethrow;
    }
  }

  /// Sends a JSON-encoded payload to the connected desktop server.
  void sendNotificationPayload(Map<String, dynamic> payload) {
    if (!_isConnected || _socket == null) {
      debugPrint('Cannot send data. Socket is not connected.');
      return;
    }

    try {
      final jsonString = jsonEncode(payload);
      // Add a newline as a delimiter to help the Qt server parse messages easily
      _socket!.write('$jsonString\n'); 
      debugPrint('Sent payload: $jsonString');
    } catch (e) {
      debugPrint('Error sending payload: $e');
    }
  }

  /// Safely disconnects and cleans up the socket.
  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}