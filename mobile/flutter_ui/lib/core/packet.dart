import 'dart:convert';

// All packet types exchanged between phone and desktop
class PacketType {
  // Handshake
  static const String hello = 'hello';
  static const String helloAck = 'hello_ack';

  // Pairing
  static const String pairingRequest = 'pairing_request';
  static const String pairingPin = 'pairing_pin';
  static const String pairingAccepted = 'pairing_accepted';
  static const String pairingRejected = 'pairing_rejected';

  // Connection
  static const String heartbeat = 'heartbeat';
  static const String heartbeatAck = 'heartbeat_ack';
  static const String disconnect = 'disconnect';

  // SMS
  static const String smsList = 'sms_list';
  static const String smsSend = 'sms_send';
  static const String smsReceived = 'sms_received';

  // Notifications
  static const String notificationPosted = 'notification_posted';
  static const String notificationDismissed = 'notification_dismissed';

  // Clipboard
  static const String clipboardPush = 'clipboard_push';

  // File transfer
  static const String fileOffer = 'file_offer';
  static const String fileAccept = 'file_accept';
  static const String fileReject = 'file_reject';
  static const String fileChunk = 'file_chunk';
  static const String fileDone = 'file_done';
}

class Packet {
  final String type;
  final String from;
  final Map<String, dynamic> payload;
  final int timestamp;

  Packet({
    required this.type,
    required this.from,
    required this.payload,
    int? timestamp,
  }) : timestamp = timestamp ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000;

  factory Packet.fromJson(Map<String, dynamic> json) {
    return Packet(
      type: json['type'] as String,
      from: json['from'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'from': from,
        'payload': payload,
        'timestamp': timestamp,
      };

  String encode() => jsonEncode(toJson());

  static Packet? tryDecode(String raw) {
    try {
      return Packet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
