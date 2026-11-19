import 'dart:io'
    if (dart.library.html) 'package:heliumapp/core/platform_stub.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:heliumapp/core/google_account_store.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/last_oauth_provider_store.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.oauth_sign_in');

typedef _PendingLink = ({String providerName, AuthCredential credential, String email});

enum OAuthProvider {
  google('Google'),
  apple('Apple'),
  microsoft('Microsoft');

  final String label;

  const OAuthProvider(this.label);
}

class OAuthSignInService {
  static const linkRequiredCode = 'oauth_link_required';

  static final OAuthSignInService _instance = OAuthSignInService._internal();

  factory OAuthSignInService() => _instance;

  OAuthSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleAccountStore _googleAccountStore = GoogleAccountStore();
  final LastOAuthProviderStore _lastOAuthProviderStore = LastOAuthProviderStore();
  bool _initialized = false;
  _PendingLink? _pendingLink;
  String? _linkedProvider;

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

  /// On iOS, [onChooseAccount] confirms any remembered account first; `true`
  /// resolves silently, `false`/`null` goes interactive. Unused on Android/web.
  Future<String?> signInWithGoogle({
    Future<bool?> Function(RememberedGoogleAccount)? onChooseAccount,
  }) async {
    return _signInWithOAuth(
      OAuthProvider.google,
      onChooseGoogleAccount: onChooseAccount,
    );
  }

  Future<String?> signInWithApple() async {
    return _signInWithOAuth(OAuthProvider.apple);
  }

  Future<String?> signInWithMicrosoft() async {
    return _signInWithOAuth(OAuthProvider.microsoft);
  }

  Future<String?> _signInWithOAuth(
    OAuthProvider provider, {
    Future<bool?> Function(RememberedGoogleAccount)? onChooseGoogleAccount,
  }) async {
    final providerName = provider.label;

    _linkedProvider = null;

    try {
      _log.info(
        'Starting $providerName Sign-In flow on ${kIsWeb ? "web" : "mobile"}',
      );

      final UserCredential? userCredential;

      if (provider == OAuthProvider.google && !kIsWeb) {
        userCredential = await _signInWithGoogleMobile(
          onChooseAccount: onChooseGoogleAccount,
        );
      } else {
        userCredential = await _signInWithFirebaseAuthProvider(provider);
      }

      if (userCredential == null) {
        return null;
      }

      final String? firebaseIdToken = await userCredential.user!.getIdToken();

      if (firebaseIdToken == null) {
        _log.severe('Firebase did not provide an ID token');
        throw HeliumException(
          message: 'Sign in with $providerName failed.',
        );
      }

      await _linkPendingCredential(userCredential.user!);

      _log.info('Firebase ID token obtained successfully from $providerName Sign-In');

      await _lastOAuthProviderStore.setLastUsedProvider(provider.name);

      return firebaseIdToken;
    } on FirebaseAuthException catch (e) {
      _log.warning('FirebaseAuthException caught - code: ${e.code}');

      if (e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          // Microsoft / iOS
          e.code == 'web-context-cancelled' ||
          // Microsoft / Android
          e.code == 'web-context-canceled') {
        _log.info('$providerName Sign-In cancelled by user');
        return null;
      }
      if (e.code == 'account-exists-with-different-credential') {
        _log.info('$providerName Sign-In blocked: email already linked to another provider');
        final credential = e.credential;
        final email = e.email;
        if (credential == null || email == null) {
          throw HeliumException(
            message: 'That email is already registered with a different sign-in method. Sign in that way instead.',
          );
        }
        _pendingLink = (providerName: providerName, credential: credential, email: email);
        throw HeliumException(
          message:
              'That email is already registered with a different sign-in method. Sign in that way to link $providerName too.',
          code: linkRequiredCode,
        );
      }
      _log.warning('Firebase Auth exception: ${e.code}');
      throw HeliumException(
        message: 'Sign in with $providerName failed.',
      );
    } on FirebaseException catch (e) {
      // Reached only when Firebase failed to initialize during app boot
      _log.warning('Firebase exception: ${e.code}');
      throw HeliumException(
        message: 'Sign in with $providerName is temporarily unavailable.',
      );
    } on GoogleSignInException catch (e) {
      _log.warning('GoogleSignInException caught - code: ${e.code}');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        _log.info('$providerName Sign-In cancelled by user');
        return null;
      }
      _log.warning('Google Sign-In exception: ${e.code}');
      throw HeliumException(
        message: 'Sign in with $providerName failed.',
      );
    } catch (e, s) {
      _log.severe(
        'Unexpected error during $providerName Sign-In - type: ${e.runtimeType}',
        e,
        s,
      );

      if (e is HeliumException) {
        rethrow;
      }

      throw HeliumException(message: 'Sign in with $providerName failed.');
    }
  }

  Future<UserCredential?> _signInWithGoogleMobile({
    Future<bool?> Function(RememberedGoogleAccount)? onChooseAccount,
  }) async {
    await _ensureInitialized();

    if (Platform.isIOS) {
      return _signInWithGoogleIOS(onChooseAccount);
    }

    // Clear any stale cached credential that could cause Credential Manager to
    // attempt (and fail) a reauth of a previously-authorized account.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    return _interactiveGoogleSignIn(remember: false);
  }

  /// iOS lacks Android's Credential Manager, so `authenticate()` always does a
  /// real interactive round trip - which triggers Google's "shared data" email.
  /// Confirming the remembered account and attempting a silent reauth first
  /// avoids that, falling back to interactive only on decline or failure.
  Future<UserCredential?> _signInWithGoogleIOS(
    Future<bool?> Function(RememberedGoogleAccount)? onChooseAccount,
  ) async {
    final remembered = await _googleAccountStore.getRemembered();

    if (remembered == null || onChooseAccount == null) {
      return _interactiveGoogleSignIn();
    }

    final continueAsRemembered = await onChooseAccount(remembered);

    if (continueAsRemembered == null) {
      _log.info('Google account confirmation dismissed without a choice');
      return null;
    }

    if (!continueAsRemembered) {
      _log.info('Google account confirmation: user chose a different account');
      return _interactiveGoogleSignIn();
    }

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.attemptLightweightAuthentication();
    } catch (e, s) {
      _log.warning(
        'Lightweight Google reauth failed, falling back to interactive',
        e,
        s,
      );
      googleUser = null;
    }

    // GIDSignIn restores its single cached session, which should match the
    // offered account - fall back to interactive if it doesn't (e.g. expired).
    if (googleUser != null && googleUser.id == remembered.googleUserId) {
      _log.info(
        'Google account confirmation: lightweight reauth succeeded',
      );
      return _finishGoogleFirebaseSignIn(googleUser, remember: true);
    }

    _log.info(
      'Google account confirmation: lightweight reauth unavailable, '
      'falling back to interactive',
    );
    return _interactiveGoogleSignIn();
  }

  Future<UserCredential> _interactiveGoogleSignIn({bool remember = true}) async {
    final googleUser = await _googleSignIn.authenticate(
      scopeHint: ['email', 'profile'],
    );
    return _finishGoogleFirebaseSignIn(googleUser, remember: remember);
  }

  Future<UserCredential> _finishGoogleFirebaseSignIn(
    GoogleSignInAccount googleUser, {
    bool remember = false,
  }) async {
    _log.info('Google Sign-In successful, getting authentication details');

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      _log.severe('Google Sign-In did not provide an ID token');
      throw HeliumException(
        message: 'Sign in with Google failed.',
      );
    }

    // google_sign_in v7 only needs ID token
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    _log.info('Signing in to Firebase with Google credentials');
    final userCredential = await _firebaseAuth.signInWithCredential(
      credential,
    );

    if (remember) {
      await _googleAccountStore.setRemembered(
        RememberedGoogleAccount(
          googleUserId: googleUser.id,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
        ),
      );
    }

    return userCredential;
  }

  Future<void> _linkPendingCredential(User user) async {
    final pendingLink = _pendingLink;
    _pendingLink = null;
    if (pendingLink == null || user.email?.toLowerCase() != pendingLink.email.toLowerCase()) return;

    try {
      await user.linkWithCredential(pendingLink.credential);
      _linkedProvider = pendingLink.providerName;
      _log.info('Linked ${pendingLink.providerName} to the signed-in account');
    } on FirebaseAuthException catch (e) {
      _log.warning('Linking ${pendingLink.providerName} failed - code: ${e.code}');
    }
  }

  Future<UserCredential?> _signInWithFirebaseAuthProvider(
    OAuthProvider provider,
  ) async {
    final providerName = provider.label;
    final dynamic authProvider = _authProviderFor(provider);

    if (kIsWeb) {
      _log.info('Using Firebase Auth popup for $providerName on web');
      return await _firebaseAuth.signInWithPopup(authProvider);
    } else {
      _log.info('Using Firebase Auth for $providerName on mobile');
      return await _firebaseAuth.signInWithProvider(authProvider);
    }
  }

  dynamic _authProviderFor(OAuthProvider provider) {
    final dynamic authProvider = switch (provider) {
      OAuthProvider.google => GoogleAuthProvider(),
      OAuthProvider.apple => AppleAuthProvider(),
      OAuthProvider.microsoft => MicrosoftAuthProvider(),
    };

    if (provider == OAuthProvider.google) {
      authProvider.addScope('email');
      authProvider.addScope('profile');
      authProvider.setCustomParameters({'prompt': 'select_account'});
    } else if (provider == OAuthProvider.apple) {
      authProvider.addScope('email');
      authProvider.addScope('name');
    } else {
      authProvider.addScope('email');
      authProvider.addScope('profile');
    }

    return authProvider;
  }

  /// Links [provider] to the signed-in Firebase user through its interactive
  /// sign-in, returning a fresh Firebase ID token, or null if the user
  /// cancelled or the link failed.
  Future<String?> linkProvider(OAuthProvider provider) async {
    final user = _firebaseAuth.currentUser!;

    try {
      final dynamic authProvider = _authProviderFor(provider);
      final userCredential = kIsWeb
          ? await user.linkWithPopup(authProvider)
          : await user.linkWithProvider(authProvider);
      _log.info('Linked ${provider.label} to the signed-in account');

      return await userCredential.user!.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      _log.warning('Linking ${provider.label} failed - code: ${e.code}');
      return null;
    }
  }

  String? takeLinkedProvider() {
    final linkedProvider = _linkedProvider;
    _linkedProvider = null;
    return linkedProvider;
  }

  Future<void> signOut() async {
    _pendingLink = null;
    try {
      // Signing out of Helium shouldn't sign out of Google on iOS - clearing
      // it is what forced a full, email-triggering reauth on every login.
      if (_initialized && (kIsWeb || !Platform.isIOS)) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      _log.info('Signed out from OAuth providers and Firebase');
    } catch (e, s) {
      _log.warning('Error signing out from OAuth/Firebase', e, s);
    }
  }
}
