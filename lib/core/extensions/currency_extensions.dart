/// EduX School Management System
/// Currency formatting extensions and utilities
library;

import 'package:intl/intl.dart';

/// Centralized currency formatting for the application
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Default currency formatter for Pakistani Rupees
  static final NumberFormat _defaultFormatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  /// Compact currency formatter for charts and summaries
  static final NumberFormat _compactFormatter = NumberFormat.compact();

  /// Format an amount as currency
  static String format(double amount, {bool compact = false}) {
    if (compact) {
      return _compactFormatter.format(amount);
    }
    return _defaultFormatter.format(amount);
  }

  /// Format an amount with custom symbol and locale
  static String formatCustom(
    double amount, {
    String locale = 'en_PK',
    String symbol = 'Rs. ',
    int decimalDigits = 0,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }
}

/// Extension on double for currency formatting
extension CurrencyDoubleExtension on double {
  /// Format as currency string
  String toCurrency({bool compact = false}) {
    return CurrencyFormatter.format(this, compact: compact);
  }

  /// Format as compact currency (for charts)
  String toCompactCurrency() {
    return CurrencyFormatter.format(this, compact: true);
  }
}

/// Extension on int for currency formatting
extension CurrencyIntExtension on int {
  /// Format as currency string
  String toCurrency({bool compact = false}) {
    return CurrencyFormatter.format(toDouble(), compact: compact);
  }

  /// Format as compact currency (for charts)
  String toCompactCurrency() {
    return CurrencyFormatter.format(toDouble(), compact: true);
  }
}

/// Extension on num for currency formatting
extension CurrencyNumExtension on num {
  /// Format as currency string
  String toCurrency({bool compact = false}) {
    return CurrencyFormatter.format(toDouble(), compact: compact);
  }

  /// Format as compact currency (for charts)
  String toCompactCurrency() {
    return CurrencyFormatter.format(toDouble(), compact: true);
  }
}
