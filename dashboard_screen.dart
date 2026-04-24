import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/nsd_service.dart';
import '../services/settings_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions and initialize listening when the UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkService>();
    final nsd = context.watch<NsdService>();
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone-Link Dashboard'),
        actions: [
          Row(
            children: [
              const Text('Service Enabled'),
              Switch(
                value: settings.isServiceEnabled,
                onChanged: (val) => settings.toggleService(val),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connection Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              leading: Icon(
                network.isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: network.isConnected ? Colors.green : Colors.red,
              ),
              title: Text(network.isConnected ? 'Connected to Desktop' : 'Disconnected'),
              trailing: network.isConnected
                  ? TextButton(onPressed: () => network.disconnect(), child: const Text('Disconnect'))
                  : null,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discovered Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: nsd.isDiscovering ? () => nsd.stopScanning() : () => nsd.startScanning(),
                  child: Text(nsd.isDiscovering ? 'Stop Scanning' : 'Scan for Desktop'),
                ),
              ],
            ),
            Expanded(
              child: nsd.discoveredServices.isEmpty
                  ? const Center(child: Text('No devices found on the local network.'))
                  : ListView.builder(
                      itemCount: nsd.discoveredServices.length,
                      itemBuilder: (context, index) {
                        final service = nsd.discoveredServices[index];
                        return ListTile(
                          title: Text(service.name ?? 'Unknown Device'),
                          subtitle: Text('${service.host ?? 'Unknown IP'}:${service.port}'),
                          trailing: ElevatedButton(
                            onPressed: network.isConnected ? null : () => network.connect(service.host!, service.port!),
                            child: const Text('Connect'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}