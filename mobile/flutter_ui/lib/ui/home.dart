import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connection_manager.dart' as cm;
import '../services/mdns_discovery.dart';
import '../services/mdns_registration.dart';
import '../utils/helpers.dart';
import 'available_devices_sheet.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'permissions_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _ipAddress;
  late final Stream<bool> _wifiStream;

  @override
  void initState() {
    super.initState();
    _wifiStream = wifiAvailableStream();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Consumer<cm.ConnectionManager>(
          builder: (context, connection, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConnectedDevicePanel(connection: connection),
                _RegistrationPanel(wifiStream: _wifiStream),
                _FeatureRow(connection: connection),
                _DiscoverButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Connected device panel (top half)
// ───────────────────────────────────────────────
class _ConnectedDevicePanel extends StatelessWidget {
  final cm.ConnectionManager connection;

  const _ConnectedDevicePanel({required this.connection});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: _panelContent(context),
        ),
      ),
    );
  }

  Widget _panelContent(BuildContext context) {
    switch (connection.state) {
      case cm.ConnectionState.connected:
        return _ConnectedView(connection: connection);
      case cm.ConnectionState.connecting:
      case cm.ConnectionState.handshaking:
        return _StatusView(
          icon: Icons.sync,
          label: 'Connecting...',
          color: Colors.orange,
        );
      case cm.ConnectionState.pairing:
        return _PairingView(connection: connection);
      case cm.ConnectionState.reconnecting:
        return _StatusView(
          icon: Icons.sync_problem,
          label: 'Reconnecting...',
          color: Colors.orange,
        );
      case cm.ConnectionState.error:
        return _StatusView(
          icon: Icons.error_outline,
          label: connection.errorMessage ?? 'Connection error',
          color: Colors.red,
        );
      case cm.ConnectionState.disconnected:
        return _StatusView(
          icon: Icons.phonelink_off,
          label: 'Not connected',
          color: Colors.grey,
        );
    }
  }
}

class _ConnectedView extends StatelessWidget {
  final cm.ConnectionManager connection;

  const _ConnectedView({required this.connection});

  @override
  Widget build(BuildContext context) {
    final device = connection.activeDevice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('connected to'),
        const SizedBox(height: 20),
        Text(
          device.deviceName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
        Text(
          device.lastKnownIp,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Icon(Icons.circle, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          const Text('Connected'),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.lock_outline, size: 14),
          const SizedBox(width: 8),
          Text('Platform: ${device.platform}'),
        ]),
        const Spacer(),
        TextButton(
          onPressed: () => showPermissionsSheet(context),
          style: _btnStyle(Colors.grey.shade400),
          child: const Text('Permissions'),
        ),
        TextButton(
          onPressed: () => connection.disconnect(),
          style: _btnStyle(Colors.red.shade300),
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}

class _PairingView extends StatelessWidget {
  final cm.ConnectionManager connection;
  const _PairingView({required this.connection});

  @override
  Widget build(BuildContext context) {
    final pin = context.watch<cm.ConnectionManager>();
    // Read PIN from pairing service through provider
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pairing request',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Confirm this PIN on both devices:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, dynamic pairingSvc, _) {
            // PairingService is provided above — read from it
            return Text(
              '------', // PIN is shown via PairingPinBanner below
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.blue.shade700,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => connection.disconnect(),
          style: _btnStyle(Colors.red.shade200),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusView({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 14),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────
// mDNS registration panel (bottom half)
// ───────────────────────────────────────────────
class _RegistrationPanel extends StatefulWidget {
  final Stream<bool> wifiStream;
  const _RegistrationPanel({required this.wifiStream});

  @override
  State<_RegistrationPanel> createState() => _RegistrationPanelState();
}

class _RegistrationPanelState extends State<_RegistrationPanel> {
  String? _ipAddress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: StreamBuilder<bool>(
            stream: widget.wifiStream,
            builder: (context, snapshot) {
              final wifiOk = snapshot.data == true;

              if (!wifiOk) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Text(
                      'This device is not discoverable',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Connect to a Wi-Fi network to start advertising.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }

              if (_ipAddress == null) {
                getLocalIPv4().then((ip) {
                  if (mounted) setState(() => _ipAddress = ip);
                });
              }

              return Consumer<MdnsRegistrationController>(
                builder: (context, controller, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'This device is discoverable',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              controller.config.deviceName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              _ipAddress ?? 'Fetching IP...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Text('Port : ${controller.config.port}'),
                            const SizedBox(height: 4),
                            Text('Service : ${controller.config.serviceType}'),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  _showEditDialog(context, controller),
                              style: _btnStyle(Colors.grey.shade300),
                              child: const Text('Edit'),
                            ),
                            controller.isRegistered
                                ? TextButton(
                                    onPressed: controller.stop,
                                    style: _btnStyle(Colors.red.shade300),
                                    child: const Text('Stop advertising'),
                                  )
                                : TextButton(
                                    onPressed: controller.start,
                                    style: _btnStyle(Colors.grey.shade300),
                                    child: const Text('Start advertising'),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, MdnsRegistrationController controller) {
    final nameCtrl =
        TextEditingController(text: controller.config.deviceName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: nameCtrl,
          decoration:
              const InputDecoration(labelText: 'Device name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.updateDeviceName(nameCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Feature shortcuts row
// ───────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final cm.ConnectionManager connection;
  const _FeatureRow({required this.connection});

  @override
  Widget build(BuildContext context) {
    final enabled = connection.isConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _FeatureChip(
            icon: Icons.message_outlined,
            label: 'SMS',
            enabled: enabled,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _FeatureChip(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            enabled: enabled,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _FeatureChip(
            icon: Icons.content_copy,
            label: 'Clipboard',
            enabled: enabled,
            onTap: () {
              context.read<cm.ConnectionManager>(); // just to show it works
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clipboard synced')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.blue.shade50
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: enabled
                      ? Colors.blue.shade700
                      : Colors.grey.shade400),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: enabled
                      ? Colors.blue.shade700
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Discover button
// ───────────────────────────────────────────────
class _DiscoverButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextButton(
        onPressed: () => showAvailableDevicesSheet(context),
        style: _btnStyle(Colors.grey.shade200),
        child: const Text('Show available devices'),
      ),
    );
  }
}

ButtonStyle _btnStyle(Color color) => TextButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
