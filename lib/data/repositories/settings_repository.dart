import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../shared/models/difficulty.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode loadThemeMode() {
    final value = _prefs.getString(StorageKeys.themeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(StorageKeys.themeMode, mode.name);
  }

  bool loadSoundEnabled() {
    return _prefs.getBool(StorageKeys.soundEnabled) ?? true;
  }

  Future<void> saveSoundEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.soundEnabled, enabled);
  }

  bool loadVibrationEnabled() {
    return _prefs.getBool(StorageKeys.vibrationEnabled) ?? true;
  }

  Future<void> saveVibrationEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.vibrationEnabled, enabled);
  }

  double loadFontScale() {
    return _prefs.getDouble(StorageKeys.fontScale) ?? 1.0;
  }

  Future<void> saveFontScale(double scale) async {
    await _prefs.setDouble(StorageKeys.fontScale, scale);
  }

  Difficulty loadLastDifficulty() {
    final value = _prefs.getString(StorageKeys.lastDifficulty);
    if (value == null) return Difficulty.veryEasy;
    return Difficulty.fromName(value);
  }

  Future<void> saveLastDifficulty(Difficulty difficulty) async {
    await _prefs.setString(StorageKeys.lastDifficulty, difficulty.name);
  }
}
