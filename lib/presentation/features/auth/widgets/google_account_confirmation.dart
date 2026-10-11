import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/google_account_store.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_bottom_sheet.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/google_avatar_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class _GoogleAccountConfirmContent extends StatelessWidget {
  final RememberedGoogleAccount account;

  const _GoogleAccountConfirmContent({required this.account});

  @override
  Widget build(BuildContext context) {
    final hasName = account.displayName?.isNotEmpty ?? false;
    final photoUrl = GoogleAvatar.sizedUrl(account.photoUrl);
    final label = hasName ? account.displayName! : account.email;
    final initial = label[0].toUpperCase();

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.colorScheme.primary,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          initial,
                          style: AppStyles.pageTitle(
                            context,
                          ).copyWith(color: context.colorScheme.onPrimary),
                        )
                      : null,
                ),
                // An email alone doesn't say which provider it's signed in via.
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logos/google_light.png',
                      package: 'sign_in_button',
                      height: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: AppStyles.pageTitle(context)),
            if (hasName)
              Text(
                account.email,
                style: AppStyles.smallSecondaryText(context),
              ),
            const SizedBox(height: 16),
            HeliumElevatedButton(
              buttonText: 'Continue as $label',
              onPressed: () {
                Feedback.forTap(context);
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: HeliumElevatedButton.outlinedStyle(context.colorScheme),
                onPressed: () {
                  Feedback.forTap(context);
                  Navigator.of(context).pop(false);
                },
                child: const Text('Not you? Use a different account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirms the Google account remembered from a previous sign-in (iOS only
/// - see `OAuthSignInService`); resolves true/false/null as in `GoogleLoginEvent`.
/// Mobile layouts get a bottom sheet, wider layouts a centered dialog.
Future<bool?> showGoogleAccountConfirmation({
  required BuildContext parentContext,
  required RememberedGoogleAccount account,
}) {
  if (Responsive.isMobile(parentContext)) {
    return _showConfirmSheet(parentContext, account);
  }
  return _showConfirmDialog(parentContext, account);
}

Future<bool?> _showConfirmDialog(
  BuildContext parentContext,
  RememberedGoogleAccount account,
) {
  return showDialog<bool>(
    context: parentContext,
    useRootNavigator: true,
    builder: (BuildContext dialogContext) {
      return Dialog(
        child: SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: _GoogleAccountConfirmContent(account: account),
        ),
      );
    },
  );
}

Future<bool?> _showConfirmSheet(
  BuildContext parentContext,
  RememberedGoogleAccount account,
) {
  return showHeliumBottomSheet<bool>(
    context: parentContext,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        top: false,
        child: _GoogleAccountConfirmContent(account: account),
      );
    },
  );
}
