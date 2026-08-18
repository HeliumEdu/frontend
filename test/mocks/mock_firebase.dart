import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

/// Sets up Firebase mocks for testing.
///
/// Call this in setUpAll() before running widget tests that require Firebase.
void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

/// Initializes Firebase for testing with mocks.
///
/// This is a convenience function that combines test binding initialization,
/// Firebase mock setup, and Firebase initialization.
Future<void> mockFirebaseInitializeApp() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();
  await Firebase.initializeApp();
}
