import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/presentation/ui/components/account_email_field.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/utils/app_style.dart';

/// Opens the account's linked sign-in [providers] as a list, each with a
/// button to remove it, anchored to [anchorContext] on larger screens or as a
/// bottom sheet on phones. [onRemove] runs after the menu closes.
Future<void> showSignInMethodsMenu(
  BuildContext context, {
  required BuildContext anchorContext,
  required List<OAuthProvider> providers,
  required void Function(OAuthProvider provider) onRemove,
}) async {
  OAuthProvider? removed;
  await showHeliumMenu(
    context: context,
    anchorContext: anchorContext,
    builder: (menuContext, _) => _SignInMethodsMenuContent(
      providers: providers,
      onRemove: (provider) {
        removed = provider;
        Navigator.of(menuContext).pop();
      },
    ),
  );

  final provider = removed;
  if (provider != null) onRemove(provider);
}

class _SignInMethodsMenuContent extends StatelessWidget {
  final List<OAuthProvider> providers;
  final void Function(OAuthProvider provider) onRemove;

  const _SignInMethodsMenuContent({
    required this.providers,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return HeliumMenuContent(
      width: HeliumMenuContent.listWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeliumMenuTitle(title: 'Sign-in Methods'),
          const SizedBox(height: 8),
          for (final provider in providers)
            _buildProviderRow(context, provider),
        ],
      ),
    );
  }

  Widget _buildProviderRow(BuildContext context, OAuthProvider provider) {
    return HeliumMenuItemRow.label(
      label: Row(
        children: [
          OAuthProviderBadge(provider: provider),
          const SizedBox(width: 12),
          Text(provider.label, style: AppStyles.standardBodyText(context)),
        ],
      ),
      action: HeliumIconButton(
        onPressed: () => onRemove(provider),
        icon: Icons.link_off,
        tooltip: 'Remove ${provider.label}',
        color: context.colorScheme.error,
      ),
    );
  }
}
