import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/monetization_constants.dart';
import '../models/premium_status.dart';

/// Repository for managing premium status and purchases
class PurchaseRepository {
  PurchaseRepository(this._prefs);

  final SharedPreferences _prefs;
  PremiumStatus? _cachedStatus;

  // ============================================================
  // Premium Status
  // ============================================================

  /// Get premium status
  PremiumStatus getStatus() {
    if (_cachedStatus != null) {
      return _cachedStatus!;
    }

    final json = _prefs.getString(MonetizationConstants.premiumStatusKey);
    if (json == null) {
      _cachedStatus = PremiumStatus.free();
      return _cachedStatus!;
    }

    try {
      final map = Map<String, dynamic>.from(
        Uri.splitQueryString(json).map(
          (key, value) => MapEntry(key, _parseValue(key, value)),
        ),
      );
      _cachedStatus = PremiumStatus.fromJson(map);
      return _cachedStatus!;
    } catch (e) {
      debugPrint('[PurchaseRepository] Error loading status: $e');
      _cachedStatus = PremiumStatus.free();
      return _cachedStatus!;
    }
  }

  dynamic _parseValue(String key, String value) {
    // Parse boolean
    if (key == 'isPremium') {
      return value.toLowerCase() == 'true';
    }
    
    // Parse null values
    if (value == 'null') return null;
    
    // Return as string
    return value;
  }

  /// Check if user is premium
  bool isPremium() => getStatus().isPremium;

  /// Unlock premium
  Future<void> unlockPremium({
    required String transactionId,
  }) async {
    final status = PremiumStatus.premium(
      purchasedAt: DateTime.now(),
      transactionId: transactionId,
    );

    await _saveStatus(status);
    debugPrint('[PurchaseRepository] Premium unlocked');
  }

  /// Restore premium (from purchase restore)
  Future<void> restorePremium({
    required String transactionId,
    required DateTime purchasedAt,
  }) async {
    final status = PremiumStatus.premium(
      purchasedAt: purchasedAt,
      transactionId: transactionId,
    );

    await _saveStatus(status);
    debugPrint('[PurchaseRepository] Premium restored');
  }

  // ============================================================
  // Ads Disabled Status
  // ============================================================

  /// Check if ads should be disabled
  /// (Premium users don't see ads)
  bool areAdsDisabled() {
    return isPremium();
  }

  // ============================================================
  // Purchase History
  // ============================================================

  /// Record a hint pack purchase
  Future<void> recordHintPurchase({
    required String productId,
    required String transactionId,
  }) async {
    // Save to purchase history
    final history = _getPurchaseHistory();
    history.add({
      'productId': productId,
      'transactionId': transactionId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _savePurchaseHistory(history);
    debugPrint('[PurchaseRepository] Hint purchase recorded: $productId');
  }

  /// Get purchase history
  List<Map<String, String>> _getPurchaseHistory() {
    final json = _prefs.getString('purchase_history');
    if (json == null) return [];

    try {
      // Simple parsing (in production, use proper JSON encoding)
      final items = json.split('|');
      return items.map((item) {
        final parts = item.split(',');
        return {
          'productId': parts[0],
          'transactionId': parts[1],
          'timestamp': parts[2],
        };
      }).toList();
    } catch (e) {
      debugPrint('[PurchaseRepository] Error loading history: $e');
      return [];
    }
  }

  Future<void> _savePurchaseHistory(
    List<Map<String, String>> history,
  ) async {
    // Simple encoding (in production, use proper JSON encoding)
    final encoded = history
        .map((item) =>
            '${item['productId']},${item['transactionId']},${item['timestamp']}')
        .join('|');
    await _prefs.setString('purchase_history', encoded);
  }

  // ============================================================
  // Private Methods
  // ============================================================

  Future<void> _saveStatus(PremiumStatus status) async {
    _cachedStatus = status;
    final json = _encodeJson(status.toJson());
    await _prefs.setString(MonetizationConstants.premiumStatusKey, json);
  }

  String _encodeJson(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  /// Clear all purchase data (for testing)
  Future<void> clearData() async {
    await _prefs.remove(MonetizationConstants.premiumStatusKey);
    await _prefs.remove('purchase_history');
    _cachedStatus = null;
    debugPrint('[PurchaseRepository] Purchase data cleared');
  }
}
