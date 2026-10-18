import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui/data/discovered_device.dart';
import 'package:flutter_ui/data/local_device.dart';
import 'package:flutter_ui/data/paired_device.dart';
import 'package:flutter_ui/services/connection_manager.dart';
import 'package:flutter_ui/services/mdns_discovery.dart';
import 'package:flutter_ui/services/pairing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('paired device remembers a new port', () {
    final original = PairedDevice(
      deviceId: 'desk',
      deviceName: 'Desk',
      platform: 'linux',
      lastKnownIp: '192.168.1.20',
      port: 5555,
      pairedAt: 10,
    );

    final moved = original.copyWith(lastKnownIp: '10.0.0.8', port: 5556);

    expect(moved.lastKnownIp, '10.0.0.8');
    expect(moved.port, 5556);
    expect(moved.deviceId, 'desk');
    expect(moved.pairedAt, 10);
  });

  test('resume id is saved, reloaded, and cleared with the desktop', () async {
    final pairing = PairingService();
    await pairing.load();
    await pairing.trustDevice(_desktop(port: 5555));
    await pairing.setResumeDevice('desk-1');

    final reloaded = PairingService();
    await reloaded.load();
    expect(reloaded.resumeDevice?.deviceId, 'desk-1');
    expect(reloaded.resumeDevice?.port, 5555);

    await reloaded.removeDevice('desk-1');
    final afterRemoval = PairingService();
    await afterRemoval.load();
    expect(afterRemoval.resumeDevice, isNull);
  });

  test('a resume id that is not paired is dropped on load', () async {
    SharedPreferences.setMockInitialValues({
      'resume_device_id': 'missing',
      'paired_devices': '[]',
    });

    final pairing = PairingService();
    await pairing.load();
    expect(pairing.resumeDevice, isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('resume_device_id'), isNull);
  });

  testWidgets('trusted desktop reconnects after the socket drops', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(desktop);
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      await harness.networkUp();
      await harness.manager.connectTo(harness.deviceAt(desktop));
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);

      expect(harness.pairing.resumeDevice?.deviceId, 'desk-1');
      expect(harness.pairing.resumeDevice?.port, desktop.port);
      expect(desktop.connections, 1);

      desktop.dropClients();
      await harness.waitUntil(() => desktop.connections >= 2);
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
    });
  });

  testWidgets('Wi-Fi down pauses dialing until the network returns', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(desktop);
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      await harness.networkUp();
      await harness.manager.connectTo(harness.deviceAt(desktop));
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);

      harness.network.add(false);
      await harness.waitUntil(
        () => harness.manager.state == ConnectionState.waitingForNetwork,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(desktop.connections, 1);

      harness.network.add(true);
      await harness.waitUntil(() => desktop.connections >= 2);
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
    });
  });

  testWidgets('opening the app dials the previous desktop', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(desktop);
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      await harness.manager.restoreLastSession();
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
      expect(desktop.connections, 1);
      expect(desktop.types, contains('hello'));
    });
  });

  testWidgets('launch waits for Wi-Fi, then dials the saved desktop', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(desktop, networkUpOnLaunch: false);
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      await harness.manager.restoreLastSession();
      expect(harness.manager.state, ConnectionState.waitingForNetwork);
      expect(desktop.connections, 0);

      harness.network.add(true);
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
      expect(desktop.connections, 1);
    });
  });

  testWidgets('Disconnect forgets the desktop and does not dial again', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(desktop);
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      await harness.networkUp();
      await harness.manager.connectTo(harness.deviceAt(desktop));
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);

      await harness.manager.disconnect();
      expect(harness.manager.state, ConnectionState.disconnected);
      expect(harness.pairing.resumeDevice, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(desktop.connections, 1);
      expect(harness.manager.state, ConnectionState.disconnected);

      final nextLaunch = ConnectionManager(
        harness.config,
        harness.pairing,
        harness.discovery,
        openSocket: harness.openSocket,
        networkEvents: Stream<bool>.empty,
        networkCheck: () async => true,
        discoverWindow: const Duration(milliseconds: 20),
        backoffSteps: const [0],
      );
      addTearDown(nextLaunch.dispose);
      await nextLaunch.restoreLastSession();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(nextLaunch.state, ConnectionState.disconnected);
      expect(desktop.connections, 1);
    });
  });

  testWidgets('a missed heartbeat ack reconnects', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1');
      final harness = await _Harness.open(
        desktop,
        heartbeatAckTimeout: const Duration(milliseconds: 200),
      );
      addTearDown(() async {
        harness.manager.dispose();
        harness.discovery.dispose();
        await harness.network.close();
        await desktop.close();
      });

      desktop.ackHeartbeat = false;
      await harness.networkUp();
      await harness.manager.connectTo(harness.deviceAt(desktop));
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
      await harness.waitUntil(() => harness.manager.state != ConnectionState.connected);
      desktop.ackHeartbeat = true;
      await harness.waitUntil(() => desktop.connections >= 2);
      await harness.waitUntil(() => harness.manager.state == ConnectionState.connected);
    });
  });

  testWidgets('first pair is saved and the next launch skips the PIN', (tester) async {
    await tester.runAsync(() async {
      final desktop = await _DesktopDouble.bind(deviceId: 'desk-1', paired: false);
      final config = LocalDeviceConfigService();
      await config.load();
      final pairing = PairingService();
      await pairing.load();
      final discovery = _ScriptedDiscovery();
      final network = StreamController<bool>();
      final manager = ConnectionManager(
        config,
        pairing,
        discovery,
        openSocket: (host, port) =>
            Socket.connect(host, port, timeout: const Duration(seconds: 2)),
        networkEvents: () => network.stream,
        networkCheck: () async => true,
        discoverWindow: const Duration(milliseconds: 20),
        backoffSteps: const [0],
        heartbeatInterval: const Duration(hours: 1),
        heartbeatAckTimeout: const Duration(seconds: 5),
      );
      addTearDown(() async {
        manager.dispose();
        discovery.dispose();
        await network.close();
        await desktop.close();
      });

      network.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final first = _device(desktop);
      discovery.scripted = first;
      await manager.connectTo(first);
      await _wait(() => manager.state == ConnectionState.connected);
      expect(pairing.isTrusted('desk-1'), isTrue);
      expect(desktop.types, contains('pairing_request'));
      expect(pairing.resumeDevice?.deviceId, 'desk-1');

      await manager.disconnect();
      // Disconnect clears the saved session. Put it back the way a finished
      // pair left it, then open a second manager the way the next launch does.
      await pairing.setResumeDevice('desk-1');

      final relaunch = ConnectionManager(
        config,
        pairing,
        discovery,
        openSocket: (host, port) =>
            Socket.connect(host, port, timeout: const Duration(seconds: 2)),
        networkEvents: () => Stream<bool>.empty(),
        networkCheck: () async => true,
        discoverWindow: const Duration(milliseconds: 20),
        backoffSteps: const [0],
        heartbeatInterval: const Duration(hours: 1),
        heartbeatAckTimeout: const Duration(seconds: 5),
      );
      addTearDown(relaunch.dispose);
      await relaunch.restoreLastSession();
      await _wait(() => relaunch.state == ConnectionState.connected);
      expect(desktop.types.where((type) => type == 'pairing_request').length, 1);
    });
  });
}

PairedDevice _desktop({required int port}) {
  return PairedDevice(
    deviceId: 'desk-1',
    deviceName: 'Desk',
    platform: 'linux',
    lastKnownIp: '127.0.0.1',
    port: port,
  );
}

DiscoveredDevice _device(_DesktopDouble desktop) {
  return DiscoveredDevice(
    instanceName: 'Desk',
    deviceName: 'Desk',
    ipv4: InternetAddress.loopbackIPv4,
    port: desktop.port,
    txt: const {'id': 'desk-1', 'name': 'Desk'},
  );
}

class _ScriptedDiscovery extends MdnsDiscoveryController {
  DiscoveredDevice? scripted;

  @override
  Future<void> start() async {}

  @override
  DiscoveredDevice? findByDeviceId(String deviceId) {
    final device = scripted;
    if (device != null && device.txt['id'] == deviceId) return device;
    return null;
  }
}

class _Harness {
  _Harness({
    required this.config,
    required this.pairing,
    required this.discovery,
    required this.manager,
    required this.network,
    required this.desktop,
  });

  final LocalDeviceConfigService config;
  final PairingService pairing;
  final _ScriptedDiscovery discovery;
  final ConnectionManager manager;
  final StreamController<bool> network;
  final _DesktopDouble desktop;

  Future<Socket> openSocket(String host, int port) {
    return Socket.connect(host, port, timeout: const Duration(seconds: 2));
  }

  DiscoveredDevice deviceAt(_DesktopDouble desktop) => _device(desktop);

  Future<void> networkUp() async {
    network.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  Future<void> waitUntil(bool Function() ready) => _wait(ready);

  static Future<_Harness> open(
    _DesktopDouble desktop, {
    bool networkUpOnLaunch = true,
    Duration heartbeatAckTimeout = const Duration(seconds: 5),
  }) async {
    final config = LocalDeviceConfigService();
    await config.load();
    final pairing = PairingService();
    await pairing.load();
    await pairing.trustDevice(_desktop(port: desktop.port));
    await pairing.setResumeDevice('desk-1');

    final discovery = _ScriptedDiscovery()..scripted = _device(desktop);
    final network = StreamController<bool>();
    final harness = _Harness(
      config: config,
      pairing: pairing,
      discovery: discovery,
      manager: ConnectionManager(
        config,
        pairing,
        discovery,
        openSocket: (host, port) =>
            Socket.connect(host, port, timeout: const Duration(seconds: 2)),
        networkEvents: () => network.stream,
        networkCheck: () async => networkUpOnLaunch,
        discoverWindow: const Duration(milliseconds: 20),
        backoffSteps: const [0],
        heartbeatInterval: const Duration(hours: 1),
        heartbeatAckTimeout: heartbeatAckTimeout,
      ),
      network: network,
      desktop: desktop,
    );
    // The constructor captured openSocket via the closure above. The field
    // exists so later managers in the same test can reuse it.
    return harness;
  }
}

class _DesktopDouble {
  _DesktopDouble({required this.deviceId, required this.paired});

  final String deviceId;
  final bool paired;
  ServerSocket? _server;
  final List<Socket> _clients = [];
  int connections = 0;
  bool ackHeartbeat = true;
  final List<String> types = [];

  int get port => _server!.port;

  static Future<_DesktopDouble> bind({
    required String deviceId,
    bool paired = true,
  }) async {
    final desktop = _DesktopDouble(deviceId: deviceId, paired: paired);
    desktop._server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    desktop._server!.listen(desktop._onClient);
    return desktop;
  }

  void dropClients() {
    for (final client in List<Socket>.from(_clients)) {
      client.destroy();
    }
    _clients.clear();
  }

  Future<void> close() async {
    dropClients();
    await _server?.close();
    _server = null;
  }

  void _onClient(Socket socket) {
    connections += 1;
    _clients.add(socket);
    final buffer = StringBuffer();
    socket.listen((data) {
      buffer.write(utf8.decode(data, allowMalformed: true));
      final raw = buffer.toString();
      final lines = raw.split('\n');
      buffer.clear();
      if (lines.last.isNotEmpty) buffer.write(lines.last);
      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final message = jsonDecode(line) as Map<String, dynamic>;
        final type = message['type'] as String? ?? '';
        types.add(type);
        if (type == 'hello') {
          _send(socket, 'hello_ack', {
            'device_id': deviceId,
            'device_name': 'Desk',
          });
        } else if (type == 'heartbeat' && ackHeartbeat) {
          _send(socket, 'heartbeat_ack', {});
        } else if (type == 'pairing_request' && !paired) {
          final payload = message['payload'] as Map<String, dynamic>? ?? {};
          _send(socket, 'pairing_pin', {'pin': payload['pin'] ?? ''});
        } else if (type == 'pairing_accepted' && !paired) {
          _send(socket, 'pairing_accepted', {
            'device_name': 'Desk',
            'platform': 'linux',
          });
        }
      }
    });
  }

  void _send(Socket socket, String type, Map<String, dynamic> payload) {
    socket.write('${jsonEncode({
      'type': type,
      'from': deviceId,
      'payload': payload,
      'timestamp': 1,
    })}\n');
  }
}

Future<void> _wait(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 4));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 15));
  }
}
