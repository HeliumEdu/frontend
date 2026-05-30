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

/// Returns the Firebase auth domain, defaulting to the Firebase-managed
/// default domain required for signInWithRedirect to function correctly.
String get firebaseAuthDomain {
  if (_overrideFirebaseAuthDomain.isNotEmpty) return _overrideFirebaseAuthDomain;
  return 'helium-edu.firebaseapp.com';
}

FirebaseOptions firebaseOptionsWithOverrides() {
  final base = DefaultFirebaseOptions.currentPlatform;
  if (kIsWeb) {
    return base.copyWith(authDomain: firebaseAuthDomain);
  }
  return base;
}
