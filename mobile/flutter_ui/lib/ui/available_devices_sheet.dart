import 'package:flutter/material.dart';
import 'package:flutter_ui/services/mdns_discovery.dart';
import 'package:provider/provider.dart';

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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // ───── drag handle ─────
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

                  // ───── title ─────
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Available Devices",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  SizedBox(height: 3),

                  // ───── scrollable content ─────
                  Expanded(
                    child: Consumer<MdnsDiscoveryController>(
                      builder: (context, controller, _) {
                        final services = controller.services;

                        if (!controller.isRunning) {
                          return const Center(
                            child: Text("Starting discovery..."),
                          );
                        }

                        if (services.isEmpty) {
                          return const Center(
                            child: Text("No devices found"),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: services.length, // mock devices for now
                          itemBuilder: (context, index) {
                            final service = services[index];

                            return deviceContainer(
                              name: service.name ?? 'Unknown device',
                              id: service.host ?? 'Unknown host',
                              connType: 'tcp:${service.port ?? 0}',
                              connected: false,
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
        ),
      );
    },
  );
}

Widget deviceContainer({
  required String name,
  required String id,
  required String connType,
  required bool connected,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Device ID : $id",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        "Connection Type : $connType",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                connected
                    ? Icon(Icons.circle, color: Colors.grey.shade300)
                    : Icon(Icons.circle_outlined, color: Colors.grey.shade300)
              ],
            )
          ],
        ),
      ),
    ),
  );
}
