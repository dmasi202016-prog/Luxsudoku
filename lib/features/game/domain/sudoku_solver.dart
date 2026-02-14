import 'dart:math';

import '../../../core/constants/app_constants.dart';

typedef Board = List<List<int>>;

class SudokuSolver {
  bool solve(Board board) {
    for (var row = 0; row < AppConstants.boardSize; row++) {
      for (var col = 0; col < AppConstants.boardSize; col++) {
        if (board[row][col] == 0) {
          for (var number = 1; number <= AppConstants.boardSize; number++) {
            if (_isSafe(board, row, col, number)) {
              board[row][col] = number;
              if (solve(board)) {
                return true;
              }
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  int countSolutions(Board board, {int maxSolutions = 2}) {
    var solutions = 0;

    bool backtrack() {
      for (var row = 0; row < AppConstants.boardSize; row++) {
        for (var col = 0; col < AppConstants.boardSize; col++) {
          if (board[row][col] == 0) {
            for (var number = 1; number <= AppConstants.boardSize; number++) {
              if (_isSafe(board, row, col, number)) {
                board[row][col] = number;
                if (backtrack()) {
                  solutions++;
                  if (solutions >= maxSolutions) {
                    board[row][col] = 0;
                    return true;
                  }
                }
                board[row][col] = 0;
              }
            }
            return false;
          }
        }
      }
      solutions++;
      return solutions >= maxSolutions;
    }

    backtrack();
    return solutions;
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

  Board deepCopy(Board board) {
    return [
      for (final row in board) [...row],
    ];
  }

  void shuffleNumbers(Board board) {
    final numbers = List.generate(AppConstants.boardSize, (index) => index + 1);
    numbers.shuffle(Random());
    final mapping = <int, int>{
      for (var i = 0; i < numbers.length; i++) i + 1: numbers[i],
    };
    for (var row = 0; row < AppConstants.boardSize; row++) {
      for (var col = 0; col < AppConstants.boardSize; col++) {
        final value = board[row][col];
        if (value != 0) {
          board[row][col] = mapping[value]!;
        }
      }
    }
  }
}
