// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers which OAuth provider was last used to sign in to Helium on
/// this device, purely to highlight the matching button on the login screen.
/// `accountName`/`publicKey` give it its own storage namespace so
/// `PrefService().clear()` (every Helium logout) can't wipe it - the
/// highlight matters most right after logging out.
class LastOAuthProviderStore {
  static const String _key = 'last_oauth_provider';
  static const String _accountName = 'last_oauth_provider_store';

  final FlutterSecureStorage _secureStorage;

  static LastOAuthProviderStore _instance =
      LastOAuthProviderStore._internal();

  factory LastOAuthProviderStore() => _instance;

  LastOAuthProviderStore._internal()
    : _secureStorage = const FlutterSecureStorage(
        iOptions: IOSOptions(accountName: _accountName),
        webOptions: WebOptions(publicKey: _accountName),
      );

  @visibleForTesting
  LastOAuthProviderStore.forTesting({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  @visibleForTesting
  static void resetForTesting() {
    _instance = LastOAuthProviderStore._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(LastOAuthProviderStore instance) {
    _instance = instance;
  }

  Future<String?> getLastUsedProvider() => _secureStorage.read(key: _key);

  Future<void> setLastUsedProvider(String provider) {
    return _secureStorage.write(key: _key, value: provider);
  }

  Future<void> clearLastUsedProvider() => _secureStorage.delete(key: _key);
}
