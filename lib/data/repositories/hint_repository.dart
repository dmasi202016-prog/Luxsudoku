import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/monetization_constants.dart';
import '../models/hint_balance.dart';

/// Repository for managing hint balance
class HintRepository {
  HintRepository(this._prefs);

  final SharedPreferences _prefs;
  HintBalance? _cachedBalance;

  // ============================================================
  // Get Hint Balance
  // ============================================================

  /// Get current hint balance
  HintBalance getBalance() {
    if (_cachedBalance != null) {
      return _cachedBalance!;
    }

    final json = _prefs.getString(MonetizationConstants.hintBalanceKey);
    if (json == null) {
      _cachedBalance = HintBalance.initial();
      _saveBalance(_cachedBalance!);
      return _cachedBalance!;
    }

    try {
      final map = Map<String, dynamic>.from(
        // ignore: avoid_dynamic_calls
        Uri.splitQueryString(json).map(
          (key, value) => MapEntry(key, _parseValue(value)),
        ),
      );
      _cachedBalance = HintBalance.fromJson(map);
      return _cachedBalance!;
    } catch (e) {
      debugPrint('[HintRepository] Error loading balance: $e');
      _cachedBalance = HintBalance.initial();
      return _cachedBalance!;
    }
  }

  dynamic _parseValue(String value) {
    // Try to parse as int
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    
    // Return as string (for DateTime)
    return value;
  }

  // ============================================================
  // Update Hint Balance
  // ============================================================

  /// Use a hint (decrement)
  Future<bool> useHint() async {
    final balance = getBalance();
    
    if (balance.currentHints <= 0) {
      debugPrint('[HintRepository] No hints available');
      return false;
    }

    final updated = balance.copyWith(
      currentHints: balance.currentHints - 1,
      totalUsed: balance.totalUsed + 1,
      lastUpdated: DateTime.now(),
    );

    await _saveBalance(updated);
    
    debugPrint('[HintRepository] Hint used. Remaining: ${updated.currentHints}');
    return true;
  }

  /// Add hints from rewarded ad
  Future<void> addHintsFromAd(int amount) async {
    final balance = getBalance();
    final newAmount = (balance.currentHints + amount)
        .clamp(0, MonetizationConstants.maxFreeUserHints);

    final updated = balance.copyWith(
      currentHints: newAmount,
      totalFromAds: balance.totalFromAds + amount,
      lastUpdated: DateTime.now(),
    );

    await _saveBalance(updated);
    debugPrint('[HintRepository] Added $amount hints from ad. Total: ${updated.currentHints}');
  }

  /// Add hints from purchase
  Future<void> addHintsFromPurchase(int amount) async {
    final balance = getBalance();
    final newAmount = balance.currentHints + amount;

    final updated = balance.copyWith(
      currentHints: newAmount,
      totalPurchased: balance.totalPurchased + amount,
      lastUpdated: DateTime.now(),
    );

    await _saveBalance(updated);
    debugPrint('[HintRepository] Added $amount hints from purchase. Total: ${updated.currentHints}');
  }

  /// Reset hints to initial amount (for new game)
  Future<void> resetToDefault() async {
    final balance = getBalance();
    final updated = balance.copyWith(
      currentHints: MonetizationConstants.defaultHintsPerGame,
      lastUpdated: DateTime.now(),
    );

    await _saveBalance(updated);
    debugPrint('[HintRepository] Hints reset to default: ${updated.currentHints}');
  }

  // ============================================================
  // Statistics
  // ============================================================

  /// Get total hints used
  int getTotalUsed() => getBalance().totalUsed;

  /// Get total hints from ads
  int getTotalFromAds() => getBalance().totalFromAds;

  /// Get total hints purchased
  int getTotalPurchased() => getBalance().totalPurchased;

  // ============================================================
  // Private Methods
  // ============================================================

  Future<void> _saveBalance(HintBalance balance) async {
    _cachedBalance = balance;
    final json = _encodeJson(balance.toJson());
    await _prefs.setString(MonetizationConstants.hintBalanceKey, json);
  }

  String _encodeJson(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  /// Clear all hint data (for testing)
  Future<void> clearData() async {
    await _prefs.remove(MonetizationConstants.hintBalanceKey);
    _cachedBalance = null;
    debugPrint('[HintRepository] Hint data cleared');
  }
}
