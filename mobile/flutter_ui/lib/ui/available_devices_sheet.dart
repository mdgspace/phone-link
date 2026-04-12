import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/discovered_device.dart';
import '../services/connection_manager.dart';
import '../services/mdns_discovery.dart';

void showAvailableDevicesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return ChangeNotifierProvider(
        create: (_) => MdnsDiscoveryController()..start(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // ── drag handle ──
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Available Devices',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer<MdnsDiscoveryController>(
                      builder: (context, discovery, _) {
                        if (!discovery.isRunning) {
                          return const Center(
                              child: Text('Starting discovery...'));
                        }
                        if (discovery.devices.isEmpty) {
                          return const Center(
                              child: Text('No devices found'));
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: discovery.devices.length,
                          itemBuilder: (context, i) {
                            final device = discovery.devices[i];
                            return _DeviceTile(device: device);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _DeviceTile extends StatelessWidget {
  final DiscoveredDevice device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final connection = context.read<ConnectionManager>();

    return GestureDetector(
      onTap: () {
        connection.connectTo(device);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.computer, color: Colors.grey.shade600),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.deviceName,
                        style: const TextStyle(fontSize: 15)),
                    Text(
                      '${device.ipv4.address} : ${device.port}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
