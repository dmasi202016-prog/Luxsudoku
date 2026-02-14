import '../../../core/constants/app_constants.dart';
import 'cell_coordinate.dart';

typedef Board = List<List<int>>;

class SudokuValidator {
  bool isValid(Board board, int row, int col, int value) {
    if (value == 0) return true;
    for (var i = 0; i < AppConstants.boardSize; i++) {
      if (board[row][i] == value && i != col) return false;
      if (board[i][col] == value && i != row) return false;
    }

    final startRow = row ~/ AppConstants.subGridSize * AppConstants.subGridSize;
    final startCol = col ~/ AppConstants.subGridSize * AppConstants.subGridSize;
    for (var r = 0; r < AppConstants.subGridSize; r++) {
      for (var c = 0; c < AppConstants.subGridSize; c++) {
        final targetRow = startRow + r;
        final targetCol = startCol + c;
        if (board[targetRow][targetCol] == value &&
            (targetRow != row || targetCol != col)) {
          return false;
        }
      }
    }

    return true;
  }

  Set<CellCoordinate> findConflicts(
    Board board,
    int row,
    int col,
    int value,
  ) {
    final conflicts = <CellCoordinate>{};
    if (value == 0) return conflicts;

    for (var i = 0; i < AppConstants.boardSize; i++) {
      if (board[row][i] == value && i != col) {
        conflicts.add(CellCoordinate(row, i));
      }
      if (board[i][col] == value && i != row) {
        conflicts.add(CellCoordinate(i, col));
      }
    }

    final startRow = row ~/ AppConstants.subGridSize * AppConstants.subGridSize;
    final startCol = col ~/ AppConstants.subGridSize * AppConstants.subGridSize;

    for (var r = 0; r < AppConstants.subGridSize; r++) {
      for (var c = 0; c < AppConstants.subGridSize; c++) {
        final targetRow = startRow + r;
        final targetCol = startCol + c;
        if (board[targetRow][targetCol] == value &&
            (targetRow != row || targetCol != col)) {
          conflicts.add(CellCoordinate(targetRow, targetCol));
        }
      }
    }

    if (conflicts.isNotEmpty) {
      conflicts.add(CellCoordinate(row, col));
    }
    return conflicts;
  }
}
