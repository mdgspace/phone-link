import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phone_notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationService>().checkListenerActive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<NotificationService>(
        builder: (context, svc, _) {
          if (!svc.listenerActive) {
            return _AccessPrompt(
              onOpen: svc.openNotificationSettings,
            );
          }

          if (svc.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No notifications yet'),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: svc.notifications.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, i) {
              final notif = svc.notifications[i];
              return _NotifTile(
                notif: notif,
                onDismiss: () => svc.dismiss(notif.key),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final PhoneNotification notif;
  final VoidCallback onDismiss;
  const _NotifTile({required this.notif, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.key),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Text(
            notif.appName.isNotEmpty ? notif.appName[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
          ),
        ),
        title: Row(
          children: [
            Text(notif.appName,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              _formatTime(notif.postedAt),
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notif.title.isNotEmpty)
              Text(notif.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            Text(notif.text,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: notif.title.isNotEmpty,
      ),
    );
  }

  String _formatTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    final now = DateTime.now();
    if (dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _AccessPrompt extends StatelessWidget {
  final VoidCallback onOpen;
  const _AccessPrompt({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Notification access needed',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Open system settings and enable notification access for Phone Link.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onOpen,
              child: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}
