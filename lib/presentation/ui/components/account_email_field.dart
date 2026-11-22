import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// The signed-in account's email, read-only, with a badge for each sign-in
/// provider (Google, Apple, Microsoft) linked to it, set off from the email
/// in a strip of the editable-field fill. With [onManageProviders], the
/// badges are one button that calls it.
class AccountEmailField extends StatelessWidget {
  final String email;
  final List<String> oauthProviders;
  final void Function(BuildContext anchorContext)? onManageProviders;

  const AccountEmailField({
    super.key,
    required this.email,
    this.oauthProviders = const [],
    this.onManageProviders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
          width: AppStyles.formFieldBorderWidth,
        ),
        borderRadius: BorderRadius.circular(AppStyles.formFieldBorderRadius),
      ),
      child: Row(
        children: [
          Expanded(child: _buildEmail(context)),
          if (oauthProviders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildBadges(context),
            ),
        ],
      ),
    );
  }

  Widget _buildEmail(BuildContext context) {
    final edge = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppStyles.formFieldBorderRadius - AppStyles.formFieldBorderWidth,
      ),
      borderSide: BorderSide.none,
    );
    return TextFormField(
      initialValue: email,
      readOnly: true,
      keyboardType: TextInputType.emailAddress,
      style: AppStyles.formText(context),
      textAlignVertical: TextAlignVertical.center,
      decoration: AppStyles.formFieldDecoration(context, readOnly: true)
          .copyWith(
            prefixIcon: Icon(
              Icons.email_outlined,
              color: context.colorScheme.onSurface.withValues(
                alpha: AppStyles.mutedIconAlpha,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: kMinInteractiveDimension,
              minHeight: AppStyles.formFieldInnerHeight,
              maxHeight: AppStyles.formFieldInnerHeight,
            ),
            constraints: const BoxConstraints.tightFor(
              height: AppStyles.formFieldInnerHeight,
            ),
            border: edge,
            enabledBorder: edge,
            focusedBorder: edge,
            disabledBorder: edge,
          ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    final badges = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final name in oauthProviders)
          if (OAuthProvider.values.asNameMap()[name] case final provider?) ...[
            const SizedBox(width: 6),
            _OAuthProviderBadge(provider: provider),
          ],
      ],
    );

    final onManageProviders = this.onManageProviders;
    if (onManageProviders == null) return badges;

    return Semantics(
      button: true,
      label: 'Manage sign-in methods',
      child: Tooltip(
        message: 'Manage sign-in methods',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Builder(
            builder: (anchorContext) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onManageProviders(anchorContext),
              child: badges,
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthProviderBadge extends StatelessWidget {
  final OAuthProvider provider;

  const _OAuthProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: IgnorePointer(child: _buildButton()),
    );
  }

  Widget _buildButton() {
    return switch (provider) {
      // Google's SignInButton asserts mini != true; use SignInButtonBuilder
      // directly with the package's own Google G image asset to match the
      // mini style that Apple and Microsoft render via SignInButton(mini: true).
      OAuthProvider.google => SignInButtonBuilder(
        text: '',
        mini: true,
        backgroundColor: Colors.white,
        onPressed: () {},
        image: Image.asset(
          'assets/logos/google_light.png',
          package: 'sign_in_button',
          height: 24,
        ),
      ),
      OAuthProvider.apple => SignInButton(
        Buttons.apple,
        mini: true,
        onPressed: () {},
      ),
      OAuthProvider.microsoft => SignInButton(
        Buttons.microsoft,
        mini: true,
        onPressed: () {},
      ),
    };
  }
}
