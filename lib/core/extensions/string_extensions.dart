/// EduX School Management System
/// String utility extensions
library;

/// Extension methods for String
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Convert camelCase to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// Convert snake_case to camelCase
  String get toCamelCase {
    final parts = split('_');
    if (parts.length == 1) return this;
    return parts.first + parts.skip(1).map((word) => word.capitalize).join();
  }

  /// Get initials from a name (e.g., "John Doe" -> "JD")
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid phone number (Pakistani format)
  bool get isValidPhone {
    // Matches Pakistani phone formats: +92, 0, 03xx, etc.
    return RegExp(
      r'^(\+92|0)?[0-9]{10,11}$',
    ).hasMatch(replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Check if string is a valid CNIC (Pakistani format: XXXXX-XXXXXXX-X)
  bool get isValidCnic {
    return RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$').hasMatch(this) ||
        RegExp(r'^[0-9]{13}$').hasMatch(replaceAll('-', ''));
  }

  /// Format as CNIC (add dashes)
  String get formatAsCnic {
    final clean = replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 13) return this;
    return '${clean.substring(0, 5)}-${clean.substring(5, 12)}-${clean.substring(12)}';
  }

  /// Format as phone number
  String get formatAsPhone {
    final clean = replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.length < 10) return this;
    if (clean.startsWith('+92')) {
      return '+92 ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    if (clean.startsWith('0')) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return this;
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Collapse multiple whitespace into single space
  String get normalizeWhitespace {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Check if string contains only numbers
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Check if string contains only letters
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Check if string contains only letters and numbers
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Parse as integer with fallback
  int toIntOrDefault([int defaultValue = 0]) {
    return int.tryParse(this) ?? defaultValue;
  }

  /// Parse as double with fallback
  double toDoubleOrDefault([double defaultValue = 0.0]) {
    return double.tryParse(this) ?? defaultValue;
  }

  /// Check if string is null or empty (after trim)
  bool get isNullOrEmpty {
    return trim().isEmpty;
  }

  /// Check if string is not null and not empty (after trim)
  bool get isNotNullOrEmpty {
    return trim().isNotEmpty;
  }

  /// Add ordinal suffix to number string (e.g., "1" -> "1st")
  String get ordinal {
    final n = int.tryParse(this);
    if (n == null) return this;
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
}

/// Extension methods for nullable String
extension NullableStringExtensions on String? {
  /// Return value or default if null/empty
  String orDefault([String defaultValue = '']) {
    return (this?.isEmpty ?? true) ? defaultValue : this!;
  }

  /// Return value or null if empty
  String? orNullIfEmpty() {
    return (this?.isEmpty ?? true) ? null : this;
  }

  /// Check if null or empty
  bool get isNullOrEmpty {
    return this?.trim().isEmpty ?? true;
  }

  /// Check if not null and not empty
  bool get isNotNullOrEmpty {
    return this?.trim().isNotEmpty ?? false;
  }
}
