import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/google_account_store.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';

class _GoogleAccountConfirmSheet extends StatelessWidget {
  final RememberedGoogleAccount account;

  const _GoogleAccountConfirmSheet({required this.account});

  @override
  Widget build(BuildContext context) {
    final hasName = account.displayName?.isNotEmpty ?? false;
    final label = hasName ? account.displayName! : account.email;
    final initial = label[0].toUpperCase();

    return Material(
      color: context.colorScheme.surface,
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
                  backgroundImage: account.photoUrl != null
                      ? NetworkImage(account.photoUrl!)
                      : null,
                  child: account.photoUrl == null
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
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Feedback.forTap(context);
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Not you? Use a different account',
                style: AppStyles.formText(
                  context,
                ).copyWith(color: context.colorScheme.primary),
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
Future<bool?> showGoogleAccountConfirmSheet({
  required BuildContext parentContext,
  required RememberedGoogleAccount account,
}) {
  return showModalBottomSheet<bool>(
    context: parentContext,
    backgroundColor: parentContext.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return _GoogleAccountConfirmSheet(account: account);
    },
  );
}
