import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/game/domain/sudoku_validator.dart';

void main() {
  final validator = SudokuValidator();
  final baseBoard = List.generate(
    9,
    (_) => List.filled(9, 0),
  );

  test('validator accepts empty board', () {
    expect(validator.isValid(baseBoard, 0, 0, 0), isTrue);
  });

  test('validator detects duplicate in row', () {
    final board = List.generate(
      9,
      (_) => List.filled(9, 0),
    );
    board[0][0] = 5;
    board[0][3] = 5;
    expect(validator.isValid(board, 0, 3, 5), isFalse);
    final conflicts = validator.findConflicts(board, 0, 3, 5);
    expect(conflicts.length, 2);
  });

  test('validator detects duplicate in subgrid', () {
    final board = List.generate(
      9,
      (_) => List.filled(9, 0),
    );
    board[1][1] = 8;
    board[2][2] = 8;
    expect(validator.isValid(board, 2, 2, 8), isFalse);
  });
}
