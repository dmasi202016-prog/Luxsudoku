import 'package:riverpod/riverpod.dart';

import '../../data/repositories/game_repository.dart';
import '../../data/repositories/hint_repository.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/services/storage_service.dart';
import '../../features/game/domain/puzzle_generator.dart';
import '../../features/game/domain/sudoku_solver.dart';
import '../../features/game/domain/sudoku_validator.dart';
import 'app_providers.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return GameRepository(storage);
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LeaderboardRepository(storage);
});

final puzzleGeneratorProvider = Provider<PuzzleGenerator>((ref) {
  final solver = ref.watch(sudokuSolverProvider);
  return PuzzleGenerator(solver);
});

final sudokuSolverProvider = Provider<SudokuSolver>((ref) {
  return SudokuSolver();
});

final sudokuValidatorProvider = Provider<SudokuValidator>((ref) {
  return SudokuValidator();
});

// Monetization repositories
final hintRepositoryProvider = Provider<HintRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HintRepository(prefs);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PurchaseRepository(prefs);
});
