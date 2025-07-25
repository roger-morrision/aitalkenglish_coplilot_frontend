import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aitalk_copilot/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    // Verify that the app starts up properly
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
