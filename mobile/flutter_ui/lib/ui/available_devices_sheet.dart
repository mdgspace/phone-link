import 'package:flutter/material.dart';
import 'package:flutter_ui/data/discovered_device.dart';
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
                        final services = controller.devices;

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
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];

                            return deviceContainer(
                              device: service,
                              controller: controller,
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
  required DiscoveredDevice device,
  required MdnsDiscoveryController controller,
}) {
  return GestureDetector(
    onTap: () {
      if (device.connected) {
        controller.disconnectFromDevice(device);
      } else {
        controller.connectToDevice(device);
      }
    },
    child: Padding(
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
                          device.deviceName,
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Device ID : ${device.instanceName}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "IPv4 Address : ${device.ipv4.toString()}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "Port : ${device.port}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  device.connected
                      ? Icon(Icons.circle, color: Colors.grey.shade300)
                      : Icon(Icons.circle_outlined, color: Colors.grey.shade300)
                ],
              )
            ],
          ),
        ),
      ),
    ),
  );
}
