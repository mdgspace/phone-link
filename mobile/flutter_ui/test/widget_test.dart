import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ui/app.dart';
import 'package:flutter_ui/data/local_device.dart';

void main() {
  testWidgets('Phone Link app loads', (tester) async {
    final config = LocalDeviceConfigService();
    await config.load();

    await tester.pumpWidget(PhoneLinkApp(configService: config));
    await tester.pump();

    expect(find.text('Show available devices'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
  });
}