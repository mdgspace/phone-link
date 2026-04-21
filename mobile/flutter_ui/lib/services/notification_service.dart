import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'network_service.dart';

class NotificationService extends ChangeNotifier {
  final NetworkService networkService;

  NotificationService({required this.networkService});

  StreamSubscription<ServiceNotificationEvent>? _subscription;
  final List<ServiceNotificationEvent> _notifications = [];

  List<ServiceNotificationEvent> get notifications => _notifications;

  /// Initializes the service by requesting permissions and subscribing to the stream.
  Future<void> init() async {
    bool isAllowed = await NotificationListenerService.isPermissionGranted();
    if (!isAllowed) {
      debugPrint('Notification permission not granted, requesting...');
      isAllowed = await NotificationListenerService.requestPermission();
    }

    if (isAllowed) {
      debugPrint('Notification permission granted. Listening to stream...');
      _subscription = NotificationListenerService.notificationsStream.listen((event) {
        debugPrint('New Notification: ${event.title} - ${event.content}');
        _notifications.add(event);
        notifyListeners();
        
        // Forward the notification event to the Qt desktop app via local network socket.
        if (networkService.isConnected) {
          networkService.sendNotificationPayload({
            'package': event.packageName,
            'title': event.title,
            'content': event.content,
          });
        }
      });
    } else {
      debugPrint('Notification permission was denied by the user.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}