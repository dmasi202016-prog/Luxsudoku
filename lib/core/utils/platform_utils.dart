import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class PlatformUtils {
  PlatformUtils._();

  static bool get isWeb => kIsWeb;

  // Heavy vibration for errors (0.5 seconds effect)
  static Future<void> vibrateError({bool enabled = true}) async {
    if (kIsWeb || !enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // Light vibration for normal touches (0.1 seconds)
  static Future<void> vibrateLight({bool enabled = true}) async {
    if (kIsWeb || !enabled) return;
    await HapticFeedback.lightImpact();
  }

  // Medium vibration for selections
  static Future<void> vibrateMedium({bool enabled = true}) async {
    if (kIsWeb || !enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
