import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/game_state.dart';
import '../../domain/cell_coordinate.dart';
import 'hint_effect_overlay.dart';
import 'hint_effect_type.dart';

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    super.key,
    required this.state,
    required this.onCellTap,
    this.hintAnimatingRow,
    this.hintAnimatingCol,
    this.hintEffectType,
    this.hintAnimationKey = 0,
    this.onHintAnimationComplete,
  });

  final GameState state;
  final void Function(int row, int col) onCellTap;

  /// Row of the cell currently playing a hint animation, or null.
  final int? hintAnimatingRow;

  /// Column of the cell currently playing a hint animation, or null.
  final int? hintAnimatingCol;

  /// The hint effect type being displayed.
  final HintEffectType? hintEffectType;

  /// Incremented each time a new hint animation starts (used as widget key).
  final int hintAnimationKey;

  /// Called when the hint animation finishes.
  final VoidCallback? onHintAnimationComplete;

  bool get _isHintAnimating =>
      hintAnimatingRow != null &&
      hintAnimatingCol != null &&
      hintEffectType != null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = size.width < 500 ? size.width * 0.9 : 480.0;
    final innerSize = boardSize - 16; // 8px padding on each side
    final cellSize = innerSize / AppConstants.boardSize;

    return Center(
      child: Container(
        width: boardSize,
        height: boardSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldPrimary.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: const LinearGradient(
            colors: [
              AppColors.darkBoardBg,
              Color(0xFF221D15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // --- Grid cells ---
            Column(
              children: [
                for (var row = 0; row < AppConstants.boardSize; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < AppConstants.boardSize; col++)
                          Expanded(
                            child: _SudokuCell(
                              value: state.board[row][col],
                              notes: state.notes[row][col],
                              row: row,
                              col: col,
                              isFixed: state.fixedCells[row][col],
                              isSelected: state.selectedRow == row &&
                                  state.selectedCol == col,
                              isRelated: state.selectedRow == row ||
                                  state.selectedCol == col,
                              isConflict: state.conflicts
                                  .contains(CellCoordinate(row, col)),
                              isSameNumber: state.hasSelection &&
                                  state.board[state.selectedRow!]
                                          [state.selectedCol!] !=
                                      0 &&
                                  state.board[row][col] ==
                                      state.board[state.selectedRow!]
                                          [state.selectedCol!],
                              onTap: () => onCellTap(row, col),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),

            // --- Hint effect overlay ---
            if (_isHintAnimating)
              Positioned(
                left: hintAnimatingCol! * cellSize,
                top: hintAnimatingRow! * cellSize,
                width: cellSize,
                height: cellSize,
                child: IgnorePointer(
                  child: HintEffectOverlay(
                    key: ValueKey('hint_$hintAnimationKey'),
                    effectType: hintEffectType!,
                    onComplete: onHintAnimationComplete ?? () {},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    required this.value,
    required this.notes,
    required this.row,
    required this.col,
    required this.isFixed,
    required this.isSelected,
    required this.isRelated,
    required this.isConflict,
    required this.isSameNumber,
    required this.onTap,
  });

  final int value;
  final Set<int> notes;
  final int row;
  final int col;
  final bool isFixed;
  final bool isSelected;
  final bool isRelated;
  final bool isConflict;
  final bool isSameNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.goldSecondary; // 스도쿠 판 라인

    BorderSide _borderFor(int index) {
      final isThick = index % AppConstants.subGridSize == 0;
      return BorderSide(
        color: isThick ? AppColors.goldPrimary : borderColor,
        width: isThick ? 2.0 : 0.8,
      );
    }

    final backgroundColor = () {
      if (isConflict) {
        return AppColors.errorNumberColor.withOpacity(0.3);
      }
      if (isSelected) {
        return AppColors.goldPrimary.withOpacity(0.25);
      }
      if (isSameNumber) {
        // 같은 숫자 셀: 골드 하이라이트
        return AppColors.goldPrimary.withOpacity(0.08);
      }
      if (isRelated) {
        // 관련 셀들 (같은 행/열): 같은 숫자 셀과 비슷한 수준
        return AppColors.goldPrimary.withOpacity(0.08);
      }
      // Fixed cells: darker, Empty cells: slightly lighter
      return isFixed
          ? AppColors.darkCellBg
          : AppColors.lightCellBg;
    }();

    // 선택된 칸 테두리 효과
    final isSelectedCell = isSelected;
    
    // 빛 반사 효과를 위한 gradient
    final cellGradient = !isConflict
        ? (() {
            if (isSelected || isSameNumber || isRelated) {
              // 선택/하이라이트/관련 셀: 통일된 gradient 효과
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.7),
                ],
                stops: const [0.3, 1.0],
              );
            } else if (isFixed) {
              // 고정 숫자 셀: 부드러운 빛 반사 효과
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor.withOpacity(0.9),
                  backgroundColor,
                  backgroundColor.withOpacity(0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              );
            }
            return null;
          })()
        : null;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cellGradient == null ? backgroundColor : null,
          gradient: cellGradient,
          border: Border(
            top: _borderFor(row),
            left: _borderFor(col),
            right: BorderSide(
              color: ((col + 1) % AppConstants.subGridSize == 0 || col == 8)
                  ? AppColors.goldPrimary
                  : borderColor,
              width: ((col + 1) % AppConstants.subGridSize == 0 || col == 8)
                  ? 2.0
                  : 0.8,
            ),
            bottom: BorderSide(
              color: ((row + 1) % AppConstants.subGridSize == 0 || row == 8)
                  ? AppColors.goldPrimary
                  : borderColor,
              width: ((row + 1) % AppConstants.subGridSize == 0 || row == 8)
                  ? 2.0
                  : 0.8,
            ),
          ),
          // 셀 효과: 선택된 칸/고정 숫자 셀
          boxShadow: [
            if (isSelectedCell) ...[
              // 선택된 칸: 강한 골드 글로우
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.goldHighlight.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
            ] else if (isFixed && !isConflict) ...[
              // 고정 숫자 셀: 은은한 내부 하이라이트
              BoxShadow(
                color: AppColors.goldSecondary.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(-1, -1),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(1, 1),
                spreadRadius: 0,
              ),
            ],
          ],
        ),
        alignment: Alignment.center,
        child: value != 0
            ? AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontWeight: isFixed ? FontWeight.bold : FontWeight.w600,
                  color: isConflict
                      ? AppColors.errorNumberColor // 에러 숫자
                      : isFixed
                          ? AppColors.fixedNumberColor // 기본 숫자 #F0F0F0
                          : AppColors.goldPrimary, // 입력 숫자
                  fontSize: isFixed ? 22 : 20,
                  shadows: [
                    // 빛 반사 효과 - 상단 하이라이트
                    if (!isConflict && !isFixed) ...[
                      Shadow(
                        color: AppColors.goldHighlight.withOpacity(0.6),
                        blurRadius: 12,
                        offset: const Offset(0, -1),
                      ),
                      Shadow(
                        color: AppColors.goldPrimary.withOpacity(0.8),
                        blurRadius: 8,
                      ),
                    ],
                    // 고정 숫자: 부드러운 글로우 (눈부시지 않게)
                    if (isFixed && !isConflict) ...[
                      Shadow(
                        color: AppColors.goldSecondary.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, -0.5),
                      ),
                    ],
                  ],
                ),
                child: Text('$value'),
              )
            : notes.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: notes.map((note) {
                      return Text(
                        '$note',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.noteNumberColor, // 노트 숫자
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
