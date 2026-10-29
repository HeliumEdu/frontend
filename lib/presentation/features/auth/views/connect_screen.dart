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
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/unauthenticated_scaffold.dart';
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
  String? _error;
  bool _isReturning = false;
  bool _isAllowing = false;

  @override
  void initState() {
    super.initState();

    if (widget.query.isEmpty) {
      _error = AuthBloc.invalidAuthorizationMessage;
      return;
    }

    // The BLoC context is not ready until after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AuthBloc>().add(
        DescribeAuthorizationEvent(query: widget.query),
      );
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
          } else if (state is AuthAuthorizationDecided) {
            _returnToClient(state.redirectUri);
          } else if (state is AuthAuthorizationRejected) {
            final redirectUri = state.redirectUri;
            if (redirectUri != null) {
              _returnToClient(redirectUri);
            } else {
              setState(() {
                _error = state.message;
              });
            }
          } else if (state is AuthError) {
            if (_authorization == null) {
              setState(() {
                _error = state.message;
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
    final authorization = _authorization;

    return Column(
      children: [
        const SizedBox(height: 12),

        Text(
          screenTitle,
          style: AppStyles.featureText(
            context,
          ).copyWith(fontSize: Responsive.getFontSize(context, mobile: 22)),
        ),

        const SizedBox(height: 25),

        _buildIcon(context, _error == null ? Icons.link : Icons.link_off),

        const SizedBox(height: 25),

        if (_error != null)
          ..._buildError(context)
        else if (_isReturning)
          ..._buildReturning(context)
        else if (authorization == null)
          const LoadingIndicator(expanded: false)
        else
          ..._buildConsent(context, authorization),
      ],
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon) {
    return Center(
      child: Container(
        width: AppConstants.authContainerSize,
        height: AppConstants.authContainerSize,
        decoration: BoxDecoration(
          color: context.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: Responsive.getIconSize(
            context,
            mobile: 60,
            tablet: 64,
            desktop: 68,
          ),
          color: context.colorScheme.primary,
        ),
      ),
    );
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

      const SizedBox(height: 20),

      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'It will be able to:',
          style: AppStyles.standardBodyText(context),
        ),
      ),

      const SizedBox(height: 8),

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

      const SizedBox(height: 20),

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

      const SizedBox(height: 12),

      Center(
        child: TextButton(
          key: const Key(ConnectScreen.denyButtonKey),
          onPressed: isSubmitting ? null : () => _decide(allow: false),
          child: Text(
            'Deny',
            style: AppStyles.buttonText(
              context,
            ).copyWith(color: context.colorScheme.primary),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildReturning(BuildContext context) {
    final clientName = _authorization?.clientName ?? 'the app you came from';

    return [
      Text(
        kIsWeb
            ? 'Returning you to $clientName ...'
            : 'Return to $clientName to finish.',
        style: AppStyles.headingText(context),
        textAlign: TextAlign.center,
      ),
      if (kIsWeb) ...[
        const SizedBox(height: 25),
        const LoadingIndicator(expanded: false),
      ],
    ];
  }

  List<Widget> _buildError(BuildContext context) {
    return [
      Text(
        _error!,
        style: AppStyles.headingText(context),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 25),

      HeliumElevatedButton(
        buttonText: 'Go to Helium',
        onPressed: () => context.go(AppRoute.plannerScreen),
      ),
    ];
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

  void _returnToClient(String redirectUri) {
    setState(() {
      _isReturning = true;
    });

    UrlHelpers.launchWebUrl(redirectUri, sameTabOnWeb: true);
  }
}
