import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/auth/api_token_model.dart';
import 'package:heliumapp/data/models/auth/connected_app_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_bloc.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_event.dart';
import 'package:heliumapp/presentation/features/settings/bloc/connected_app_state.dart';
import 'package:heliumapp/presentation/features/settings/dialogs/change_password_dialog.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  UserModel? _user;

  ApiTokenModel? _revealedApiToken;
  bool _isApiTokenSubmitting = false;

  List<ConnectedAppModel> _connectedApps = [];
  bool _connectedAppsLoaded = false;
  final Set<int> _revokingConnectedAppIds = {};

  bool get _hasApiToken => _user?.apiTokenCreatedAt != null;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileFetched) {
      _user = authState.user;
    } else {
      context.read<AuthBloc>().add(FetchProfileEvent());
    }

    _fetchConnectedApps();
  }

  void _fetchConnectedApps() {
    context.read<ConnectedAppBloc>().add(
      FetchConnectedAppsEvent(origin: EventOrigin.screen, forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(listener: _onAuthState),
        BlocListener<ConnectedAppBloc, ConnectedAppState>(
          listener: _onConnectedAppState,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoContainer(
              text:
                  'Manage how you sign in, and how other apps and tools reach your Helium account.',
              trailing: HeliumIconButton(
                icon: Icons.menu_book_outlined,
                backgroundColor: context.colorScheme.onSurfaceVariant,
                tooltip: 'Learn more',
                onPressed: () =>
                    UrlHelpers.launchWebUrl(AppConstants.supportApiUrl),
              ),
            ),
          ),
          Expanded(
            child: _user == null ? _buildProfileLoadState() : _buildCards(),
          ),
        ],
      ),
    );
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state is AuthProfileFetched) {
      setState(() => _user = state.user);
    } else if (state is AuthApiTokenCreated) {
      setState(() {
        _user = state.user;
        _revealedApiToken = state.apiToken;
        _isApiTokenSubmitting = false;
      });
      SnackBarHelper.show(context, 'API token generated.');
    } else if (state is AuthApiTokenRevoked) {
      setState(() {
        _user = state.user;
        _revealedApiToken = null;
        _isApiTokenSubmitting = false;
      });
      SnackBarHelper.show(context, 'API token revoked.');
    } else if (state is AuthError && _isApiTokenSubmitting) {
      setState(() => _isApiTokenSubmitting = false);
      SnackBarHelper.show(context, state.message!, type: SnackType.error);
    }
  }

  void _onConnectedAppState(BuildContext context, ConnectedAppState state) {
    if (state is ConnectedAppsFetched) {
      setState(() {
        _connectedApps = state.connectedApps;
        _connectedAppsLoaded = true;
      });
    } else if (state is ConnectedAppRevoked) {
      setState(() {
        _connectedApps = _connectedApps
            .where((app) => app.id != state.id)
            .toList();
        _revokingConnectedAppIds.remove(state.id);
      });
      SnackBarHelper.show(context, 'Access revoked.');
    } else if (state is ConnectedAppsError &&
        state.origin == EventOrigin.subScreen) {
      setState(() => _revokingConnectedAppIds.clear());
      SnackBarHelper.show(context, state.message!, type: SnackType.error);
    }
  }

  Widget _buildProfileLoadState() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthError) {
          return ErrorCard(
            message: state.message!,
            source: 'security_screen',
            onReload: () => context.read<AuthBloc>().add(FetchProfileEvent()),
          );
        }
        return const LoadingIndicator();
      },
    );
  }

  Widget _buildCards() {
    return HeliumFullScreenScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPasswordCard(_user!),
          _buildApiTokenCard(_user!),
          _buildConnectedAppsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String description,
    required Widget body,
    Widget? trailing,
  }) {
    final color = context.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.containerContentInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: Responsive.getIconSize(
                      context,
                      mobile: 24,
                      tablet: 26,
                      desktop: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppStyles.featureText(context)),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppStyles.menuItemHint(context),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
            const Divider(height: 24),
            body,
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(UserModel user) {
    return _buildSectionCard(
      icon: user.hasUsablePassword
          ? Icons.lock_outline
          : Icons.lock_open_outlined,
      title: 'Password',
      description: user.hasUsablePassword
          ? 'Sign in with your email and password'
          : 'Add a password to also sign in with your email',
      body: HeliumElevatedButton(
        icon: user.hasUsablePassword ? Icons.lock_reset : Icons.lock_open,
        buttonText: user.hasUsablePassword
            ? 'Change Password'
            : 'Set Password',
        onPressed: () => _onChangePassword(user),
      ),
    );
  }

  Future<void> _onChangePassword(UserModel user) async {
    final changed = await showChangePasswordDialog(
      parentContext: context,
      passwordless: !user.hasUsablePassword,
      revokesApiToken: _hasApiToken,
    );
    if (!changed || !mounted) return;

    setState(() => _revealedApiToken = null);
    SnackBarHelper.show(context, 'Password changed.');
    context.read<AuthBloc>().add(FetchProfileEvent());
  }

  Widget _buildApiTokenCard(UserModel user) {
    return _buildSectionCard(
      icon: Icons.key_outlined,
      title: 'API Token',
      description: "Reach Helium's platform from your own scripts and tools",
      trailing: HeliumIconButton(
        icon: Icons.code,
        backgroundColor: context.colorScheme.onSurfaceVariant,
        tooltip: 'API docs',
        onPressed: () => UrlHelpers.launchWebUrl(ApiUrl.docsUrl),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_revealedApiToken != null) ...[
            _buildRevealedApiToken(_revealedApiToken!),
            const SizedBox(height: 12),
          ],
          Text(
            _apiTokenStatus(user),
            style: AppStyles.standardBodyText(context),
          ),
          const SizedBox(height: 12),
          if (_hasApiToken)
            Row(
              children: [
                Expanded(
                  child: HeliumElevatedButton(
                    icon: Icons.autorenew,
                    buttonText: 'Rotate',
                    isLoading: _isApiTokenSubmitting,
                    onPressed: _onRotateApiToken,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HeliumElevatedButton(
                    icon: Icons.link_off,
                    buttonText: 'Revoke',
                    backgroundColor: context.colorScheme.error,
                    enabled: !_isApiTokenSubmitting,
                    onPressed: _onRevokeApiToken,
                  ),
                ),
              ],
            )
          else
            HeliumElevatedButton(
              icon: Icons.add,
              buttonText: 'Generate',
              isLoading: _isApiTokenSubmitting,
              onPressed: _createApiToken,
            ),
        ],
      ),
    );
  }

  String _apiTokenStatus(UserModel user) {
    final createdAt = user.apiTokenCreatedAt;
    if (createdAt == null) return 'You have no API token.';

    final createdOn = HeliumDateTime.formatDate(
      HeliumDateTime.toLocal(createdAt, user.settings.timeZone),
    );
    return 'Created $createdOn';
  }

  Widget _buildRevealedApiToken(ApiTokenModel apiToken) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WarningContainer(
          text:
              "Copy your token now, it won't be shown again. Keep it secret, it gives full access to your account.",
          icon: Icons.privacy_tip_outlined,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.containerContentInset),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: SelectableText(
            apiToken.token,
            style: AppStyles.standardBodyTextLight(context),
          ),
        ),
        const SizedBox(height: 12),
        HeliumElevatedButton(
          icon: Icons.copy,
          buttonText: 'Copy',
          minHeight: 36,
          visualDensity: VisualDensity.standard,
          onPressed: () => _copyApiToken(apiToken),
        ),
      ],
    );
  }

  void _copyApiToken(ApiTokenModel apiToken) {
    Clipboard.setData(ClipboardData(text: apiToken.token));
    SnackBarHelper.show(context, 'API token copied.');
  }

  Future<void> _onRotateApiToken() async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Rotate API Token',
      message:
          'Rotating replaces your current token, so anything using it will stop working until you give it the new one.',
      actionText: 'Rotate',
      icon: Icons.warning_rounded,
    );
    if (!confirmed || !mounted) return;
    _createApiToken();
  }

  void _createApiToken() {
    setState(() => _isApiTokenSubmitting = true);
    context.read<AuthBloc>().add(CreateApiTokenEvent());
  }

  Future<void> _onRevokeApiToken() async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Revoke API Token',
      message:
          'Anything using your API token will stop working. You can generate a new one later.',
      actionText: 'Revoke',
      icon: Icons.warning_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isApiTokenSubmitting = true);
    context.read<AuthBloc>().add(RevokeApiTokenEvent());
  }

  Widget _buildConnectedAppsCard() {
    return _buildSectionCard(
      icon: Icons.apps_outlined,
      title: 'Connected Apps',
      description: "Apps you've allowed to reach your Helium account",
      trailing: HeliumIconButton(
        icon: Icons.menu_book_outlined,
        backgroundColor: context.colorScheme.onSurfaceVariant,
        tooltip: 'Learn more',
        onPressed: () =>
            UrlHelpers.launchWebUrl(AppConstants.supportConnectedAppsUrl),
      ),
      body: BlocBuilder<ConnectedAppBloc, ConnectedAppState>(
        builder: _buildConnectedAppsBody,
      ),
    );
  }

  Widget _buildConnectedAppsBody(
    BuildContext context,
    ConnectedAppState state,
  ) {
    if (!_connectedAppsLoaded) {
      if (state is ConnectedAppsError && state.origin == EventOrigin.screen) {
        return ErrorCard(
          message: state.message!,
          source: 'security_screen',
          expanded: false,
          onReload: _fetchConnectedApps,
        );
      }
      return const LoadingIndicator(expanded: false);
    }

    if (_connectedApps.isEmpty) {
      return Text(
        'No apps are connected.',
        style: AppStyles.standardBodyTextLight(context),
      );
    }

    return Column(
      children: [
        for (final (index, connectedApp) in _connectedApps.indexed) ...[
          if (index > 0) const Divider(height: 24),
          _buildConnectedAppRow(connectedApp),
        ],
      ],
    );
  }

  Widget _buildConnectedAppRow(ConnectedAppModel connectedApp) {
    final mutedStyle = AppStyles.smallSecondaryTextLight(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connectedApp.name,
                style: AppStyles.standardBodyTextEmphasis(context),
              ),
              const SizedBox(height: 4),
              for (final scope in connectedApp.scopes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check,
                        size: Responsive.getIconSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scope.description,
                          style: AppStyles.smallSecondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(_lastUsedLabel(connectedApp), style: mutedStyle),
            ],
          ),
        ),
        const SizedBox(width: 8),
        HeliumIconButton(
          icon: Icons.link_off,
          color: context.colorScheme.error,
          semanticLabel: 'Revoke ${connectedApp.name}',
          enabled: !_revokingConnectedAppIds.contains(connectedApp.id),
          onPressed: () => _onRevokeConnectedApp(connectedApp),
        ),
      ],
    );
  }

  String _lastUsedLabel(ConnectedAppModel connectedApp) {
    final lastUsedAt = connectedApp.lastUsedAt;
    if (lastUsedAt == null) return 'Not used yet';

    final lastUsedOn = HeliumDateTime.formatDate(
      HeliumDateTime.toLocal(lastUsedAt, _user!.settings.timeZone),
    );
    return 'Last used $lastUsedOn';
  }

  Future<void> _onRevokeConnectedApp(ConnectedAppModel connectedApp) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Revoke Access',
      message:
          '${connectedApp.name} will no longer be able to reach your Helium account. You can connect it again later.',
      actionText: 'Revoke',
      icon: Icons.warning_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _revokingConnectedAppIds.add(connectedApp.id));
    context.read<ConnectedAppBloc>().add(
      RevokeConnectedAppEvent(
        origin: EventOrigin.subScreen,
        id: connectedApp.id,
      ),
    );
  }
}
