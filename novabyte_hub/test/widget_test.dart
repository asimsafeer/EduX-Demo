// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. For more information, consult the widget testing
// guide: https://docs.flutter.dev/testing/widget-testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novabyte_hub/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NovaBytaHubApp());

    // Just verify the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
