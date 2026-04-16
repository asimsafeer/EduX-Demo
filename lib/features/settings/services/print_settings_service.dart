import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Print settings keys
class PrintSettingsKeys {
  static const String paperSize =
      'print_paper_size'; // 'a4', 'a5', 'letter', 'legal', 'b5', 'thermal_80', 'thermal_58'
  static const String showHeader = 'print_show_header';
  static const String showFooter = 'print_show_footer';
  static const String footerText = 'print_footer_text';
}

/// Print settings model
class PrintSettings {
  final String paperSize;
  final bool showHeader;
  final bool showFooter;
  final String footerText;

  const PrintSettings({
    this.paperSize = 'a4',
    this.showHeader = true,
    this.showFooter = true,
    this.footerText = 'Thank you for your business!',
  });

  PrintSettings copyWith({
    String? paperSize,
    bool? showHeader,
    bool? showFooter,
    String? footerText,
  }) {
    return PrintSettings(
      paperSize: paperSize ?? this.paperSize,
      showHeader: showHeader ?? this.showHeader,
      showFooter: showFooter ?? this.showFooter,
      footerText: footerText ?? this.footerText,
    );
  }
}

/// Print settings service
class PrintSettingsService {
  final SharedPreferences _prefs;

  PrintSettingsService(this._prefs);

  PrintSettings getSettings() {
    return PrintSettings(
      paperSize: _prefs.getString(PrintSettingsKeys.paperSize) ?? 'a4',
      showHeader: _prefs.getBool(PrintSettingsKeys.showHeader) ?? true,
      showFooter: _prefs.getBool(PrintSettingsKeys.showFooter) ?? true,
      footerText:
          _prefs.getString(PrintSettingsKeys.footerText) ??
          'Thank you for your business!',
    );
  }

  Future<void> saveSettings(PrintSettings settings) async {
    await _prefs.setString(PrintSettingsKeys.paperSize, settings.paperSize);
    await _prefs.setBool(PrintSettingsKeys.showHeader, settings.showHeader);
    await _prefs.setBool(PrintSettingsKeys.showFooter, settings.showFooter);
    await _prefs.setString(PrintSettingsKeys.footerText, settings.footerText);
  }
}

/// Shared preferences provider (needs to be initialized in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

/// Print settings service provider
final printSettingsServiceProvider = Provider<PrintSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrintSettingsService(prefs);
});

/// Print settings state provider
final printSettingsProvider =
    StateNotifierProvider<PrintSettingsNotifier, PrintSettings>((ref) {
      final service = ref.watch(printSettingsServiceProvider);
      return PrintSettingsNotifier(service);
    });

class PrintSettingsNotifier extends StateNotifier<PrintSettings> {
  final PrintSettingsService _service;

  PrintSettingsNotifier(this._service) : super(_service.getSettings());

  Future<void> updateSettings(PrintSettings settings) async {
    await _service.saveSettings(settings);
    state = settings;
  }

  Future<void> setPaperSize(String size) async {
    final newSettings = state.copyWith(paperSize: size);
    await updateSettings(newSettings);
  }

  Future<void> updateFooterText(String text) async {
    final newSettings = state.copyWith(footerText: text);
    await updateSettings(newSettings);
  }
}
