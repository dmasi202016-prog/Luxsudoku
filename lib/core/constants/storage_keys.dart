class StorageKeys {
  StorageKeys._();

  static const String themeMode = 'themeMode';
  static const String soundEnabled = 'soundEnabled';
  static const String vibrationEnabled = 'vibrationEnabled';
  static const String fontScale = 'fontScale';
  static const String lastDifficulty = 'lastDifficulty';
  static const String leaderboardBox = 'leaderboard_box';
  static const String savedGamesBox = 'saved_games_box';
  static const String autoSaveKey = 'autosave_game';

  static String leaderboardKey(String difficultyName) =>
      'leaderboard_$difficultyName';

  static String savedGameKey(int slot) => 'saved_game_$slot';
}
