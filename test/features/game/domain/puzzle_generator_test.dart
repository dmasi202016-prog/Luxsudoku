import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/game/domain/puzzle_generator.dart';
import 'package:sudoku_app/features/game/domain/sudoku_solver.dart';
import 'package:sudoku_app/shared/models/difficulty.dart';

void main() {
  final generator = PuzzleGenerator(SudokuSolver());

  test('puzzle generator produces solvable puzzle', () {
    final result = generator.generate(Difficulty.medium);
    final solver = SudokuSolver();
    final puzzleCopy = solver.deepCopy(result.puzzle);
    final solved = solver.solve(puzzleCopy);

    expect(solved, isTrue);
    expect(puzzleCopy, equals(result.solution));
  });

  test('puzzle respects difficulty empty range', () {
    final result = generator.generate(Difficulty.easy);
    final emptyCells = result.puzzle.expand((row) => row).where((cell) => cell == 0).length;
    expect(emptyCells, inInclusiveRange(Difficulty.easy.minEmptyCells, Difficulty.easy.maxEmptyCells));
  });
}
