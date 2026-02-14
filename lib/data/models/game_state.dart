import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../features/game/domain/cell_coordinate.dart';
import '../../shared/models/difficulty.dart';
import 'game_action.dart';

class GameState {
  const GameState({
    required this.board,
    required this.solution,
    required this.fixedCells,
    required this.difficulty,
    required this.hintsUsed,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.isCompleted,
    required this.actionHistory,
    required this.redoStack,
    required this.notes,
    this.selectedRow,
    this.selectedCol,
    this.startedAt,
    this.conflicts = const {},
    this.isNoteMode = false,
  });

  final List<List<int>> board;
  final List<List<int>> solution;
  final List<List<bool>> fixedCells;
  final List<List<Set<int>>> notes; // Notes for each cell (max 4 numbers)
  final Difficulty difficulty;
  final int? selectedRow;
  final int? selectedCol;
  final int hintsUsed;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isCompleted;
  final bool isNoteMode; // Whether note mode is active
  final DateTime? startedAt;
  final List<GameAction> actionHistory;
  final List<GameAction> redoStack;
  final Set<CellCoordinate> conflicts;

  factory GameState.initial(Difficulty difficulty) {
    final board = List.generate(
      AppConstants.boardSize,
      (_) => List.filled(AppConstants.boardSize, 0),
    );
    final fixed = List.generate(
      AppConstants.boardSize,
      (_) => List.filled(AppConstants.boardSize, false),
    );
    final notes = List.generate(
      AppConstants.boardSize,
      (_) => List.generate(AppConstants.boardSize, (_) => <int>{}),
    );

    return GameState(
      board: board,
      solution: board,
      fixedCells: fixed,
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
  }

  GameState copyWith({
    List<List<int>>? board,
    List<List<int>>? solution,
    List<List<bool>>? fixedCells,
    List<List<Set<int>>>? notes,
    Difficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    int? hintsUsed,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isCompleted,
    bool? isNoteMode,
    DateTime? startedAt,
    List<GameAction>? actionHistory,
    List<GameAction>? redoStack,
    Set<CellCoordinate>? conflicts,
  }) {
    return GameState(
      board: board ?? this.board,
      solution: solution ?? this.solution,
      fixedCells: fixedCells ?? this.fixedCells,
      notes: notes ?? this.notes,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isNoteMode: isNoteMode ?? this.isNoteMode,
      startedAt: startedAt ?? this.startedAt,
      actionHistory: actionHistory ?? this.actionHistory,
      redoStack: redoStack ?? this.redoStack,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  bool get hasSelection => selectedRow != null && selectedCol != null;
}

class GameStateAdapter extends TypeAdapter<GameState> {
  @override
  final int typeId = 0;

  @override
  GameState read(BinaryReader reader) {
    final board = _inflateIntBoard(reader.readList().cast<int>());
    final solution = _inflateIntBoard(reader.readList().cast<int>());
    final fixed = _inflateBoolBoard(reader.readList().cast<int>());
    final difficulty = Difficulty.values[reader.readInt()];
    final hintsUsed = reader.readInt();
    final elapsed = reader.readInt();
    final isPaused = reader.readBool();
    final isCompleted = reader.readBool();
    final startedAtMs = reader.readInt();
    final actions = reader.readList().cast<GameAction>();
    final redo = reader.readList().cast<GameAction>();
    final conflictsRaw = reader.readList();
    final conflicts = conflictsRaw
        .map(
          (item) => CellCoordinate(
            (item as List).first as int,
            item.last as int,
          ),
        )
        .toSet();

    // Initialize empty notes (not persisted for simplicity)
    final notes = List.generate(
      AppConstants.boardSize,
      (_) => List.generate(AppConstants.boardSize, (_) => <int>{}),
    );

    return GameState(
      board: board,
      solution: solution,
      fixedCells: fixed,
      notes: notes,
      difficulty: difficulty,
      hintsUsed: hintsUsed,
      elapsedSeconds: elapsed,
      isPaused: isPaused,
      isCompleted: isCompleted,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      actionHistory: actions,
      redoStack: redo,
      conflicts: conflicts,
    );
  }

  @override
  void write(BinaryWriter writer, GameState obj) {
    writer
      ..writeList(_flattenBoard(obj.board))
      ..writeList(_flattenBoard(obj.solution))
      ..writeList(_flattenBoolBoard(obj.fixedCells))
      ..writeInt(obj.difficulty.index)
      ..writeInt(obj.hintsUsed)
      ..writeInt(obj.elapsedSeconds)
      ..writeBool(obj.isPaused)
      ..writeBool(obj.isCompleted)
      ..writeInt(obj.startedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch)
      ..writeList(obj.actionHistory)
      ..writeList(obj.redoStack)
      ..writeList(
        obj.conflicts.map((c) => [c.row, c.col]).toList(),
      );
  }

  static List<List<int>> _inflateIntBoard(List<int> data) {
    final board = <List<int>>[];
    for (var i = 0; i < data.length; i += AppConstants.boardSize) {
      board.add(
        data.sublist(i, i + AppConstants.boardSize).toList(),
      );
    }
    return board;
  }

  static List<int> _flattenBoard(List<List<int>> board) {
    return [
      for (final row in board) ...row,
    ];
  }

  static List<List<bool>> _inflateBoolBoard(List<int> data) {
    final board = <List<bool>>[];
    for (var i = 0; i < data.length; i += AppConstants.boardSize) {
      board.add(
        data.sublist(i, i + AppConstants.boardSize).map((value) => value == 1).toList(),
      );
    }
    return board;
  }

  static List<int> _flattenBoolBoard(List<List<bool>> board) {
    return [
      for (final row in board) ...row.map((value) => value ? 1 : 0),
    ];
  }
}
