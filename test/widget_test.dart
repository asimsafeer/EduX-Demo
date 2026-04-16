import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:edux/database/database.dart';
import 'package:edux/main.dart';

void main() {
  setUp(() {
    // Use in-memory database for testing
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setInstance(db);
  });

  tearDown(() {
    AppDatabase.resetInstance();
  });

  testWidgets('App should build and show loading or home screen', (
    WidgetTester tester,
  ) async {
    // Set a large screen size for desktop layout
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EduXApp()));

    // Verify that the app builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump to allow splash screen timer to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
