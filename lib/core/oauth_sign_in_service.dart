// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.oauth_sign_in');

enum OAuthProvider {
  google,
  apple,
}

class OAuthSignInService {
  static final OAuthSignInService _instance = OAuthSignInService._internal();

  factory OAuthSignInService() => _instance;

  OAuthSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      _log.info('Initializing Google Sign-In for web with client ID');

      await _googleSignIn.initialize(clientId: _getWebClientId());
    } else {
      // Mobile platforms don't need explicit clientId
      await _googleSignIn.initialize();
    }

    _initialized = true;
    _log.info('Google Sign-In initialized for ${kIsWeb ? "web" : "mobile"}');
  }

  String? _getWebClientId() {
    if (!kIsWeb) return null;

    return '643279973445-e69crc4hlj2tp29jsrbr2o7ompl042r9.apps.googleusercontent.com';
  }

  Future<String?> signInWithGoogle() async {
    return _signInWithOAuth(OAuthProvider.google);
  }

  Future<String?> signInWithApple() async {
    return _signInWithOAuth(OAuthProvider.apple);
  }

  Future<String?> _signInWithOAuth(OAuthProvider provider) async {
    final providerName = provider == OAuthProvider.google ? 'Google' : 'Apple';

    try {
      _log.info(
        'Starting $providerName Sign-In flow on ${kIsWeb ? "web" : "mobile"}',
      );

      final UserCredential userCredential;

      if (provider == OAuthProvider.google && !kIsWeb) {
        // Google on mobile uses the google_sign_in package
        userCredential = await _signInWithGoogleMobile();
      } else {
        // Apple (all platforms) and Google on web use Firebase Auth directly
        userCredential = await _signInWithFirebaseAuthProvider(provider);
      }

      // Get the Firebase ID token - this is what we send to the backend
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        _log.severe('Firebase did not provide an ID token');
        throw HeliumException(
          message: '$providerName Sign-In failed: No ID token received',
        );
      }

      _log.info('Firebase ID token obtained successfully from $providerName Sign-In');

      return firebaseIdToken;
    } on FirebaseAuthException catch (e) {
      _log.warning(
        'FirebaseAuthException caught - code: ${e.code}, message: ${e.message}',
      );

      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        _log.info('$providerName Sign-In cancelled by user');
        return null;
      }
      _log.warning('Firebase Auth exception: ${e.code} - ${e.message}');
      throw HeliumException(
        message: '$providerName Sign-In failed: ${e.message ?? e.code}',
      );
    } on GoogleSignInException catch (e) {
      _log.warning(
        'GoogleSignInException caught - code: ${e.code}, description: ${e.description}',
      );

      if (e.code == GoogleSignInExceptionCode.canceled) {
        _log.info('$providerName Sign-In cancelled by user');
        return null;
      }
      _log.warning('Google Sign-In exception: ${e.code} - ${e.description}');
      throw HeliumException(
        message: '$providerName Sign-In failed: ${e.description ?? e.code.name}',
      );
    } catch (e, s) {
      _log.severe(
        'Unexpected error during $providerName Sign-In - type: ${e.runtimeType}, error: $e',
        e,
        s,
      );

      if (e is HeliumException) {
        rethrow;
      }

      throw HeliumException(message: '$providerName Sign-In failed: ${e.toString()}');
    }
  }

  Future<UserCredential> _signInWithGoogleMobile() async {
    await _ensureInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
      scopeHint: ['email', 'profile'],
    );

    _log.info('Google Sign-In successful, getting authentication details');

    // Obtain the auth details from the Google Sign-In
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      _log.severe('Google Sign-In did not provide an ID token');
      throw HeliumException(
        message: 'Google Sign-In failed: No ID token received',
      );
    }

    // Create a new credential for Firebase Auth (only needs ID token in v7)
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    _log.info('Signing in to Firebase with Google credentials');

    // Sign in to Firebase with the Google credentials
    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> _signInWithFirebaseAuthProvider(
    OAuthProvider provider,
  ) async {
    final providerName = provider == OAuthProvider.google ? 'Google' : 'Apple';

    // Create the appropriate auth provider
    final dynamic authProvider = provider == OAuthProvider.google
        ? GoogleAuthProvider()
        : AppleAuthProvider();

    // Add scopes
    if (provider == OAuthProvider.google) {
      authProvider.addScope('email');
      authProvider.addScope('profile');
    } else {
      authProvider.addScope('email');
      authProvider.addScope('name');
    }

    if (kIsWeb) {
      // On web, use popup
      _log.info('Using Firebase Auth popup for $providerName on web');
      return await _firebaseAuth.signInWithPopup(authProvider);
    } else {
      // On mobile, use provider (Apple only - Google mobile uses different path)
      _log.info('Using Firebase Auth for $providerName on mobile');
      return await _firebaseAuth.signInWithProvider(authProvider);
    }
  }

  Future<void> signOut() async {
    try {
      if (_initialized) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      _log.info('Signed out from OAuth providers and Firebase');
    } catch (e, s) {
      _log.warning('Error signing out from OAuth/Firebase', e, s);
    }
  }

  bool get isSignedIn {
    return _firebaseAuth.currentUser != null;
  }
}
