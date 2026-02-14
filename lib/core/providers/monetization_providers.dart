import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/hint_balance.dart';
import '../../data/models/premium_status.dart';
import '../../data/repositories/hint_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import 'repository_providers.dart';

// ============================================================
// Hint Provider
// ============================================================

/// Provider for hint balance state
final hintBalanceProvider = StateNotifierProvider<HintNotifier, HintBalance>(
  (ref) {
    final repository = ref.watch(hintRepositoryProvider);
    return HintNotifier(repository);
  },
);

class HintNotifier extends StateNotifier<HintBalance> {
  HintNotifier(this._repository) : super(_repository.getBalance());

  final HintRepository _repository;

  /// Refresh balance from repository
  void refresh() {
    state = _repository.getBalance();
  }

  /// Use a hint
  Future<bool> useHint() async {
    final success = await _repository.useHint();
    if (success) {
      refresh();
    }
    return success;
  }

  /// Add hints from rewarded ad
  Future<void> addHintsFromAd(int amount) async {
    await _repository.addHintsFromAd(amount);
    refresh();
  }

  /// Add hints from purchase
  Future<void> addHintsFromPurchase(int amount) async {
    await _repository.addHintsFromPurchase(amount);
    refresh();
  }

  /// Reset hints to default
  Future<void> resetToDefault() async {
    await _repository.resetToDefault();
    refresh();
  }

  /// Get current hint count
  int get currentHints => state.currentHints;

  /// Check if hints are available
  bool get hasHints => state.currentHints > 0;
}

// ============================================================
// Premium Provider
// ============================================================

/// Provider for premium status state
final premiumStatusProvider =
    StateNotifierProvider<PremiumNotifier, PremiumStatus>(
  (ref) {
    final repository = ref.watch(purchaseRepositoryProvider);
    return PremiumNotifier(repository);
  },
);

class PremiumNotifier extends StateNotifier<PremiumStatus> {
  PremiumNotifier(this._repository) : super(_repository.getStatus());

  final PurchaseRepository _repository;

  /// Refresh status from repository
  void refresh() {
    state = _repository.getStatus();
  }

  /// Unlock premium
  Future<void> unlockPremium({required String transactionId}) async {
    await _repository.unlockPremium(transactionId: transactionId);
    refresh();
  }

  /// Restore premium
  Future<void> restorePremium({
    required String transactionId,
    required DateTime purchasedAt,
  }) async {
    await _repository.restorePremium(
      transactionId: transactionId,
      purchasedAt: purchasedAt,
    );
    refresh();
  }

  /// Check if user is premium
  bool get isPremium => state.isPremium;

  /// Check if ads should be disabled
  bool get areAdsDisabled => _repository.areAdsDisabled();
}

// ============================================================
// Combined Provider (for convenience)
// ============================================================

/// Provider for checking if hints are available (considering premium)
final hintsAvailableProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(premiumStatusProvider).isPremium;
  if (isPremium) return true; // Premium users have unlimited hints

  final hintBalance = ref.watch(hintBalanceProvider);
  return hintBalance.currentHints > 0;
});

/// Provider for hint count display (considering premium)
final hintCountDisplayProvider = Provider<String>((ref) {
  final isPremium = ref.watch(premiumStatusProvider).isPremium;
  if (isPremium) return '∞'; // Premium users see infinity symbol

  final hintBalance = ref.watch(hintBalanceProvider);
  return '${hintBalance.currentHints}';
});
