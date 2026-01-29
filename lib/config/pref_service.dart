// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  FlutterSecureStorage? _secureStorageOverride;
  FlutterSecureStorage get _secureStorage =>
      _secureStorageOverride ?? const FlutterSecureStorage();

  SharedPreferencesWithCache? _sharedStorage;

  bool _isInitialized = false;

  static PrefService _instance = PrefService._internal();

  factory PrefService() => _instance;

  PrefService._internal();

  @visibleForTesting
  PrefService.forTesting({
    required FlutterSecureStorage secureStorage,
    required SharedPreferencesWithCache sharedStorage,
  })  : _secureStorageOverride = secureStorage,
        _sharedStorage = sharedStorage,
        _isInitialized = true;

  @visibleForTesting
  static void resetForTesting() {
    _instance = PrefService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(PrefService instance) {
    _instance = instance;
  }

  Future<void> init() async {
    if (isInitialized) return;

    _sharedStorage = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );

    _isInitialized = true;
  }

  // Getters
  bool get isInitialized => _isInitialized;

  List<String>? getStringList(String key) {
    return _sharedStorage?.getStringList(key);
  }

  String? getString(String key) {
    return _sharedStorage?.getString(key);
  }

  int? getInt(String key) {
    return _sharedStorage?.getInt(key);
  }

  bool? getBool(String key) {
    return _sharedStorage?.getBool(key);
  }

  Future<void>? setStringList(String key, List<String> value) {
    return _sharedStorage?.setStringList(key, value);
  }

  Future<void>? setString(String key, String value) {
    return _sharedStorage?.setString(key, value);
  }

  Future<void>? setInt(String key, int value) {
    return _sharedStorage?.setInt(key, value);
  }

  Future<void>? setBool(String key, bool value) {
    return _sharedStorage?.setBool(key, value);
  }

  Future<String?> getSecure(String key) {
    return _secureStorage.read(key: key);
  }

  Future<void>? setSecure(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  Future<void>? deleteSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  Future<List<void>>? clear() async {
    return Future.wait([_sharedStorage!.clear(), _secureStorage.deleteAll()]);
  }
}
