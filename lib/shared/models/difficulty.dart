import 'package:flutter/material.dart';

enum Difficulty {
  veryEasy,
  easy,
  medium,
  hard,
  expert;

  String get label {
    switch (this) {
      case Difficulty.veryEasy:
        return 'Very Easy';
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  int get minEmptyCells {
    switch (this) {
      case Difficulty.veryEasy:
        return 20;
      case Difficulty.easy:
        return 30;
      case Difficulty.medium:
        return 40;
      case Difficulty.hard:
        return 50;
      case Difficulty.expert:
        return 60;
    }
  }

  int get maxEmptyCells {
    switch (this) {
      case Difficulty.veryEasy:
        return 25;
      case Difficulty.easy:
        return 35;
      case Difficulty.medium:
        return 45;
      case Difficulty.hard:
        return 55;
      case Difficulty.expert:
        return 65;
    }
  }

  /// Maximum hints per game (same for all difficulties)
  static const int maxHints = 3;
  
  /// Legacy method for backwards compatibility
  @Deprecated('Use Difficulty.maxHints instead')
  int get maxHintsLegacy {
    return maxHints;
  }

  Color get accentColor {
    // Unified Gold theme for all difficulties
    return const Color(0xFFD4AF37); // Classic gold
  }

  static Difficulty fromName(String value) {
    return Difficulty.values.firstWhere(
      (difficulty) => difficulty.name == value,
      orElse: () => Difficulty.veryEasy,
    );
  }
}

const difficultyOptions = Difficulty.values;
