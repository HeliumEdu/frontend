// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _log = Logger('core.app_version');

/// Resolves and caches the running app's version once at startup so it can be
/// read synchronously (e.g. by the force-update gate on every base page).
class AppVersionService {
  String? _version;

  static AppVersionService _instance = AppVersionService._internal();

  factory AppVersionService() => _instance;

  AppVersionService._internal();

  @visibleForTesting
  AppVersionService.forTesting({String? version}) : _version = version;

  @visibleForTesting
  static void setInstanceForTesting(AppVersionService instance) {
    _instance = instance;
  }

  /// The semver string (e.g. `3.6.18`), without build metadata. Null until
  /// [init] completes or if resolution failed.
  String? get version => _version;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
    } catch (e) {
      _log.warning('Failed to resolve app version', e);
    }
  }
}
