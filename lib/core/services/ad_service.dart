import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/monetization_constants.dart';

/// Service for managing Google AdMob advertisements
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  BannerAd? _currentBannerAd;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// Initialize AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] AdMob initialized successfully');
    } catch (e) {
      debugPrint('[AdService] Failed to initialize AdMob: $e');
    }
  }

  /// Check if ads are initialized
  bool get isInitialized => _isInitialized;

  // ============================================================
  // Banner Ad
  // ============================================================

  /// Create and load a banner ad
  Future<BannerAd?> createBannerAd({
    AdSize size = AdSize.banner,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) {
      debugPrint('[AdService] AdMob not initialized, cannot create banner ad');
      return null;
    }

    _currentBannerAd?.dispose();

    final adUnitId = Platform.isAndroid
        ? MonetizationConstants.androidBannerId
        : MonetizationConstants.iosBannerId;

    _currentBannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Banner ad loaded');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner ad failed to load: $error');
          ad.dispose();
          _currentBannerAd = null;
          onAdFailedToLoad?.call();
        },
        onAdOpened: (ad) {
          debugPrint('[AdService] Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('[AdService] Banner ad closed');
        },
      ),
    );

    await _currentBannerAd!.load();
    return _currentBannerAd;
  }

  /// Get current banner ad
  BannerAd? get currentBannerAd => _currentBannerAd;

  /// Dispose banner ad
  void disposeBannerAd() {
    _currentBannerAd?.dispose();
    _currentBannerAd = null;
    debugPrint('[AdService] Banner ad disposed');
  }

  // ============================================================
  // Rewarded Ad
  // ============================================================

  /// Load a rewarded ad
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) {
      debugPrint('[AdService] AdMob not initialized, cannot load rewarded ad');
      return;
    }

    if (_isRewardedAdLoading || _rewardedAd != null) {
      debugPrint('[AdService] Rewarded ad already loading or loaded');
      return;
    }

    _isRewardedAdLoading = true;

    final adUnitId = Platform.isAndroid
        ? MonetizationConstants.androidRewardedId
        : MonetizationConstants.iosRewardedId;

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] Rewarded ad loaded');
            _rewardedAd = ad;
            _isRewardedAdLoading = false;

            // Set full screen content callback
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('[AdService] Rewarded ad showed full screen');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('[AdService] Rewarded ad dismissed');
                ad.dispose();
                _rewardedAd = null;
                // Preload next ad
                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdService] Rewarded ad failed to show: $error');
                ad.dispose();
                _rewardedAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Rewarded ad failed to load: $error');
            _isRewardedAdLoading = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] Error loading rewarded ad: $e');
      _isRewardedAdLoading = false;
    }
  }

  /// Show rewarded ad
  /// Returns true if user earned reward, false otherwise
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded ad not ready');
      return false;
    }

    // Use Completer to wait for the reward callback
    final completer = Completer<bool>();

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
            '[AdService] User earned reward: ${reward.amount} ${reward.type}',
          );
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
      
      // Wait for the ad to be dismissed or reward to be earned
      // Timeout after 60 seconds in case something goes wrong
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('[AdService] Reward callback timeout');
          return false;
        },
      );
      
      return result;
    } catch (e) {
      debugPrint('[AdService] Error showing rewarded ad: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Check if rewarded ad is loading
  bool get isRewardedAdLoading => _isRewardedAdLoading;

  /// Dispose rewarded ad
  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoading = false;
    debugPrint('[AdService] Rewarded ad disposed');
  }

  // ============================================================
  // Cleanup
  // ============================================================

  /// Dispose all ads
  void dispose() {
    disposeBannerAd();
    disposeRewardedAd();
    debugPrint('[AdService] All ads disposed');
  }
}
