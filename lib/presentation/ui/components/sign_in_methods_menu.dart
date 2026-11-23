import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
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
          _buildProviderLogo(context, provider),
          const SizedBox(width: 12),
          Text(provider.label, style: AppStyles.standardBodyText(context)),
        ],
      ),
      action: HeliumIconButton(
        onPressed: () => onRemove(provider),
        icon: Icons.link_off,
        label: 'Remove ${provider.label}',
        color: context.colorScheme.error,
      ),
    );
  }

  Widget _buildProviderLogo(BuildContext context, OAuthProvider provider) {
    return switch (provider) {
      OAuthProvider.google => Image.asset(
        'assets/logos/google_light.png',
        package: 'sign_in_button',
        width: 20,
        height: 20,
      ),
      OAuthProvider.apple => FaIcon(
        FontAwesomeIcons.apple,
        size: 20,
        color: context.colorScheme.onSurface,
      ),
      OAuthProvider.microsoft => FaIcon(
        FontAwesomeIcons.microsoft,
        size: 20,
        color: context.colorScheme.onSurface,
      ),
    };
  }
}
