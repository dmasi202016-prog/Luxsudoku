import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../shared/models/difficulty.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';

class SavedGameSummary {
  const SavedGameSummary({
    required this.slot,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.updatedAt,
  });

  final int slot;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final DateTime updatedAt;
}

class GameRepository {
  GameRepository(this._storage);

  final StorageService _storage;

  Future<void> saveGame(int slot, GameState state) async {
    await _storage.savedGamesBox.put(
      StorageKeys.savedGameKey(slot),
      state,
    );
  }

  GameState? loadGame(int slot) {
    return _storage.savedGamesBox.get(StorageKeys.savedGameKey(slot));
  }

  Future<void> autoSave(GameState state) async {
    await _storage.savedGamesBox.put(StorageKeys.autoSaveKey, state);
  }

  GameState? loadAutoSave() {
    return _storage.savedGamesBox.get(StorageKeys.autoSaveKey);
  }

  Future<void> deleteGame(int slot) async {
    await _storage.savedGamesBox.delete(StorageKeys.savedGameKey(slot));
  }

  List<SavedGameSummary> listSavedGames() {
    final summaries = <SavedGameSummary>[];
    for (var slot = 1; slot <= AppConstants.maxSaveSlots; slot++) {
      final state = loadGame(slot);
      if (state == null) continue;
      summaries.add(
        SavedGameSummary(
          slot: slot,
          difficulty: state.difficulty,
          elapsedSeconds: state.elapsedSeconds,
          updatedAt: state.startedAt ?? DateTime.now(),
        ),
      );
    }
    return summaries;
  }

  Future<void> clearAll() async {
    await _storage.savedGamesBox.clear();
  }
}
