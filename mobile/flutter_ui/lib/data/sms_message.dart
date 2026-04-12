class SmsMessage {
  final String id;
  final String address; // phone number
  final String body;
  final bool isIncoming;
  final int timestamp;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.isIncoming,
    required this.timestamp,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) => SmsMessage(
        id: json['id']?.toString() ?? '',
        address: json['address'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isIncoming: (json['is_incoming'] as bool?) ?? true,
        timestamp: json['timestamp'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'body': body,
        'is_incoming': isIncoming,
        'timestamp': timestamp,
      };
}

// Groups messages by contact number into a thread
class SmsThread {
  final String address;
  final List<SmsMessage> messages;

  SmsThread({required this.address, required this.messages});

  SmsMessage get latest => messages.last;
  String get preview => latest.body.length > 60
      ? '${latest.body.substring(0, 60)}...'
      : latest.body;
}
