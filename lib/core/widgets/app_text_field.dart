/// EduX School Management System
/// Custom text field widget
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// A customized text field with consistent styling
class AppTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController? controller;

  /// Label text
  final String? label;

  /// Hint text
  final String? hint;

  /// Helper text
  final String? helperText;

  /// Error text
  final String? errorText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon callback
  final VoidCallback? onSuffixTap;

  /// Custom suffix widget
  final Widget? suffix;

  /// Custom prefix widget
  final Widget? prefix;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is obscured (password)
  final bool obscureText;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is read-only
  final bool readOnly;

  /// Max lines
  final int? maxLines;

  /// Min lines
  final int? minLines;

  /// Max length
  final int? maxLength;

  /// On changed callback
  final ValueChanged<String>? onChanged;

  /// On submitted callback
  final ValueChanged<String>? onSubmitted;

  /// On tap callback
  final VoidCallback? onTap;

  /// Validator function
  final String? Function(String?)? validator;

  /// Focus node
  final FocusNode? focusNode;

  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Whether to autofocus
  final bool autofocus;

  /// Initial value (only works without controller)
  final String? initialValue;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.suffix,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofocus = false,
    this.initialValue,
  });

  /// Text field for email input
  factory AppTextField.email({
    Key? key,
    TextEditingController? controller,
    String? label = 'Email',
    String? hint = 'Enter email address',
    String? errorText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator ?? _defaultEmailValidator,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.next,
    );
  }

  /// Text field for phone input
  factory AppTextField.phone({
    Key? key,
    TextEditingController? controller,
    String? label = 'Phone Number',
    String? hint = '03XX-XXXXXXX',
    String? errorText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9-+]')),
        LengthLimitingTextInputFormatter(13),
      ],
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
    );
  }

  /// Text field for CNIC input
  factory AppTextField.cnic({
    Key? key,
    TextEditingController? controller,
    String? label = 'CNIC',
    String? hint = 'XXXXX-XXXXXXX-X',
    String? errorText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      prefixIcon: Icons.badge_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
        LengthLimitingTextInputFormatter(15),
        _CnicFormatter(),
      ],
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
    );
  }

  /// Text field for search input
  factory AppTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint = 'Search...',
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true ? Icons.close : null,
      onSuffixTap: onClear ?? () => controller?.clear(),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
    );
  }

  /// Multiline text field for notes/description
  factory AppTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint = 'Enter description...',
    String? errorText,
    bool enabled = true,
    int maxLines = 4,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  static String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autofocus: autofocus,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon:
            prefix ??
            (prefixIcon != null
                ? (maxLines != null && maxLines! > 1
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Icon(prefixIcon),
                          ],
                        )
                      : Icon(prefixIcon))
                : null),
        suffixIcon:
            suffix ??
            (suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Icon(suffixIcon),
                      onPressed: onSuffixTap,
                      splashRadius: 20,
                    ),
                  )
                : null),
      ),
    );
  }
}

/// CNIC input formatter
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 13; i++) {
      if (i == 5 || i == 12) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
