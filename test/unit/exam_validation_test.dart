import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edux/providers/exam_provider.dart';

// Mock dependencies if needed, but MarksEntryNotifier mainly uses state
void main() {
  group('MarksEntryNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is empty', () {
      final state = container.read(marksEntryProvider);
      expect(state.marks, isEmpty);
      expect(state.validationErrors, isEmpty);
    });

    test('setMarks validates negative marks', () {
      final notifier = container.read(marksEntryProvider.notifier);
      final studentId = 1;
      final maxMarks = 100.0;

      notifier.setMarks(studentId, -5.0, maxMarks);

      final state = container.read(marksEntryProvider);
      expect(state.marks[studentId], -5.0); // It sets the value but adds error
      expect(state.validationErrors[studentId], contains('negative'));
    });

    test('setMarks validates marks exceeding max', () {
      final notifier = container.read(marksEntryProvider.notifier);
      final studentId = 1;
      final maxMarks = 100.0;

      notifier.setMarks(studentId, 105.0, maxMarks);

      final state = container.read(marksEntryProvider);
      expect(state.marks[studentId], 105.0);
      expect(state.validationErrors[studentId], contains('exceed'));
    });

    test('setMarks accepts valid marks', () {
      final notifier = container.read(marksEntryProvider.notifier);
      final studentId = 1;
      final maxMarks = 100.0;

      notifier.setMarks(studentId, 85.0, maxMarks);

      final state = container.read(marksEntryProvider);
      expect(state.marks[studentId], 85.0);
      expect(state.validationErrors[studentId], isNull);
    });

    test('setAbsent clears marks and errors', () {
      final notifier = container.read(marksEntryProvider.notifier);
      final studentId = 1;
      final maxMarks = 100.0;

      // Set invalid marks first
      notifier.setMarks(studentId, 150.0, maxMarks);
      var state = container.read(marksEntryProvider);
      expect(state.validationErrors[studentId], isNotNull);

      // Set absent
      notifier.setAbsent(studentId, true);
      state = container.read(marksEntryProvider);

      expect(state.absent[studentId], isTrue);
      expect(state.marks[studentId], isNull);
      expect(state.validationErrors[studentId], isNull);
    });

    test('setRemarks updates remarks', () {
      final notifier = container.read(marksEntryProvider.notifier);
      final studentId = 1;

      notifier.setRemarks(studentId, 'Good job');

      final state = container.read(marksEntryProvider);
      expect(state.remarks[studentId], 'Good job');
    });
  });
}
