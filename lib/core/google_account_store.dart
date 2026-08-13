// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.google_account_store');

/// The Google account that most recently signed in to Helium on this
/// device, remembered so it can be offered again without a fresh
/// interactive Google auth round trip.
@immutable
class RememberedGoogleAccount {
  final String googleUserId;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const RememberedGoogleAccount({
    required this.googleUserId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory RememberedGoogleAccount.fromJson(Map<String, dynamic> json) {
    return RememberedGoogleAccount(
      googleUserId: json['googleUserId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'googleUserId': googleUserId,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
  };
}

/// Remembers the Google account that most recently signed in to Helium on
/// this device (iOS only; see `OAuthSignInService`) - display metadata only,
/// tokens stay in GIDSignIn's own Keychain cache. `accountName`/`publicKey`
/// give it its own storage namespace so `PrefService().clear()` (every
/// Helium logout) can't wipe it.
class GoogleAccountStore {
  static const String _key = 'google_remembered_account';
  static const String _accountName = 'google_account_store';

  final FlutterSecureStorage _secureStorage;

  static GoogleAccountStore _instance = GoogleAccountStore._internal();

  factory GoogleAccountStore() => _instance;

  GoogleAccountStore._internal()
    : _secureStorage = const FlutterSecureStorage(
        iOptions: IOSOptions(accountName: _accountName),
        webOptions: WebOptions(publicKey: _accountName),
      );

  @visibleForTesting
  GoogleAccountStore.forTesting({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  @visibleForTesting
  static void resetForTesting() {
    _instance = GoogleAccountStore._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(GoogleAccountStore instance) {
    _instance = instance;
  }

  Future<RememberedGoogleAccount?> getRemembered() async {
    final raw = await _secureStorage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return RememberedGoogleAccount.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e, s) {
      _log.warning('Failed to decode remembered Google account', e, s);
      return null;
    }
  }

  Future<void> setRemembered(RememberedGoogleAccount account) async {
    await _secureStorage.write(
      key: _key,
      value: jsonEncode(account.toJson()),
    );
  }
}
