import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/leaderboard_entry.dart';

class StorageService {
  StorageService._(this.preferences);

  final SharedPreferences preferences;
  late Box<GameState> savedGamesBox;
  late Box<List<LeaderboardEntry>> leaderboardBox;

  static Future<StorageService> init(SharedPreferences preferences) async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GameStateAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GameActionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LeaderboardEntryAdapter());
    }

    final service = StorageService._(preferences);
    service.savedGamesBox =
        await Hive.openBox<GameState>(StorageKeys.savedGamesBox);
    service.leaderboardBox =
        await Hive.openBox<List<LeaderboardEntry>>(StorageKeys.leaderboardBox);
    return service;
  }

  Future<void> dispose() async {
    await Hive.close();
  }
}
