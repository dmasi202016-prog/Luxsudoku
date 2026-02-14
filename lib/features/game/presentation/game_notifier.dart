import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/monetization_constants.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../data/models/game_action.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../shared/models/difficulty.dart';
import '../../settings/presentation/settings_notifier.dart';
import '../domain/cell_coordinate.dart';
import '../domain/puzzle_generator.dart';
import '../domain/sudoku_validator.dart';

final gameNotifierProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  final gameRepository = ref.watch(gameRepositoryProvider);
  final leaderboardRepository = ref.watch(leaderboardRepositoryProvider);
  final generator = ref.watch(puzzleGeneratorProvider);
  final validator = ref.watch(sudokuValidatorProvider);

  return GameNotifier(
    ref,
    gameRepository,
    leaderboardRepository,
    generator,
    validator,
  );
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(
    this.ref,
    this._gameRepository,
    this._leaderboardRepository,
    this._generator,
    this._validator,
  ) : super(GameState.initial(Difficulty.veryEasy));

  final Ref ref;
  final GameRepository _gameRepository;
  final LeaderboardRepository _leaderboardRepository;
  final PuzzleGenerator _generator;
  final SudokuValidator _validator;
  Timer? _timer;

  Future<void> startNewGame(Difficulty difficulty) async {
    final generated = _generator.generate(difficulty);
    final fixedCells = _buildFixedCells(generated.puzzle);
    _timer?.cancel();

    final notes = List.generate(
      AppConstants.boardSize,
      (_) => List.generate(AppConstants.boardSize, (_) => <int>{}),
    );

    state = GameState(
      board: generated.puzzle,
      solution: generated.solution,
      fixedCells: fixedCells,
      notes: notes,
      difficulty: difficulty,
      hintsUsed: 0,
      elapsedSeconds: 0,
      isPaused: false,
      isCompleted: false,
      actionHistory: const [],
      redoStack: const [],
      selectedRow: null,
      selectedCol: null,
      startedAt: DateTime.now(),
      conflicts: const {},
    );

    ref
        .read(settingsNotifierProvider.notifier)
        .updateLastDifficulty(difficulty);
    _startTimer();
    _persistAutoSave();

    // Ensure at least default hints for new game (preserve bonus hints from ads/purchases)
    final isPremium = ref.read(premiumStatusProvider).isPremium;
    if (!isPremium) {
      final currentBalance = ref.read(hintBalanceProvider);
      if (currentBalance.currentHints < MonetizationConstants.defaultHintsPerGame) {
        await ref.read(hintBalanceProvider.notifier).resetToDefault();
      }
    }

    // Restart background music (stop finish sound if playing)
    final soundEnabled = ref.read(settingsNotifierProvider).soundEnabled;
    if (soundEnabled) {
      unawaited(AudioService.instance.stopFinishSound());
      unawaited(AudioService.instance.playBackground(enabled: true));
    }
  }

  void selectCell(int row, int col) {
    // Allow selecting fixed cells for highlighting same numbers
    final vibrationEnabled =
        ref.read(settingsNotifierProvider).vibrationEnabled;
    unawaited(PlatformUtils.vibrateLight(enabled: vibrationEnabled));

    state = state.copyWith(
      selectedRow: row,
      selectedCol: col,
    );
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  void enterNumber(int value) {
    if (!state.hasSelection || state.isCompleted || state.isPaused) return;
    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.fixedCells[row][col]) return;

    // If in note mode, toggle note instead
    if (state.isNoteMode && value != 0) {
      toggleNote(value);
      return;
    }

    final previousValue = state.board[row][col];
    if (previousValue == value) return;

    final newBoard = _cloneBoard(state.board);
    newBoard[row][col] = value;

    // Clear notes for this cell when entering a number
    final newNotes = _cloneNotes(state.notes);
    if (value != 0) {
      newNotes[row][col].clear();
    }

    // Always recalculate all conflicts to avoid accumulation
    final conflicts = _recalculateConflicts(newBoard);

    final history = _appendAction(
      state.actionHistory,
      GameAction(
        row: row,
        col: col,
        previousValue: previousValue,
        newValue: value,
      ),
    );

    state = state.copyWith(
      board: newBoard,
      notes: newNotes,
      actionHistory: history,
      redoStack: const [],
      conflicts: conflicts,
    );

    final vibrationEnabled =
        ref.read(settingsNotifierProvider).vibrationEnabled;
    if (conflicts.isNotEmpty) {
      unawaited(PlatformUtils.vibrateError(enabled: vibrationEnabled));
    } else {
      unawaited(PlatformUtils.vibrateLight(enabled: vibrationEnabled));
    }

    _checkCompletion(newBoard);
    _persistAutoSave();
  }

  void toggleNoteMode() {
    state = state.copyWith(isNoteMode: !state.isNoteMode);
  }

  void toggleNote(int value) {
    if (!state.hasSelection || state.isCompleted || state.isPaused) return;
    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.fixedCells[row][col]) return;
    if (state.board[row][col] != 0) return; // Can't add notes to filled cells

    final newNotes = _cloneNotes(state.notes);
    final cellNotes = newNotes[row][col];

    if (cellNotes.contains(value)) {
      cellNotes.remove(value);
    } else if (cellNotes.length < 4) {
      cellNotes.add(value);
    }

    state = state.copyWith(notes: newNotes);
    _persistAutoSave();
  }

  void clearCell() {
    if (!state.hasSelection || state.isCompleted) return;
    enterNumber(0);
  }

  /// Use hint. Returns true if successful, false if no hints available
  Future<bool> useHint() async {
    if (!state.hasSelection || state.isCompleted) return false;
    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.fixedCells[row][col]) return false;

    // Check if user has hints in global balance (Premium or purchased/earned hints)
    final isPremium = ref.read(premiumStatusProvider).isPremium;
    final hintBalance = ref.read(hintBalanceProvider);
    
    if (!isPremium && hintBalance.currentHints <= 0) {
      // No hints available
      return false;
    }

    // Use hint from global balance (unless premium)
    if (!isPremium) {
      final used = await ref.read(hintBalanceProvider.notifier).useHint();
      if (!used) return false;
    }

    final correctValue = state.solution[row][col];
    enterNumber(correctValue);
    state = state.copyWith(hintsUsed: state.hintsUsed + 1);
    _persistAutoSave();
    return true;
  }

  /// Reserves a hint: validates and increments the hint counter only.
  /// Returns the correct value for the selected cell, or null if invalid.
  /// Does NOT place the number on the board (used with hint animations).
  Future<int?> reserveHint() async {
    if (!state.hasSelection || state.isCompleted) return null;
    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.fixedCells[row][col]) return null;

    // Check global hint balance
    final isPremium = ref.read(premiumStatusProvider).isPremium;
    final hintBalance = ref.read(hintBalanceProvider);
    
    if (!isPremium && hintBalance.currentHints <= 0) {
      return null; // No hints available
    }

    // Use hint from global balance (unless premium)
    if (!isPremium) {
      // Call the PROVIDER notifier, not the repository directly!
      final used = await ref.read(hintBalanceProvider.notifier).useHint();
      
      if (!used) {
        // Failed to use hint (race condition or other issue)
        return null;
      }
    }

    final correctValue = state.solution[row][col];
    state = state.copyWith(hintsUsed: state.hintsUsed + 1);
    _persistAutoSave();
    
    return correctValue;
  }

  /// Places a hint value at a specific cell position.
  /// Called after the hint animation completes to reveal the number.
  void placeHintValue(int row, int col, int value) {
    if (state.isCompleted) return;
    if (state.fixedCells[row][col]) return;

    final previousValue = state.board[row][col];
    if (previousValue == value) return;

    final newBoard = _cloneBoard(state.board);
    newBoard[row][col] = value;

    final newNotes = _cloneNotes(state.notes);
    if (value != 0) {
      newNotes[row][col].clear();
    }

    final conflicts = _recalculateConflicts(newBoard);

    final history = _appendAction(
      state.actionHistory,
      GameAction(
        row: row,
        col: col,
        previousValue: previousValue,
        newValue: value,
      ),
    );

    state = state.copyWith(
      board: newBoard,
      notes: newNotes,
      actionHistory: history,
      redoStack: const [],
      conflicts: conflicts,
    );

    final vibrationEnabled =
        ref.read(settingsNotifierProvider).vibrationEnabled;
    unawaited(PlatformUtils.vibrateLight(enabled: vibrationEnabled));

    _checkCompletion(newBoard);
    _persistAutoSave();
  }

  void undo() {
    if (state.actionHistory.isEmpty) return;
    final history = List<GameAction>.from(state.actionHistory);
    final lastAction = history.removeLast();
    final redo = List<GameAction>.from(state.redoStack)..add(lastAction);

    final newBoard = _cloneBoard(state.board);
    newBoard[lastAction.row][lastAction.col] = lastAction.previousValue;

    state = state.copyWith(
      board: newBoard,
      actionHistory: history,
      redoStack: redo,
      conflicts: _recalculateConflicts(newBoard),
      isCompleted: false,
    );
    _persistAutoSave();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final redo = List<GameAction>.from(state.redoStack);
    final action = redo.removeLast();
    final history = _appendAction(state.actionHistory, action);

    final newBoard = _cloneBoard(state.board);
    newBoard[action.row][action.col] = action.newValue;

    state = state.copyWith(
      board: newBoard,
      redoStack: redo,
      actionHistory: history,
      conflicts: _recalculateConflicts(newBoard),
    );
    _checkCompletion(newBoard);
    _persistAutoSave();
  }

  void togglePause() {
    final isPaused = !state.isPaused;
    state = state.copyWith(isPaused: isPaused);
    if (isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  Future<void> saveToSlot(int slot) async {
    await _gameRepository.saveGame(slot, state);
  }

  Future<void> deleteSlot(int slot) async {
    await _gameRepository.deleteGame(slot);
  }

  Future<bool> loadSlot(int slot) async {
    final saved = _gameRepository.loadGame(slot);
    if (saved == null) {
      return false;
    }
    _timer?.cancel();
    state = saved.copyWith(
      isPaused: false,
      conflicts: _recalculateConflicts(saved.board),
    );
    _startTimer();
    _persistAutoSave();
    return true;
  }

  Future<bool> resumeAutosave() async {
    final saved = _gameRepository.loadAutoSave();
    if (saved == null) return false;
    _timer?.cancel();
    state = saved.copyWith(
      isPaused: false,
      conflicts: _recalculateConflicts(saved.board),
    );
    _startTimer();
    return true;
  }

  List<SavedGameSummary> savedGames() => _gameRepository.listSavedGames();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.timerTick, (_) {
      if (state.isPaused || state.isCompleted) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _checkCompletion(List<List<int>> board) {
    // Check if board is completely filled
    for (var row = 0; row < AppConstants.boardSize; row++) {
      for (var col = 0; col < AppConstants.boardSize; col++) {
        if (board[row][col] == 0) {
          debugPrint(
              '[GameNotifier] Board not complete: empty cell at ($row, $col)');
          return;
        }
      }
    }

    // Check if there are any conflicts (instead of matching exact solution)
    // This allows any valid Sudoku solution, not just the pre-generated one
    final conflicts = _recalculateConflicts(board);
    if (conflicts.isNotEmpty) {
      debugPrint(
          '[GameNotifier] Board has conflicts: ${conflicts.length} conflicting cells');
      return;
    }

    // Game completed! All cells filled with no conflicts = valid solution
    debugPrint(
        '[GameNotifier] Game completed! Difficulty: ${state.difficulty.label}');
    _timer?.cancel();
    state = state.copyWith(isCompleted: true, isPaused: true);

    // Stop background music and play finish sound (check settings)
    final soundEnabled = ref.read(settingsNotifierProvider).soundEnabled;
    if (soundEnabled) {
      unawaited(AudioService.instance.stopBackground());
      unawaited(AudioService.instance.playFinishSound(enabled: true));
    }
    // Don't auto-add to leaderboard - let UI show dialog first
  }

  Future<void> saveToLeaderboard(String playerName) async {
    if (!state.isCompleted) return;
    await _leaderboardRepository.add(
      state.difficulty,
      LeaderboardEntry(
        playerName: playerName.isEmpty ? 'Guest' : playerName,
        seconds: state.elapsedSeconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  Set<CellCoordinate> _updatedConflicts(
    List<List<int>> board,
    int row,
    int col,
    int value,
  ) {
    final conflicts = Set<CellCoordinate>.from(state.conflicts);
    conflicts.removeWhere(
      (coord) => coord.row == row && coord.col == col,
    );
    conflicts.addAll(_validator.findConflicts(board, row, col, value));
    return conflicts;
  }

  Set<CellCoordinate> _recalculateConflicts(List<List<int>> board) {
    final conflicts = <CellCoordinate>{};
    for (var row = 0; row < AppConstants.boardSize; row++) {
      for (var col = 0; col < AppConstants.boardSize; col++) {
        final value = board[row][col];
        if (value == 0) continue;
        conflicts.addAll(_validator.findConflicts(board, row, col, value));
      }
    }
    return conflicts;
  }

  List<List<bool>> _buildFixedCells(List<List<int>> board) {
    return [
      for (final row in board) [for (final value in row) value != 0],
    ];
  }

  List<List<int>> _cloneBoard(List<List<int>> board) {
    return [
      for (final row in board) [...row],
    ];
  }

  List<List<Set<int>>> _cloneNotes(List<List<Set<int>>> notes) {
    return [
      for (final row in notes)
        [
          for (final cellNotes in row) {...cellNotes},
        ],
    ];
  }

  List<GameAction> _appendAction(
    List<GameAction> list,
    GameAction action,
  ) {
    final updated = [...list, action];
    if (updated.length <= AppConstants.maxUndoActions) {
      return updated;
    }
    return updated.sublist(updated.length - AppConstants.maxUndoActions);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _persistAutoSave() {
    unawaited(_gameRepository.autoSave(state));
  }
}
