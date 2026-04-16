/// EduX School Management System
/// Number utility extensions
library;

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Extension methods for num
extension NumExtensions on num {
  /// Format as currency with symbol
  String toCurrency({String? symbol}) {
    final currencySymbol = symbol ?? AppConstants.defaultCurrencySymbol;
    final formatter = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  /// Format as currency without symbol
  String toCurrencyValue() {
    final formatter = NumberFormat('#,##0');
    return formatter.format(this);
  }

  /// Format with comma separators
  String toFormatted({int decimalPlaces = 0}) {
    final formatter = NumberFormat.decimalPattern();
    if (decimalPlaces > 0) {
      return toDouble().toStringAsFixed(decimalPlaces);
    }
    return formatter.format(this);
  }

  /// Format as percentage
  String toPercentage({int decimalPlaces = 1}) {
    return '${toDouble().toStringAsFixed(decimalPlaces)}%';
  }

  /// Format as compact number (e.g., 1.2K, 3.5M)
  String toCompact() {
    final formatter = NumberFormat.compact();
    return formatter.format(this);
  }

  /// Clamp value between min and max
  num clampBetween(num min, num max) {
    return this < min ? min : (this > max ? max : this);
  }

  /// Check if number is between min and max (inclusive)
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// Convert to ordinal string (e.g., 1 -> "1st")
  String get ordinal {
    final n = toInt();
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// Pad with zeros to specified length
  String padWithZeros(int length) {
    return toInt().toString().padLeft(length, '0');
  }
}

/// Extension methods for int
extension IntExtensions on int {
  /// Convert to Duration (days)
  Duration get days => Duration(days: this);

  /// Convert to Duration (hours)
  Duration get hours => Duration(hours: this);

  /// Convert to Duration (minutes)
  Duration get minutes => Duration(minutes: this);

  /// Convert to Duration (seconds)
  Duration get seconds => Duration(seconds: this);

  /// Convert to Duration (milliseconds)
  Duration get milliseconds => Duration(milliseconds: this);

  /// Execute function n times
  void times(void Function(int index) action) {
    for (var i = 0; i < this; i++) {
      action(i);
    }
  }

  /// Generate list of n items
  List<T> generate<T>(T Function(int index) generator) {
    return List.generate(this, generator);
  }
}

/// Extension methods for double
extension DoubleExtensions on double {
  /// Round to specified decimal places
  double roundToPlaces(int places) {
    final mod = _pow10(places);
    return (this * mod).round() / mod;
  }

  /// Floor to specified decimal places
  double floorToPlaces(int places) {
    final mod = _pow10(places);
    return (this * mod).floor() / mod;
  }

  /// Ceil to specified decimal places
  double ceilToPlaces(int places) {
    final mod = _pow10(places);
    return (this * mod).ceil() / mod;
  }

  static double _pow10(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

/// Extension methods for nullable num
extension NullableNumExtensions on num? {
  /// Return value or default if null
  num orDefault([num defaultValue = 0]) {
    return this ?? defaultValue;
  }

  /// Format as currency or return default
  String toCurrencyOrDefault({String? symbol, String defaultValue = '-'}) {
    return this?.toCurrency(symbol: symbol) ?? defaultValue;
  }
}
