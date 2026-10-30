import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/oauth_authorization_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/account_email_field.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/unauthenticated_scaffold.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

/// Where a user consents to an app (a connector) acting on their Helium account.
/// The app sends the user here with an OAuth authorization request; the user's
/// decision sends them back to it.
class ConnectScreen extends StatefulWidget {
  static const String allowButtonKey = 'connect_allow_button';
  static const String denyButtonKey = 'connect_deny_button';
  static const String switchAccountButtonKey = 'connect_switch_account_button';

  /// About the consent's height, account line included, so moving between
  /// loading, consent, and error doesn't resize the card.
  static const double stateAreaMinHeight = 445;

  /// The OAuth authorization request's query string, passed to the API as is.
  final String query;

  const ConnectScreen({super.key, required this.query});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends BasePageScreenState<ConnectScreen> {
  @override
  String get screenTitle => 'Connect to Helium';

  @override
  bool get isAuthenticatedScreen => false;

  OAuthAuthorizationModel? _authorization;
  String? _invalidMessage;
  String? _loadError;
  bool _isReturning = false;
  bool _isAllowing = false;

  @override
  void initState() {
    super.initState();

    if (widget.query.isEmpty) {
      _invalidMessage = AuthBloc.invalidAuthorizationMessage;
      return;
    }

    // The BLoC context is not ready until after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _describe();
    });
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthorizationDescribed) {
            setState(() {
              _authorization = state.authorization;
            });
          } else if (state is AuthLoggedOut) {
            context.go(
              NextRoute.carry(
                AppRoute.signinScreen,
                '${AppRoute.connectScreen}?${widget.query}',
              ),
            );
          } else if (state is AuthAuthorizationDecided) {
            _returnToClient(state.redirectUri);
          } else if (state is AuthAuthorizationRejected) {
            final redirectUri = state.redirectUri;
            if (redirectUri != null) {
              _returnToClient(redirectUri);
            } else {
              setState(() {
                _invalidMessage = state.message;
              });
            }
          } else if (state is AuthError) {
            if (_authorization == null) {
              setState(() {
                _loadError = state.message;
              });
            } else {
              showSnackBar(
                context,
                state.message!,
                type: SnackType.error,
                seconds: 6,
              );
            }
          }

          if (state is! AuthLoading) {
            setState(() {
              isSubmitting = false;
              _isAllowing = false;
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
    return Column(
      children: [
        const SizedBox(height: 12),

        Center(child: Image.asset(AppAssets.logoImagePath, height: 90.0)),

        const SizedBox(height: 25),

        const Divider(height: 1),

        const SizedBox(height: 25),

        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ConnectScreen.stateAreaMinHeight,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildState(context),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildState(BuildContext context) {
    final authorization = _authorization;

    if (_invalidMessage != null) {
      return _buildInvalid(context, _invalidMessage!);
    } else if (_loadError != null) {
      return [
        ErrorCard(
          message: _loadError!,
          source: 'connect_screen',
          onReload: _describe,
          expanded: false,
          supportUrl: AppConstants.supportWhereToStartUrl,
        ),
      ];
    } else if (_isReturning) {
      return _buildReturning(context);
    } else if (authorization == null) {
      return [const LoadingIndicator(expanded: false)];
    }
    return _buildConsent(context, authorization);
  }

  List<Widget> _buildConsent(
    BuildContext context,
    OAuthAuthorizationModel authorization,
  ) {
    return [
      Text(
        '${authorization.clientName} wants to access your Helium account.',
        style: AppStyles.headingText(context),
        textAlign: TextAlign.center,
      ),

      if (authorization.userEmail case final userEmail?) ...[
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              AccountEmailField(
                email: userEmail,
                oauthProviders: authorization.userOAuthProviders,
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key(ConnectScreen.switchAccountButtonKey),
                    onPressed: isSubmitting ? null : _switchAccount,
                    child: Text(
                      'Not you?',
                      style: AppStyles.standardBodyText(
                        context,
                      ).copyWith(color: context.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

      ],

      const SizedBox(height: 16),

      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'It will be able to:',
          style: AppStyles.standardBodyText(context),
        ),
      ),

      const SizedBox(height: 12),

      for (final scope in authorization.scopes)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check,
                size: Responsive.getIconSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scope.description,
                  style: AppStyles.standardBodyText(context),
                ),
              ),
            ],
          ),
        ),

      const SizedBox(height: 25),

      Text(
        'Only allow this if you are connecting ${authorization.clientName} to '
        'Helium yourself.',
        style: AppStyles.smallSecondaryText(context),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 25),

      HeliumElevatedButton(
        key: const Key(ConnectScreen.allowButtonKey),
        buttonText: 'Allow',
        isLoading: _isAllowing,
        enabled: !isSubmitting,
        onPressed: () => _decide(allow: true),
      ),

      const SizedBox(height: 8),

      TextButton(
        key: const Key(ConnectScreen.denyButtonKey),
        style: HeliumElevatedButton.textStyle(context.colorScheme),
        onPressed: isSubmitting ? null : () => _decide(allow: false),
        child: isSubmitting && !_isAllowing
            ? LoadingIndicator(
                size: HeliumElevatedButton.loadingIndicatorSize,
                strokeWidth: HeliumElevatedButton.loadingIndicatorStrokeWidth,
                expanded: false,
                color: context.colorScheme.onSurface.withValues(alpha: 0.38),
              )
            : Text(
                'Deny',
                style: AppStyles.buttonText(context).copyWith(
                  color: isSubmitting
                      ? context.colorScheme.onSurface.withValues(alpha: 0.38)
                      : context.colorScheme.primary,
                ),
              ),
      ),
    ];
  }

  List<Widget> _buildReturning(BuildContext context) {
    final clientName = _authorization?.clientName ?? 'the app you came from';

    return [
      if (kIsWeb) ...[
        const LoadingIndicator(size: 48, strokeWidth: 4, expanded: false),

        const SizedBox(height: 32),
      ],

      Text(
        kIsWeb
            ? 'Returning you to $clientName ...'
            : 'Return to $clientName to finish.',
        style: AppStyles.standardBodyText(
          context,
        ).copyWith(fontSize: 18.0, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _buildInvalid(BuildContext context, String message) {
    return [
      Text(
        message,
        style: AppStyles.headingText(context),
        textAlign: TextAlign.center,
      ),
    ];
  }

  void _describe() {
    setState(() {
      _loadError = null;
    });

    context.read<AuthBloc>().add(
      DescribeAuthorizationEvent(query: widget.query),
    );
  }

  void _decide({required bool allow}) {
    setState(() {
      isSubmitting = true;
      _isAllowing = allow;
    });

    context.read<AuthBloc>().add(
      DecideAuthorizationEvent(query: widget.query, allow: allow),
    );
  }

  void _switchAccount() {
    setState(() {
      isSubmitting = true;
    });

    context.read<AuthBloc>().add(LogoutEvent());
  }

  void _returnToClient(String redirectUri) {
    setState(() {
      _isReturning = true;
    });

    UrlHelpers.launchWebUrl(redirectUri, sameTabOnWeb: true);
  }
}
