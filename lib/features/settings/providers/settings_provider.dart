/// Settings providers for app preferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/core/services/data_retention_service.dart';

// Re-export printer provider so existing imports continue working
export 'package:tulasihotels/features/settings/providers/printer_provider.dart';

/// App settings state
class AppSettings {
  final bool isDarkMode;
  final Locale locale;
  final String languageCode;
  final int retentionDays;
  final bool autoCleanupEnabled;

  const AppSettings({
    this.isDarkMode = false,
    this.locale = const Locale('en'),
    this.languageCode = 'en',
    this.retentionDays = 90,
    this.autoCleanupEnabled = true,
  });

  RetentionPeriod get retentionPeriod =>
      RetentionPeriod.fromDays(retentionDays);

  AppSettings copyWith({
    bool? isDarkMode,
    Locale? locale,
    String? languageCode,
    int? retentionDays,
    bool? autoCleanupEnabled,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      locale: locale ?? this.locale,
      languageCode: languageCode ?? this.languageCode,
      retentionDays: retentionDays ?? this.retentionDays,
      autoCleanupEnabled: autoCleanupEnabled ?? this.autoCleanupEnabled,
    );
  }
}

/// Main settings provider - rebuilds on user change
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  // Settings reload is triggered by ref.invalidate() from auth provider
  // after login/logout — NOT by watching authNotifierProvider
  // (watching auth causes a provider rebuild cycle that resets auth state).
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    // Load local cache SYNCHRONOUSLY first to avoid flash of wrong theme
    _loadLocalSync();
    // Then sync from cloud in background
    _loadFromCloud();
  }

  /// Synchronous load from SharedPreferences — instant, no flash
  void _loadLocalSync() {
    try {
      final isDark =
          OfflineStorageService.getSetting<bool>(
            SettingsKeys.isDarkMode,
            defaultValue: false,
          ) ??
          false;

      final langCode =
          OfflineStorageService.getSetting<String>(
            SettingsKeys.language,
            defaultValue: 'en',
          ) ??
          'en';

      final retDays =
          OfflineStorageService.getSetting<int>(
            SettingsKeys.retentionDays,
            defaultValue: 90,
          ) ??
          90;

      final autoCleanup =
          OfflineStorageService.getSetting<bool>(
            SettingsKeys.autoCleanupEnabled,
            defaultValue: true,
          ) ??
          true;

      state = AppSettings(
        isDarkMode: isDark,
        locale: Locale(langCode),
        languageCode: langCode,
        retentionDays: retDays,
        autoCleanupEnabled: autoCleanup,
      );
      debugPrint('✅ Settings loaded instantly from local cache');
    } catch (e) {
      debugPrint('Error loading settings from local cache: $e');
    }
  }

  /// Async cloud fetch — updates if cloud has newer data
  Future<void> _loadFromCloud() async {
    try {
      final cloudData = await OfflineStorageService.loadAllSettingsFromCloud();

      if (cloudData.isNotEmpty) {
        final cloudDark = cloudData[SettingsKeys.isDarkMode] as bool?;
        final cloudLang = cloudData[SettingsKeys.language] as String?;
        final cloudRetention = cloudData[SettingsKeys.retentionDays] as int?;
        final cloudAutoCleanup =
            cloudData[SettingsKeys.autoCleanupEnabled] as bool?;

        if (cloudDark != null || cloudLang != null || cloudRetention != null) {
          final langCode = cloudLang ?? state.languageCode;
          final newState = AppSettings(
            isDarkMode: cloudDark ?? state.isDarkMode,
            locale: Locale(langCode),
            languageCode: langCode,
            retentionDays: cloudRetention ?? state.retentionDays,
            autoCleanupEnabled: cloudAutoCleanup ?? state.autoCleanupEnabled,
          );
          // Only update if different
          if (newState.isDarkMode != state.isDarkMode ||
              newState.languageCode != state.languageCode ||
              newState.retentionDays != state.retentionDays ||
              newState.autoCleanupEnabled != state.autoCleanupEnabled) {
            state = newState;
            debugPrint('✅ Settings updated from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('Cloud settings load failed: $e');
    }
  }

  /// Reload settings (called on user switch)
  Future<void> reloadSettings() async {
    _loadLocalSync();
    await _loadFromCloud();
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    OfflineStorageService.saveSetting(
      SettingsKeys.isDarkMode,
      state.isDarkMode,
    );
  }

  void setDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
    OfflineStorageService.saveSetting(SettingsKeys.isDarkMode, isDark);
  }

  void setLanguage(String languageCode) {
    state = state.copyWith(
      languageCode: languageCode,
      locale: Locale(languageCode),
    );
    OfflineStorageService.saveSetting(SettingsKeys.language, languageCode);
  }

  void setRetentionPeriod(RetentionPeriod period) {
    state = state.copyWith(retentionDays: period.days);
    OfflineStorageService.saveSetting(SettingsKeys.retentionDays, period.days);
  }

  void setRetentionDays(int days) {
    state = state.copyWith(retentionDays: days);
    OfflineStorageService.saveSetting(SettingsKeys.retentionDays, days);
  }

  void setAutoCleanup(bool enabled) {
    state = state.copyWith(autoCleanupEnabled: enabled);
    OfflineStorageService.saveSetting(SettingsKeys.autoCleanupEnabled, enabled);
  }
}

/// Language options
enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी'),
  telugu('te', 'తెలుగు');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Theme mode provider (legacy, use settingsProvider instead)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

/// Language provider (legacy, use settingsProvider instead)
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

/// Settings loading state
final settingsLoadingProvider = StateProvider<bool>((ref) => false);
