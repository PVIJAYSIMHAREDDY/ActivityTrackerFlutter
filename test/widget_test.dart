import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/screens/login_screen.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('Login and privacy render at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue as guest →'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsNothing);
      await tester.ensureVisible(find.text('Privacy & health information'));
      await tester.tap(find.text('Privacy & health information'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
