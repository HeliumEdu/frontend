import 'package:flutter/material.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// Asks, after signing in with [signedInWith], whether to link a provider
/// that sign-in removed. Can't be dismissed without choosing.
RelinkProviderPrompt oauthRelinkPrompt(
  BuildContext context, {
  required OAuthProvider signedInWith,
}) {
  return (provider) async {
    if (!context.mounted) return false;

    return showConfirmActionDialog(
      context: context,
      title: 'Link $provider?',
      message:
          'Signing in with ${signedInWith.label} removed $provider from your '
          'account. Link it so both keep working?',
      actionText: 'Link $provider',
      cancelText: "Don't link",
      style: ConfirmActionStyle.neutral,
      dismissible: false,
    );
  };
}

/// Shows, in turn, which providers [state]'s sign-in linked and which it
/// didn't.
void showLinkOutcomeSnackBars(BuildContext context, AuthLoggedIn state) {
  var clearSnackBar = true;
  for (final provider in state.linkedProviders) {
    SnackBarHelper.show(
      context,
      '$provider is now linked to your account.',
      clearSnackBar: clearSnackBar,
      useRootMessenger: true,
    );
    clearSnackBar = false;
  }
  for (final provider in state.notLinkedProviders) {
    SnackBarHelper.show(
      context,
      providerNotLinkedMessage(provider),
      type: SnackType.info,
      seconds: 10,
      clearSnackBar: clearSnackBar,
      useRootMessenger: true,
    );
    clearSnackBar = false;
  }
}

String providerNotLinkedMessage(String provider) =>
    "$provider wasn't linked. Sign in with $provider any time to link it "
    'again.';
