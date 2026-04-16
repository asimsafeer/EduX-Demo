import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edux_teacher_app/app.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TeacherApp());

    // Verify that the splash screen is shown
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
