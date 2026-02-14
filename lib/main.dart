import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/ad_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/iap_service.dart';
import 'data/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final storageService = await StorageService.init(prefs);
  
  // Initialize audio service (but don't auto-play due to web autoplay policy)
  // Audio will start when user clicks "Start Game" button
  try {
    debugPrint('[main] Initializing AudioService...');
    await AudioService.instance.initialize();
    debugPrint('[main] AudioService initialized successfully');
  } catch (e) {
    debugPrint('[main] AudioService initialization failed: $e');
    // Silently fail if audio not available
  }

  // Initialize AdMob
  try {
    debugPrint('[main] Initializing AdService...');
    await AdService.instance.initialize();
    debugPrint('[main] AdService initialized successfully');
    
    // Preload rewarded ad
    await AdService.instance.loadRewardedAd();
  } catch (e) {
    debugPrint('[main] AdService initialization failed: $e');
    // Silently fail if ads not available
  }

  // Initialize In-App Purchase
  try {
    debugPrint('[main] Initializing IAPService...');
    await IAPService.instance.initialize();
    debugPrint('[main] IAPService initialized successfully');
  } catch (e) {
    debugPrint('[main] IAPService initialization failed: $e');
    // Silently fail if IAP not available
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const SudokuApp(),
    ),
  );
}
