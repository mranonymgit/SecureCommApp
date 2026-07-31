import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_theme_option.dart';
import '../../domain/entities/user_preferences.dart';

class AparienciaController extends ValueNotifier<AppThemeMode> {
  AparienciaController([SettingsRepositoryImpl? repository, AppThemeMode initialMode = AppThemeMode.light])
      : _repository = repository ?? SettingsRepositoryImpl(),
        super(initialMode);

  final SettingsRepositoryImpl _repository;
  UserPreferences? preferences;

  Future<void> loadSavedTheme() async {
    try {
      preferences = await _repository.getPreferences();
      final theme = preferences?.themeMode;
      if (theme != null) {
        value = _themeFromString(theme);
      }
    } catch (_) {
      // Si falla, mantenemos el tema actual.
    }
  }

  Future<void> changeTheme(AppThemeMode mode) async {
    value = mode;
    preferences = await _repository.updatePreferences(
      (preferences ?? const UserPreferences(themeMode: 'default', notificationsEnabled: true, language: 'es'))
          .copyWith(themeMode: mode.name),
    );
  }

  AppThemeMode _themeFromString(String value) {
    switch (value) {
      case 'deuteranopia':
        return AppThemeMode.deuteranopia;
      case 'protanopia':
        return AppThemeMode.protanopia;
      case 'tritanopia':
        return AppThemeMode.tritanopia;
      case 'dark':
      case 'default':
      default:
        return AppThemeMode.dark;
    }
  }
}
