import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/presentation/ui/components/hover_tap_target.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// The signed-in account's email, read-only, with a badge for each sign-in
/// provider (Google, Apple, Microsoft) linked to it. With
/// [onManageProviders], the badges are one button that calls it.
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
    return LabelAndTextFormField(
      initialValue: email,
      keyboardType: TextInputType.emailAddress,
      readOnly: true,
      prefixIcon: Icons.email_outlined,
      suffixIcon: oauthProviders.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildBadges(context),
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
            OAuthProviderBadge(provider: provider),
          ],
      ],
    );

    final onManageProviders = this.onManageProviders;
    if (onManageProviders == null) return badges;

    return Semantics(
      button: true,
      label: 'Manage sign-in methods',
      child: HoverTapTarget(
        onTap: onManageProviders,
        color: context.colorScheme.primary,
        tooltip: 'Manage sign-in methods',
        child: badges,
      ),
    );
  }
}

/// The mini sign-in button for an OAuth [provider], shown as a badge: it
/// takes no taps itself.
class OAuthProviderBadge extends StatelessWidget {
  final OAuthProvider provider;

  const OAuthProviderBadge({super.key, required this.provider});

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
