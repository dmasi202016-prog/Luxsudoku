/// Monetization constants for ads and in-app purchases
class MonetizationConstants {
  MonetizationConstants._();

  // ============================================================
  // AdMob Ad Unit IDs
  // ============================================================
  
  // Test Ad IDs (개발 중 사용)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production Ad IDs (실제 배포 시 교체 필요)
  // TODO: AdMob 콘솔에서 앱 등록 후 실제 ID로 교체
  static const String androidBannerId = 'ca-app-pub-3940256099942544/6300978111'; // 테스트 ID
  static const String iosBannerId = 'ca-app-pub-3940256099942544/2934735716'; // 테스트 ID
  
  static const String androidRewardedId = 'ca-app-pub-3940256099942544/5224354917'; // 테스트 ID
  static const String iosRewardedId = 'ca-app-pub-3940256099942544/1712485313'; // 테스트 ID

  // ============================================================
  // In-App Purchase Product IDs
  // ============================================================
  
  /// Premium unlock (non-consumable) - 광고 제거 + 무제한 힌트
  static const String premiumUnlockId = 'premium_unlock';
  
  /// Hint packs (consumable)
  static const String hints5PackId = 'hints_5';
  static const String hints20PackId = 'hints_20';
  static const String hints50PackId = 'hints_50';
  
  /// All IAP product IDs
  static const List<String> allProductIds = [
    premiumUnlockId,
    hints5PackId,
    hints20PackId,
    hints50PackId,
  ];

  // ============================================================
  // Hint System
  // ============================================================
  
  /// Default hints per game for free users
  static const int defaultHintsPerGame = 3;
  
  /// Hints rewarded per ad watch
  static const int hintsPerRewardedAd = 1;
  
  /// Hint pack quantities
  static const int hints5Quantity = 5;
  static const int hints20Quantity = 20;
  static const int hints50Quantity = 50;
  
  /// Maximum hints for free users (to prevent hoarding)
  static const int maxFreeUserHints = 20;

  // ============================================================
  // Pricing (Display only - actual price from store)
  // ============================================================
  
  static const String premiumPrice = '\$3.99';
  static const String hints5Price = '\$0.99';
  static const String hints20Price = '\$2.99';
  static const String hints50Price = '\$4.99';

  // ============================================================
  // Storage Keys
  // ============================================================
  
  static const String hintBalanceKey = 'hint_balance';
  static const String premiumStatusKey = 'premium_status';
  static const String lastHintResetKey = 'last_hint_reset';
  static const String adsDisabledKey = 'ads_disabled';
}
