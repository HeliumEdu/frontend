// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:heliumapp/firebase_options.dart';

const _overrideFirebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

/// Derives the Firebase auth domain from the current web hostname, or falls
/// back to the compile-time override or the prod default for mobile.
String get firebaseAuthDomain {
  if (_overrideFirebaseAuthDomain.isNotEmpty) return _overrideFirebaseAuthDomain;

  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
      return 'auth.heliumedu.com';
    }

    // Derives auth domain from app host: app.{env.}heliumedu.com -> auth.{env.}heliumedu.com
    return host.replaceFirst('app.', 'auth.');
  }

  return 'auth.heliumedu.com';
}

FirebaseOptions firebaseOptionsWithOverrides() {
  final base = DefaultFirebaseOptions.currentPlatform;
  if (kIsWeb) {
    return base.copyWith(authDomain: firebaseAuthDomain);
  }
  return base;
}
