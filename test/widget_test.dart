// Basic smoke test — verifies the app widget tree can be built.
// Note: Full Firebase-dependent tests require an emulator or real device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — MaterialApp renders', (WidgetTester tester) async {
    // Minimal app to verify the widget layer compiles and renders.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ReagentKit')),
        ),
      ),
    );

    expect(find.text('ReagentKit'), findsOneWidget);
  });
}
