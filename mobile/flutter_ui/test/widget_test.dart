import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_ui/app.dart';
import 'package:flutter_ui/data/local_device.dart';
import 'package:flutter_ui/services/pairing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Phone Link app loads', (tester) async {
    final config = LocalDeviceConfigService();
    await config.load();
    final pairing = PairingService();
    await pairing.load();

    await tester.pumpWidget(PhoneLinkApp(
      configService: config,
      pairingService: pairing,
    ));
    await tester.pump();

    expect(find.text('Show available devices'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
  });
}