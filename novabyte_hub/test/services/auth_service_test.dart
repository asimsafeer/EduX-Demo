/// Unit tests for AuthException model
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/services/auth_service.dart';

void main() {
  group('AuthException', () {
    test('stores message', () {
      const exception = AuthException('Test error message');
      expect(exception.message, equals('Test error message'));
    });

    test('toString returns message', () {
      const exception = AuthException('Connection failed');
      expect(exception.toString(), equals('Connection failed'));
    });

    test('implements Exception', () {
      const exception = AuthException('test');
      expect(exception, isA<Exception>());
    });

    test('empty message is allowed', () {
      const exception = AuthException('');
      expect(exception.message, isEmpty);
    });

    test('long message is preserved', () {
      final longMsg = 'A' * 1000;
      final exception = AuthException(longMsg);
      expect(exception.message, equals(longMsg));
      expect(exception.message.length, equals(1000));
    });

    test('special characters in message', () {
      const exception = AuthException('Error: <html>&amp;"quotes"');
      expect(exception.message, contains('<html>'));
    });
  });
}
