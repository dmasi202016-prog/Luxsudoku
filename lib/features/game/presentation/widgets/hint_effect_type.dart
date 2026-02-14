import 'dart:math';
import 'dart:ui' show Color;

/// Types of hint effects displayed when a hint is used.
///
/// Each effect plays a unique animation over the target cell
/// before revealing the correct number.
enum HintEffectType {
  /// Lightning bolt strikes the cell (번개 - 헤라클레스 번개던지기)
  lightning,

  /// Bomb drops and explodes (폭탄 폭발)
  bomb,

  /// Hurricane swirls around the cell (허리케인)
  hurricane,

  /// Hammer smashes the cell (망치)
  hammer,

  /// Fire burst effect (불꽃) - bonus
  fire,

  /// Magic sparkle effect (마법 반짝임) - bonus
  magicSparkle;

  static final _random = Random();

  /// Returns a random hint effect type.
  static HintEffectType random() {
    return values[_random.nextInt(values.length)];
  }

  /// Display label for the effect (Korean + English).
  String get label {
    switch (this) {
      case lightning:
        return 'Lightning Strike';
      case bomb:
        return 'Bomb Explosion';
      case hurricane:
        return 'Hurricane';
      case hammer:
        return 'Hammer Smash';
      case fire:
        return 'Fire Burst';
      case magicSparkle:
        return 'Magic Sparkle';
    }
  }

  /// Primary color for the effect.
  Color get primaryColor {
    switch (this) {
      case lightning:
        return const Color(0xFF64C8FF);
      case bomb:
        return const Color(0xFFFF6B35);
      case hurricane:
        return const Color(0xFF00CED1);
      case hammer:
        return const Color(0xFFB0B0B0);
      case fire:
        return const Color(0xFFFF4500);
      case magicSparkle:
        return const Color(0xFFAA66FF);
    }
  }
}
