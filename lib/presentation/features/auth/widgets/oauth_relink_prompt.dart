import 'package:flutter/material.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// Asks, after signing in with [signedInWith], whether to link a provider
/// that sign-in removed, or one it couldn't link on its own. Can't be
/// dismissed without choosing.
RelinkProviderPrompt oauthRelinkPrompt(
  BuildContext context, {
  required OAuthProvider signedInWith,
}) {
  return (provider, {required removed}) async {
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context);
    return showConfirmActionDialog(
      context: context,
      title: l10n.oauthRelinkTitle(provider),
      message: removed
          ? l10n.oauthRelinkRemovedMessage(provider, signedInWith.label)
          : l10n.oauthRelinkPendingMessage(provider),
      actionText: l10n.oauthRelinkButton(provider),
      cancelText: l10n.oauthRelinkDeclineButton,
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
      AppLocalizations.of(context).oauthRelinkLinkedMessage(provider),
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

@visibleForTesting
String providerNotLinkedMessage(String provider) =>
    LocaleNotifier().localizations.oauthRelinkNotLinkedMessage(provider);
