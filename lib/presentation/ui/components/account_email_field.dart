import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// The signed-in account's email, read-only, with a badge for each sign-in
/// provider (Google, Apple, Microsoft) linked to it.
class AccountEmailField extends StatelessWidget {
  final String email;
  final List<String> oauthProviders;

  const AccountEmailField({
    super.key,
    required this.email,
    this.oauthProviders = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LabelAndTextFormField(
      initialValue: email,
      keyboardType: TextInputType.emailAddress,
      readOnly: true,
      prefixIcon: Icons.email_outlined,
      inlineSuffix: oauthProviders.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final provider in oauthProviders)
                    if (_buildProviderBadge(provider) case final badge?) ...[
                      const SizedBox(width: 6),
                      Theme(
                        data: Theme.of(context).copyWith(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: badge,
                      ),
                    ],
                ],
              ),
            ),
    );
  }

  Widget? _buildProviderBadge(String provider) {
    // Google's SignInButton asserts mini != true; use SignInButtonBuilder
    // directly with the package's own Google G image asset to match the mini
    // style that Apple and Microsoft render via SignInButton(mini: true).
    if (provider == 'google') {
      return IgnorePointer(
        child: SignInButtonBuilder(
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
      );
    }
    final button = switch (provider) {
      'apple' => Buttons.apple,
      'microsoft' => Buttons.microsoft,
      _ => null,
    };
    if (button == null) return null;
    return IgnorePointer(
      child: SignInButton(button, mini: true, onPressed: () {}),
    );
  }
}
