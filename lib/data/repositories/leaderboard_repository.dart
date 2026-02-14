import '../../core/constants/storage_keys.dart';
import '../../shared/models/difficulty.dart';
import '../models/leaderboard_entry.dart';
import '../services/storage_service.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._storage);

  final StorageService _storage;

  List<LeaderboardEntry> fetch(Difficulty difficulty) {
    final list = _storage.leaderboardBox
            .get(StorageKeys.leaderboardKey(difficulty.name)) ??
        <LeaderboardEntry>[];
    return List<LeaderboardEntry>.from(list)
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
  }

  Future<void> add(
    Difficulty difficulty,
    LeaderboardEntry entry,
  ) async {
    final entries = fetch(difficulty);
    entries.add(entry);
    entries.sort((a, b) => a.seconds.compareTo(b.seconds));
    if (entries.length > 10) {
      entries.removeRange(10, entries.length);
    }
    await _storage.leaderboardBox.put(
      StorageKeys.leaderboardKey(difficulty.name),
      entries,
    );
  }

  Future<void> clear(Difficulty difficulty) async {
    await _storage.leaderboardBox
        .delete(StorageKeys.leaderboardKey(difficulty.name));
  }
}
