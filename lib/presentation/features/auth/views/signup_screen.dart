import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/oauth_sign_in_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';

import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/auth/controllers/credentials_form_controller.dart';
import 'package:heliumapp/presentation/features/auth/controllers/signup_form_controller.dart';
import 'package:heliumapp/presentation/features/auth/widgets/oauth_relink_prompt.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_password_field.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/layout/unauthenticated_scaffold.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/linked_text_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class SignupScreen extends StatefulWidget {
  static const String signUpButtonKey = 'signup_sign_up_button';

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends BasePageScreenState<SignupScreen> {
  static const _oauthButtonWidth = 250.0;
  static const _oauthButtonHeight = 40.0;

  @override
  String get screenTitle => AppLocalizations.of(context).signUpTitle;

  @override
  bool get isAuthenticatedScreen => false;

  final SignupFormController _formController = SignupFormController();
  String? _nextRoute;
  bool _isOAuthLoading = false;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final Future<void> _localeDetection;

  @override
  void initState() {
    super.initState();

    // Defer until after initState so GoRouterState is available; it requires an
    // attached BuildContext
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _nextRoute = NextRoute.read(GoRouterState.of(context).uri.queryParameters);
    });

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => UrlHelpers.launchWebUrl(AppConstants.termsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => UrlHelpers.launchWebUrl(AppConstants.privacyUrl);

    _localeDetection = _formController.detectLocale();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedIn) {
            final wasOAuthFlow = _isOAuthLoading;
            setState(() {
              _isOAuthLoading = false;
              isSubmitting = true;
            });

            if (!context.mounted) return;

            showLinkOutcomeSnackBars(context, state);

            // Check if account setup is complete. Default to false for OAuth
            // (new users won't have the pref yet, and the setup screen handles
            // the already-complete case by redirecting immediately).
            final setupStateCode =
                PrefService().getInt(SettingsPrefKey.setupState.key);
            final isSetupComplete = setupStateCode == null
                ? !wasOAuthFlow
                : setupStateCode == SetupState.complete.code;

            if (!isSetupComplete) {
              context.replace(
                NextRoute.carry(AppRoute.setupAccountScreen, _nextRoute),
              );
            } else {
              // Redirect to intended destination or default to planner
              context.replace(_nextRoute ?? AppRoute.plannerScreen);
            }
          } else if (state is AuthRegistered) {
            TextInput.finishAutofillContext();
            showSnackBar(
              context,
              AppLocalizations.of(context).signUpVerificationSentMessage,
              seconds: 6,
            );

            final email = state.email;
            if (email == null || email.isEmpty) {
              showSnackBar(
                context,
                AppLocalizations.of(context).signUpEmailUnavailableMessage,
                type: SnackType.error,
                seconds: 6,
              );
              return;
            }

            if (!context.mounted) return;
            context.go(NextRoute.carry(
              '${AppRoute.verifyEmailScreen}?email=${Uri.encodeComponent(email)}',
              _nextRoute,
            ));
          } else if (state is AuthError) {
            final isLinkRequired =
                state.code == OAuthSignInService.linkRequiredCode;
            showSnackBar(
              context,
              state.message!,
              type: isLinkRequired ? SnackType.info : SnackType.error,
              seconds: isLinkRequired ? 10 : 6,
            );
          }

          if (state is! AuthLoading && state is! AuthLoggedIn) {
            setState(() {
              isSubmitting = false;
              _isOAuthLoading = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildScaffold(BuildContext context) {
    return UnauthenticatedScaffold(
      child: buildMainArea(context),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formController.formKey,
        child: Column(
          children: [
            const SizedBox(height: 25),

            Center(child: Image.asset(AppAssets.logoImagePath, height: 90.0)),

            const SizedBox(height: 35),

            SizedBox(
              width: _oauthButtonWidth,
              height: _oauthButtonHeight,
              child: IgnorePointer(
                ignoring: _isOAuthLoading || isSubmitting,
                child: Opacity(
                  opacity: _isOAuthLoading || isSubmitting ? 0.5 : 1.0,
                  child: SignInButton(
                    Buttons.google,
                    onPressed: () {
                      setState(() {
                        _isOAuthLoading = true;
                      });
                      context.read<AuthBloc>().add(
                        GoogleLoginEvent(
                          onRelinkProvider: oauthRelinkPrompt(
                            context,
                            signedInWith: OAuthProvider.google,
                          ),
                        ),
                      );
                    },
                    text: AppLocalizations.of(context).signUpWithProviderButton(OAuthProvider.google.label),
                  ),
                ),
              ),
            ),

            // Only show Apple Sign-In on iOS and web (not Android)
            if (kIsWeb || !Platform.isAndroid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: _oauthButtonWidth,
                height: _oauthButtonHeight,
                child: IgnorePointer(
                  ignoring: _isOAuthLoading || isSubmitting,
                  child: Opacity(
                    opacity: _isOAuthLoading || isSubmitting ? 0.5 : 1.0,
                    child: SignInButton(
                      Buttons.apple,
                      onPressed: () {
                        setState(() {
                          _isOAuthLoading = true;
                        });
                        context.read<AuthBloc>().add(
                          AppleLoginEvent(
                            onRelinkProvider: oauthRelinkPrompt(
                              context,
                              signedInWith: OAuthProvider.apple,
                            ),
                          ),
                        );
                      },
                      text: AppLocalizations.of(context).signUpWithProviderButton(OAuthProvider.apple.label),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: _oauthButtonWidth,
              height: _oauthButtonHeight,
              child: IgnorePointer(
                ignoring: _isOAuthLoading || isSubmitting,
                child: Opacity(
                  opacity: _isOAuthLoading || isSubmitting ? 0.5 : 1.0,
                  child: SignInButton(
                    Buttons.microsoft,
                    onPressed: () {
                      setState(() {
                        _isOAuthLoading = true;
                      });
                      context.read<AuthBloc>().add(
                        MicrosoftLoginEvent(
                          onRelinkProvider: oauthRelinkPrompt(
                            context,
                            signedInWith: OAuthProvider.microsoft,
                          ),
                        ),
                      );
                    },
                    text: AppLocalizations.of(context).signUpWithProviderButton(OAuthProvider.microsoft.label),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppLocalizations.of(context).authOrDivider,
                    style: AppStyles.standardBodyText(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 15),

            LabelAndTextFormField(
              key: const Key(CredentialsFormController.emailField),
              hintText: AppLocalizations.of(context).authEmailHint,
              autofocus: PlatformBehavior.autofocusesOnOpen,
              prefixIcon: Icons.email_outlined,
              controller: _formController.emailController,
              validator: BasicFormController.validateRequiredEmail,
              onFieldSubmitted: (value) => _onSubmit(),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),

            HeliumPasswordField(
              key: const Key(CredentialsFormController.passwordField),
              hintText: AppLocalizations.of(context).authPasswordHint,
              controller: _formController.passwordController,
              validator: BasicFormController.validatePassword,
              onFieldSubmitted: (value) => _onSubmit(),
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),

            HeliumPasswordField(
              key: const Key(SignupFormController.confirmPasswordField),
              hintText: AppLocalizations.of(context).signUpConfirmPasswordHint,
              prefixIcon: Icons.repeat,
              controller: _formController.confirmPasswordController,
              validator: _formController.validateConfirmPassword,
              onFieldSubmitted: (value) => _onSubmit(),
              autofillHints: const [AutofillHints.newPassword],
            ),

            const SizedBox(height: 16),

            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SizedBox(
                  width: _oauthButtonWidth,
                  child: HeliumElevatedButton(
                    key: const Key(SignupScreen.signUpButtonKey),
                    buttonText: AppLocalizations.of(context).signUpButton,
                    isLoading: isSubmitting,
                    enabled: !_isOAuthLoading,
                    onPressed: _onSubmit,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    context.go(NextRoute.carry(AppRoute.signinScreen, _nextRoute));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: Responsive.getIconSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).authBackToSignInLink,
                        style: AppStyles.buttonText(
                          context,
                        ).copyWith(color: context.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildLegalNotice(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final termsOfService = l10n.signUpTermsOfServiceLink;
    final privacyPolicy = l10n.signUpPrivacyPolicyLink;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppStyles.formText(context).copyWith(
          color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedTextAlpha),
        ),
        children: LinkedText.spans(
          l10n.signUpLegalNotice(termsOfService, privacyPolicy),
          links: {termsOfService: _termsRecognizer, privacyPolicy: _privacyRecognizer},
          linkStyle: AppStyles.formText(context).copyWith(color: context.colorScheme.primary),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (_formController.formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        isSubmitting = true;
      });

      await _localeDetection;
      if (!mounted) return;

      context.read<AuthBloc>().add(
        RegisterEvent(
          email: _formController.emailController.text.trim(),
          password: _formController.passwordController.text,
          timezone: _formController.timeZone,
          language: _formController.language,
        ),
      );
    }
  }
}
