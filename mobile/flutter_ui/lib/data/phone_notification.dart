class PhoneNotification {
  final String key;
  final String appPackage;
  final String appName;
  final String title;
  final String text;
  final int postedAt;

  PhoneNotification({
    required this.key,
    required this.appPackage,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  factory PhoneNotification.fromJson(Map<String, dynamic> json) =>
      PhoneNotification(
        key: json['key'] as String? ?? '',
        appPackage: json['app_package'] as String? ?? '',
        appName: json['app_name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        postedAt: json['posted_at'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'app_package': appPackage,
        'app_name': appName,
        'title': title,
        'text': text,
        'posted_at': postedAt,
      };
}
