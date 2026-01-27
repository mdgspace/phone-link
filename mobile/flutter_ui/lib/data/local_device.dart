import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String serviceType = "_phonelink._tcp";
const int defaultPort = 4040;
const int protocolVersion = 1;

class LocalDeviceConfig {
  final String deviceId;
  final String deviceName;
  final String serviceType;
  final int port;
  final int protocolVersion;

  const LocalDeviceConfig({
    required this.deviceId,
    required this.deviceName,
    required this.serviceType,
    required this.port,
    required this.protocolVersion,
  });

  LocalDeviceConfig copyWith({
    String? deviceName,
  }) {
    return LocalDeviceConfig(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      serviceType: serviceType,
      port: port,
      protocolVersion: protocolVersion,
    );
  }
}

class LocalDeviceConfigService {
  static const _keyDeviceId = 'device_id';
  static const _keyDeviceName = 'device_name';

  late LocalDeviceConfig _config;

  LocalDeviceConfig get config => _config;

  /// Must be called once at app startup
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final deviceId = prefs.getString(_keyDeviceId) ?? const Uuid().v4();
    final deviceName = prefs.getString(_keyDeviceName) ?? 'My Phone';

    _config = LocalDeviceConfig(
      deviceId: deviceId,
      deviceName: deviceName,
      serviceType: serviceType,
      port: defaultPort,
      protocolVersion: protocolVersion,
    );

    // Persist defaults if missing
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setString(_keyDeviceName, deviceName);
  }

  /// Only editable field (for now)
  Future<void> updateName(String newName) async {
    _config = _config.copyWith(deviceName: newName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, newName);
  }
}
