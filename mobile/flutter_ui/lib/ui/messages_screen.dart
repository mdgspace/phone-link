import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sms_message.dart';
import '../services/sms_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sms = context.read<SmsService>();
      if (!sms.hasPermission) {
        sms.requestPermission().then((granted) {
          if (granted) sms.fetchAllSms();
        });
      } else {
        sms.fetchAllSms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SmsService>().fetchAllSms(),
          ),
        ],
      ),
      body: Consumer<SmsService>(
        builder: (context, sms, _) {
          if (!sms.hasPermission) {
            return _PermissionPrompt(
              onRequest: () => sms.requestPermission().then(
                    (ok) {
                      if (ok) sms.fetchAllSms();
                    },
                  ),
            );
          }

          if (sms.threadList.isEmpty) {
            return const Center(child: Text('No messages'));
          }

          return ListView.separated(
            itemCount: sms.threadList.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, i) {
              final thread = sms.threadList[i];
              return _ThreadTile(thread: thread);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () => _showComposeSheet(context),
      ),
    );
  }

  void _showComposeSheet(BuildContext context) {
    final addressCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Message',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'To', hintText: '+91 xxxxxxxxxx'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.read<SmsService>().sendSms(
                      addressCtrl.text.trim(),
                      bodyCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Send'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final SmsThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _ConversationScreen(thread: thread)),
      ),
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          thread.address.isNotEmpty ? thread.address[0] : '?',
          style: TextStyle(color: Colors.blue.shade800),
        ),
      ),
      title: Text(thread.address),
      subtitle: Text(
        thread.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Text(
        _formatTime(thread.latest.timestamp),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
    );
  }

  String _formatTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _ConversationScreen extends StatefulWidget {
  final SmsThread thread;
  const _ConversationScreen({required this.thread});

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.address)),
      body: Column(
        children: [
          Expanded(
            child: Consumer<SmsService>(
              builder: (context, sms, _) {
                final msgs =
                    sms.threads[widget.thread.address] ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
                );
              },
            ),
          ),
          _ReplyBar(
            ctrl: _ctrl,
            onSend: () {
              context.read<SmsService>().sendSms(
                    widget.thread.address,
                    _ctrl.text.trim(),
                  );
              _ctrl.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final SmsMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          msg.isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: msg.isIncoming
              ? Colors.grey.shade200
              : Colors.blue.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Text(
          msg.body,
          style: TextStyle(
            color: msg.isIncoming ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  const _ReplyBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionPrompt({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.message, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'SMS permission needed',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Grant permission to read and send messages from this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: onRequest, child: const Text('Grant permission')),
          ],
        ),
      ),
    );
  }
}
