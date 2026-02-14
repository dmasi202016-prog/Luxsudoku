import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized.');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService has not been initialized.');
});
