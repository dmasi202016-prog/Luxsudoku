import 'package:flutter/services.dart';

/// Haptic feedback service for vibration effects
class HapticService {
  HapticService._();
  
  static final HapticService instance = HapticService._();
  
  /// Light haptic feedback for button taps
  Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }
  
  /// Medium haptic feedback for important actions
  Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }
  
  /// Heavy haptic feedback for critical actions
  Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }
  
  /// Selection click for UI interactions
  Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }
  
  /// Vibrate for errors or conflicts
  Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      // Silently fail if haptic not available
    }
  }
}
