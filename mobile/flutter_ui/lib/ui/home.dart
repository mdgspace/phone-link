import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui/services/mdns_registration.dart';
import 'package:flutter_ui/utils/helpers.dart';
import 'package:provider/provider.dart';

import 'available_devices_sheet.dart';
import 'permissions_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String deviceName = "OnePlus 13 Pro Plus";
  String deviceId = "Address or some form of ID";
  String port = "5000";
  String service = "_phonelink._tcp";

  String? _ipAddress;
  late final Stream<bool> _wifiAvailableStream;

  @override
  void initState() {
    super.initState();
    _wifiAvailableStream = wifiAvailableStream();
  }

  void func() async {
    final result = await Connectivity().checkConnectivity();
    print("Connectivity result: $result");

    final interfaces = await NetworkInterface.list();
    for (final i in interfaces) {
      print("Interface: ${i.name}, addresses: ${i.addresses}");
    }
  }

  void refreshIp() {
    // setState(() async {
    //   _ipFuture = await getLocalIPv4();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ───────── Connected Device ─────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("connected to"),
                      const SizedBox(height: 25),
                      const Text(
                        "Ava's Lenovo Laptop",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24),
                      ),
                      const Text(
                        "Address or some form of ID",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.green, size: 18),
                          SizedBox(width: 10),
                          Text("Connection status"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.lock, size: 18),
                          SizedBox(width: 10),
                          Text("Encrypted TLS"),
                        ],
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () {
                          showPermissionsSheet(context);
                        },
                        style: _buttonStyle(Colors.grey.shade400),
                        child: const Text("Permissions"),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: _buttonStyle(Colors.red.shade300),
                        child: const Text("Disconnect"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ───────── mDNS Registration ─────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: StreamBuilder<bool>(
                    stream: _wifiAvailableStream,
                    builder: (context, snapshot) {
                      final wifiOk = snapshot.data == true;
                      if (!wifiOk) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "This device is not discoverable",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            const Text(
                              "Make sure you are connected to a Wi-Fi network for registration to start.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }

                      if (wifiOk && _ipAddress == null) {
                        getLocalIPv4().then((ip) {
                          setState(() {
                            _ipAddress = ip;
                          });
                        });
                      }

                      return Consumer<MdnsRegistrationController>(
                        builder: (context, controller, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "This device is discoverable",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      controller.config.deviceName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      _ipAddress ?? "Cannot get IP",
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 25),
                                    Text("Port : ${controller.config.port}"),
                                    const SizedBox(height: 8),
                                    Text(
                                        "Service : ${controller.config.serviceType}"),
                                    const SizedBox(height: 25),
                                    TextButton(
                                      onPressed: () {
                                        showEditMdnsDialog(context, controller);
                                      },
                                      style: _buttonStyle(Colors.grey.shade300),
                                      child: const Text("Edit"),
                                    ),
                                    controller.isRegistered
                                        ? TextButton(
                                            onPressed: () {
                                              controller.stop();
                                            },
                                            style: _buttonStyle(
                                                Colors.red.shade300),
                                            child:
                                                const Text("Stop registration"),
                                          )
                                        : TextButton(
                                            onPressed: () {
                                              controller.start();
                                            },
                                            style: _buttonStyle(
                                                Colors.grey.shade300),
                                            child: const Text(
                                                "Start registration"),
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
            ),

            // ───────── Discover Devices Button ─────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              child: TextButton(
                onPressed: () {
                  showAvailableDevicesSheet(context);
                },
                style: _buttonStyle(Colors.grey.shade200),
                child: const Text("Show available devices"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showEditMdnsDialog(
    BuildContext context,
    MdnsRegistrationController controller,
  ) {
    final nameController =
        TextEditingController(text: controller.config.deviceName);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ───── Header ─────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          "Edit Device Info",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ───── Content ─────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: "Device Name",
                              helperText:
                                  "This name is shown to other devices on the network",
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Optional: show port as read-only info
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Port: ${controller.config.port}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ───── Actions ─────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            controller
                                .updateDeviceName(nameController.text.trim());
                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Shared button style helper
  ButtonStyle _buttonStyle(Color color) {
    return TextButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
