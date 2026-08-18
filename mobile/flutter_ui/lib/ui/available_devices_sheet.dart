import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/discovered_device.dart';
import '../services/connection_manager.dart';
import '../services/mdns_discovery.dart';

void showAvailableDevicesSheet(BuildContext context) {
  // Capture the actual app-wide ConnectionManager BEFORE creating the
  // modal route. We then explicitly inject that exact instance into the
  // sheet, so the sheet/tile cannot accidentally resolve a different
  // provider scope.
  final connection = Provider.of<ConnectionManager>(
    context,
    listen: false,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connection),
          ChangeNotifierProvider(
            create: (_) => MdnsDiscoveryController()..start(),
          ),
        ],
        child: const _AvailableDevicesSheet(),
      );
    },
  );
}

class _AvailableDevicesSheet extends StatelessWidget {
  const _AvailableDevicesSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer<MdnsDiscoveryController>(
                  builder: (context, discovery, _) {
                    if (discovery.errorMessage != null) {
                      return _DiscoveryError(
                        message: discovery.errorMessage!,
                        retrying: discovery.isStarting,
                        onRetry: discovery.start,
                      );
                    }

                    if (discovery.isStarting && discovery.devices.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (discovery.devices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.devices_other, size: 36),
                            const SizedBox(height: 10),
                            const Text('No devices found'),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: discovery.start,
                              child: const Text('Scan again'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: discovery.devices.length,
                      itemBuilder: (context, i) {
                        return _DeviceTile(
                          device: discovery.devices[i],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  const _DiscoveryError({
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Device discovery failed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: retrying ? null : onRetry,
              child: Text(retrying ? 'Retrying...' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DiscoveredDevice device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    // This provider is explicitly installed on the sheet route by
    // showAvailableDevicesSheet(), so this lookup is guaranteed to resolve.
    final connection = context.read<ConnectionManager>();

    return GestureDetector(
      onTap: () async {
        await connection.connectTo(device);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.computer, color: Colors.grey.shade600),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      '${device.ipv4.address} : ${device.port}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
