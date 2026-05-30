// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/firebase_options.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.oauth_sign_in');

enum OAuthProvider {
  google,
  apple,
  microsoft,
}

class OAuthSignInService {
  static final OAuthSignInService _instance = OAuthSignInService._internal();

  factory OAuthSignInService() => _instance;

  OAuthSignInService._internal();

  // Named secondary app used only for Microsoft on web. Microsoft requires
  // signInWithRedirect, whose result is stored under the authDomain the
  // Firebase auth handler uses — helium-edu.firebaseapp.com (from init.json).
  // Keeping this separate leaves the primary app's auth.heliumedu.com domain
  // untouched for Google and Apple.
  static const _microsoftWebAppName = 'microsoft-auth';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseAuth? _microsoftWebAuth;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      _log.info('Initializing Google Sign-In for web with client ID');

      await _googleSignIn.initialize(clientId: _getWebClientId());
    } else {
      // Android Credential Manager API (used by google_sign_in) requires serverClientId
      // (the web OAuth client ID) to authenticate properly; without it account reauth fails.
      await _googleSignIn.initialize(serverClientId: _getWebClientId());
    }

    _initialized = true;
    _log.info('Google Sign-In initialized for ${kIsWeb ? "web" : "mobile"}');
  }

  String _getWebClientId() {
    return '643279973445-e69crc4hlj2tp29jsrbr2o7ompl042r9.apps.googleusercontent.com';
  }

  Future<FirebaseAuth> _getMicrosoftWebAuth() async {
    if (_microsoftWebAuth != null) return _microsoftWebAuth!;
    FirebaseApp app;
    try {
      app = Firebase.app(_microsoftWebAppName);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: _microsoftWebAppName,
        options: DefaultFirebaseOptions.currentPlatform.copyWith(
          authDomain: 'helium-edu.firebaseapp.com',
        ),
      );
    }
    _microsoftWebAuth = FirebaseAuth.instanceFor(app: app);
    return _microsoftWebAuth!;
  }

  Future<String?> signInWithGoogle() async {
    return _signInWithOAuth(OAuthProvider.google);
  }

  Future<String?> signInWithApple() async {
    return _signInWithOAuth(OAuthProvider.apple);
  }

  Future<String?> signInWithMicrosoft() async {
    return _signInWithOAuth(OAuthProvider.microsoft);
  }

  Future<(String, String)?> checkRedirectResult() async {
    try {
      // Microsoft redirect uses the secondary app (helium-edu.firebaseapp.com authDomain).
      // Google and Apple use signInWithPopup and never leave a redirect result.
      final microsoftAuth = await _getMicrosoftWebAuth();
      final userCredential = await microsoftAuth.getRedirectResult();

      if (userCredential.user == null) {
        return null;
      }

      final String? firebaseIdToken = await userCredential.user!.getIdToken();
      if (firebaseIdToken == null) {
        _log.severe('No Firebase ID token in OAuth redirect result');
        return null;
      }

      final providerId = userCredential.additionalUserInfo?.providerId;
      final provider = switch (providerId) {
        'google.com' => 'google',
        'apple.com' => 'apple',
        'microsoft.com' => 'microsoft',
        _ => null,
      };

      if (provider == null) {
        _log.warning('Unknown provider in redirect result: $providerId');
        return null;
      }

      _log.info('Redirect result obtained for $provider');
      return (firebaseIdToken, provider);
    } catch (e, s) {
      _log.warning('Error checking OAuth redirect result', e, s);
      return null;
    }
  }

  Future<String?> _signInWithOAuth(OAuthProvider provider) async {
    final providerName = switch (provider) {
      OAuthProvider.google => 'Google',
      OAuthProvider.apple => 'Apple',
      OAuthProvider.microsoft => 'Microsoft',
    };

    try {
      _log.info(
        'Starting $providerName Sign-In flow on ${kIsWeb ? "web" : "mobile"}',
      );

      final UserCredential? userCredential;

      if (provider == OAuthProvider.google && !kIsWeb) {
        // Google on mobile uses the google_sign_in package
        userCredential = await _signInWithGoogleMobile();
      } else {
        // Google/Apple on web use signInWithPopup; Microsoft on web uses signInWithRedirect
      // (Microsoft's OAuth pages set COOP: same-origin, severing the popup opener chain).
      // On mobile, Apple/Microsoft use signInWithProvider.
        userCredential = await _signInWithFirebaseAuthProvider(provider);
      }

      if (userCredential == null) {
        // On web, null means signInWithRedirect was initiated and page is navigating away
        return null;
      }

      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        _log.severe('Firebase did not provide an ID token');
        throw HeliumException(
          message: 'Sign-in with $providerName failed.',
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
        message: 'Sign-in with $providerName failed.',
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
        message: 'Sign-in with $providerName failed.',
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

      throw HeliumException(message: 'Sign-in with $providerName failed.');
    }
  }

  Future<UserCredential> _signInWithGoogleMobile() async {
    await _ensureInitialized();

    // Clear any stale cached credential that could cause Credential Manager to
    // attempt (and fail) a reauth of a previously-authorized account.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
      scopeHint: ['email', 'profile'],
    );

    _log.info('Google Sign-In successful, getting authentication details');

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      _log.severe('Google Sign-In did not provide an ID token');
      throw HeliumException(
        message: 'Sign-in with Google failed.',
      );
    }

    // google_sign_in v7 only needs ID token
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    _log.info('Signing in to Firebase with Google credentials');
    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithFirebaseAuthProvider(
    OAuthProvider provider,
  ) async {
    final providerName = switch (provider) {
      OAuthProvider.google => 'Google',
      OAuthProvider.apple => 'Apple',
      OAuthProvider.microsoft => 'Microsoft',
    };

    final dynamic authProvider = switch (provider) {
      OAuthProvider.google => GoogleAuthProvider(),
      OAuthProvider.apple => AppleAuthProvider(),
      OAuthProvider.microsoft => MicrosoftAuthProvider(),
    };

    if (provider == OAuthProvider.google) {
      authProvider.addScope('email');
      authProvider.addScope('profile');
    } else if (provider == OAuthProvider.apple) {
      authProvider.addScope('email');
      authProvider.addScope('name');
    } else {
      authProvider.addScope('email');
      authProvider.addScope('profile');
    }

    if (kIsWeb && provider == OAuthProvider.microsoft) {
      // Microsoft's OAuth pages set COOP: same-origin, which severs the opener
      // chain required by signInWithPopup. Redirect flow avoids this entirely.
      // Uses the secondary Firebase app so the redirect result is stored under
      // helium-edu.firebaseapp.com — matching the authDomain the handler's
      // init.json advertises — without affecting Google/Apple's auth domain.
      _log.info('Using Firebase Auth redirect for $providerName on web');
      final microsoftAuth = await _getMicrosoftWebAuth();
      await microsoftAuth.signInWithRedirect(authProvider);
      return null; // Page navigates away to OAuth provider; unreachable in practice
    } else if (kIsWeb) {
      _log.info('Using Firebase Auth popup for $providerName on web');
      return await _firebaseAuth.signInWithPopup(authProvider);
    } else {
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
      if (_microsoftWebAuth != null) {
        await _microsoftWebAuth!.signOut();
      }
      _log.info('Signed out from OAuth providers and Firebase');
    } catch (e, s) {
      _log.warning('Error signing out from OAuth/Firebase', e, s);
    }
  }

  bool get isSignedIn {
    return _firebaseAuth.currentUser != null;
  }
}
