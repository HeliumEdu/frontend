// Utilities for deriving Firebase configuration that can change per build.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

const _environmentPrefix = String.fromEnvironment(
  'ENVIRONMENT_PREFIX',
  defaultValue: '',
);

const _defaultFirebaseAuthDomain = 'auth.${_environmentPrefix}heliumedu.com';

/// Dart-define override that can be used when building/testing different envs.
const firebaseAuthDomain = String.fromEnvironment(
  'FIREBASE_AUTH_DOMAIN',
  defaultValue: _defaultFirebaseAuthDomain,
);

FirebaseOptions firebaseOptionsWithOverrides() {
  final base = DefaultFirebaseOptions.currentPlatform;
  if (kIsWeb) {
    return base.copyWith(authDomain: firebaseAuthDomain);
  }
  return base;
}
