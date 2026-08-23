import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which OAuth provider was last used to sign in to Helium on
/// this device, purely to highlight the matching button on the login screen.
/// The provider name is non-sensitive, so it lives in plain
/// `SharedPreferences` rather than secure storage - and under a key kept out
/// of `PrefService`'s allow-list, so `PrefService().clear()` (every Helium
/// logout) can't wipe it. The highlight matters most right after logging out.
class LastOAuthProviderStore {
  static const String _key = 'last_oauth_provider';

  SharedPreferencesAsync? _prefsOverride;
  SharedPreferencesAsync get _prefs =>
      _prefsOverride ??= SharedPreferencesAsync();

  static LastOAuthProviderStore _instance =
      LastOAuthProviderStore._internal();

  factory LastOAuthProviderStore() => _instance;

  LastOAuthProviderStore._internal();

  @visibleForTesting
  LastOAuthProviderStore.forTesting({
    required SharedPreferencesAsync prefs,
  }) : _prefsOverride = prefs;

  @visibleForTesting
  static void resetForTesting() {
    _instance = LastOAuthProviderStore._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(LastOAuthProviderStore instance) {
    _instance = instance;
  }

  Future<String?> getLastUsedProvider() async {
    try {
      return await _prefs.getString(_key);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastUsedProvider(String provider) {
    return _prefs.setString(_key, provider);
  }

  Future<void> clearLastUsedProvider() => _prefs.remove(_key);
}
