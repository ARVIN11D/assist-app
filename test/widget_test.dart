import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assist/main.dart';

void main() {
  testWidgets('ASSIST app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AssistApp());
    // Verify that the splash screen loads.
    expect(find.text('ASSIST'), findsOneWidget);
  });
}
