import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../shared/models/difficulty.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.fontScale,
    required this.lastDifficulty,
  });

  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final double fontScale;
  final Difficulty lastDifficulty;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    double? fontScale,
    Difficulty? lastDifficulty,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      fontScale: fontScale ?? this.fontScale,
      lastDifficulty: lastDifficulty ?? this.lastDifficulty,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() {
    return SettingsState(
      themeMode: _repository.loadThemeMode(),
      soundEnabled: _repository.loadSoundEnabled(),
      vibrationEnabled: _repository.loadVibrationEnabled(),
      fontScale: _repository.loadFontScale(),
      lastDifficulty: _repository.loadLastDifficulty(),
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _repository.saveThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> toggleSound(bool enabled) async {
    await _repository.saveSoundEnabled(enabled);
    state = state.copyWith(soundEnabled: enabled);
    // Stop or start background music based on new setting
    if (enabled) {
      await AudioService.instance.playBackground(enabled: true);
    } else {
      await AudioService.instance.stopBackground();
    }
  }

  Future<void> toggleVibration(bool enabled) async {
    await _repository.saveVibrationEnabled(enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  Future<void> updateFontScale(double scale) async {
    await _repository.saveFontScale(scale);
    state = state.copyWith(fontScale: scale);
  }

  Future<void> updateLastDifficulty(Difficulty difficulty) async {
    await _repository.saveLastDifficulty(difficulty);
    state = state.copyWith(lastDifficulty: difficulty);
  }
}
