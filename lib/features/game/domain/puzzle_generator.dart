import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/difficulty.dart';
import 'sudoku_solver.dart';

typedef Board = List<List<int>>;

class PuzzleGenerator {
  PuzzleGenerator(this._solver);

  final SudokuSolver _solver;
  final Random _random = Random();

  ({Board puzzle, Board solution}) generate(Difficulty difficulty) {
    final solvedBoard = List.generate(
      AppConstants.boardSize,
      (_) => List.filled(AppConstants.boardSize, 0),
    );
    _fillBoard(solvedBoard);
    _solver.shuffleNumbers(solvedBoard);

    final solution = _solver.deepCopy(solvedBoard);
    final puzzle = _solver.deepCopy(solvedBoard);

    // Simple approach: randomly remove targetEmpty cells
    final targetEmpty = _randomBetween(
      difficulty.minEmptyCells,
      difficulty.maxEmptyCells,
    );
    
    final allCells = List.generate(81, (i) => i)..shuffle(_random);
    var removed = 0;

    for (final cellIndex in allCells) {
      if (removed >= targetEmpty) break;
      final row = cellIndex ~/ AppConstants.boardSize;
      final col = cellIndex % AppConstants.boardSize;
      
      if (puzzle[row][col] != 0) {
        puzzle[row][col] = 0;
        removed++;
      }
    }

    return (puzzle: puzzle, solution: solution);
  }

  bool _fillBoard(Board board) {
    for (var row = 0; row < AppConstants.boardSize; row++) {
      for (var col = 0; col < AppConstants.boardSize; col++) {
        if (board[row][col] == 0) {
          final numbers = List.generate(AppConstants.boardSize, (index) => index + 1)
            ..shuffle(_random);
          for (final number in numbers) {
            if (_isSafe(board, row, col, number)) {
              board[row][col] = number;
              if (_fillBoard(board)) {
                return true;
              }
            }
          }
          board[row][col] = 0;
          return false;
        }
      }
    }
    return true;
  }

  bool _isSafe(Board board, int row, int col, int number) {
    for (var i = 0; i < AppConstants.boardSize; i++) {
      if (board[row][i] == number || board[i][col] == number) {
        return false;
      }
    }

    final startRow = row ~/ AppConstants.subGridSize * AppConstants.subGridSize;
    final startCol = col ~/ AppConstants.subGridSize * AppConstants.subGridSize;
    for (var r = 0; r < AppConstants.subGridSize; r++) {
      for (var c = 0; c < AppConstants.subGridSize; c++) {
        if (board[startRow + r][startCol + c] == number) {
          return false;
        }
      }
    }
    return true;
  }

  int _randomBetween(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }
}
