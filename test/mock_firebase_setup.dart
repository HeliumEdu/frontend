import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_firebase_service.dart';

Future<void> mockFirebaseInitialiseApp() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();
  await Firebase.initializeApp();
}