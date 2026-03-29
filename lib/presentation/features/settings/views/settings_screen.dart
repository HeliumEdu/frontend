// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_state.dart';
import 'package:heliumapp/presentation/features/settings/views/change_email_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/change_password_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/external_calendars_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/feeds_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/import_export_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/preferences_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/support_helium_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum SettingsSubScreen {
  preferences,
  externalCalendars,
  feeds,
  changeEmail,
  changePassword,
  importExport,
}

/// Shows settings screen (responsive: side panel on desktop, full-screen on mobile)
Future<void> showSettings(BuildContext context, {int? initialTab}) {
  final currentUri = router.routerDelegate.currentConfiguration.uri;
  final hasDialogParam =
      currentUri.queryParameters.containsKey(DeepLinkParam.dialog);
  final basePath = hasDialogParam ? currentUri.path : null;

  final isMobile = Responsive.isMobile(context);

  final result = showScreenAsDialog(
    context,
    child: SettingsScreen(initialTab: initialTab),
    width: isMobile ? double.infinity : AppConstants.leftPanelDialogWidth,
    alignment: isMobile ? Alignment.center : Alignment.centerLeft,
    insetPadding: isMobile
        ? EdgeInsets.zero
        : const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 100),
  );

  if (basePath != null) {
    return result.then((_) => clearRouteQueryParams(basePath));
  }
  return result;
}

class SettingsScreen extends StatefulWidget {
  // Field name constants for integration testing
  static const String deleteAccountPasswordField = 'delete_account_password';

  /// 1-based tab index to open at, corresponding to [SettingsSubScreen] ordinal.
  /// Null opens the settings home page.
  final int? initialTab;

  const SettingsScreen({super.key, this.initialTab});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends BasePageScreenState<SettingsScreen> {
  final _preferencesKey = GlobalKey<PreferencesScreenState>();
  final _changeEmailKey = GlobalKey<ChangeEmailScreenState>();
  final _changePasswordKey = GlobalKey<ChangePasswordScreenState>();
  final _externalCalendarsKey = GlobalKey<ExternalCalendarsScreenState>();

  final BasicFormController _deleteAccountFormController =
      BasicFormController();
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();

  final themeNotifier = ThemeNotifier();

  SettingsSubScreen? _activeSubScreen;
  String _email = '';
  String? _emailChanging;
  String _version = '';
  bool _hasUsablePassword = true;
  bool _hasOAuthProviders = false;
  bool _dangerZoneExpanded = false;
  Timer? _dangerZoneTimer;

  @override
  String get screenTitle => switch (_activeSubScreen) {
    SettingsSubScreen.preferences => 'Preferences',
    SettingsSubScreen.externalCalendars => 'External Calendars',
    SettingsSubScreen.feeds => 'Feeds',
    SettingsSubScreen.changeEmail => 'Change Email',
    SettingsSubScreen.changePassword => 'Change Password',
    SettingsSubScreen.importExport => 'Import/Export',
    null => 'Settings',
  };

  @override
  IconData get icon => switch (_activeSubScreen) {
    SettingsSubScreen.preferences => Icons.tune,
    SettingsSubScreen.externalCalendars => AppConstants.externalCalendarIcon,
    SettingsSubScreen.feeds => Icons.rss_feed,
    SettingsSubScreen.changeEmail => Icons.email_outlined,
    SettingsSubScreen.changePassword => Icons.lock_outlined,
    SettingsSubScreen.importExport => Icons.swap_horiz,
    null => Icons.settings,
  };

  @override
  ScreenType get screenType => switch (_activeSubScreen) {
    SettingsSubScreen.preferences => ScreenType.entityPage,
    SettingsSubScreen.changeEmail => ScreenType.entityPage,
    SettingsSubScreen.changePassword => ScreenType.entityPage,
    _ => ScreenType.subPage,
  };

  @override
  Function? get saveAction => switch (_activeSubScreen) {
    SettingsSubScreen.preferences => () {
      if (isSubmitting) return;
      _preferencesKey.currentState?.onSubmit();
    },
    SettingsSubScreen.changeEmail => () {
      if (isSubmitting) return;
      _changeEmailKey.currentState?.onSubmit();
    },
    SettingsSubScreen.changePassword => () {
      if (isSubmitting) return;
      _changePasswordKey.currentState?.onSubmit();
    },
    _ => null,
  };

  @override
  Function get cancelAction => () {
    if (!mounted) return;
    if (_activeSubScreen != null) {
      setState(() => _activeSubScreen = null);
    } else if (DialogModeProvider.isDialogMode(context)) {
      Navigator.of(context).pop();
    } else {
      context.pop();
    }
  };

  @override
  bool get showActionButton =>
      _activeSubScreen == SettingsSubScreen.externalCalendars;

  @override
  VoidCallback? get actionButtonCallback =>
      _activeSubScreen == SettingsSubScreen.externalCalendars
          ? () => _externalCalendarsKey.currentState?.onAddCalendar()
          : null;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());

    final tab = widget.initialTab;
    if (tab != null) {
      final subScreen = _subScreenFromTab(tab);
      if (subScreen != null) {
        _activeSubScreen = subScreen;
      }
    }
  }

  static SettingsSubScreen? _subScreenFromTab(int tab) => switch (tab) {
    1 => SettingsSubScreen.preferences,
    2 => SettingsSubScreen.externalCalendars,
    3 => SettingsSubScreen.feeds,
    4 => SettingsSubScreen.changeEmail,
    5 => SettingsSubScreen.changePassword,
    6 => SettingsSubScreen.importExport,
    _ => null,
  };

  @override
  void dispose() {
    _dangerZoneTimer?.cancel();
    _deleteAccountPasswordController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<PlannerItemBloc, PlannerItemState>(
        listener: (context, state) {
          if (state.origin != EventOrigin.dialog) return;

          if (state is AllEventsDeleted) {
            setState(() {
              isLoading = false;
            });
            showSnackBar(context, 'All Events deleted');
          } else if (state is PlannerItemsError) {
            setState(() {
              isLoading = false;
            });
            showSnackBar(context, state.message!, type: SnackType.error);
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            // Only handle on the main settings page; sub-screens handle their own errors.
            if (_activeSubScreen == null) {
              showSnackBar(context, state.message!, type: SnackType.error);
            }
          } else if (state is AuthProfileFetched) {
            final platform = await PackageInfo.fromPlatform();

            setState(() {
              _version = 'v${platform.version}';

              _email = state.user.email;
              _emailChanging = state.user.emailChanging;
              _hasUsablePassword = state.user.hasUsablePassword;
              _hasOAuthProviders = state.user.hasOAuthProviders;

              isLoading = false;
            });
          } else if (state is AuthEmailChangeRequested) {
            setState(() {
              _emailChanging = state.newEmail;
            });
          } else if (state is AuthEmailChangeCancelled) {
            setState(() {
              _emailChanging = null;
            });
          } else if (state is AuthLoggedOut) {
            if (!context.mounted) return;
            context.go(AppRoute.loginScreen);
          } else if (state is AuthAccountDeleted) {
            showSnackBar(
              context,
              "Sorry to see you go! We've deleted all traces of your existence from Helium.",
              type: SnackType.info,
              seconds: 6,
              useRootMessenger: true,
            );
            if (!context.mounted) return;
            if (DialogModeProvider.isDialogMode(context)) {
              Navigator.of(context).pop();
            }
            context.go(AppRoute.loginScreen);
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    if (_activeSubScreen == null) {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator();
          }

          return _buildSettingsPage();
        },
      );
    }

    return Expanded(
      child: switch (_activeSubScreen!) {
        SettingsSubScreen.preferences => PreferencesScreen(
          key: _preferencesKey,
          userSettings: userSettings,
          onActionStarted: () => setState(() => isSubmitting = true),
          onCompleted: () => setState(() {
            isSubmitting = false;
            _activeSubScreen = null;
          }),
          onFailed: () => setState(() => isSubmitting = false),
        ),
        SettingsSubScreen.changeEmail => ChangeEmailScreen(
          key: _changeEmailKey,
          onActionStarted: () => setState(() => isSubmitting = true),
          onCompleted: () => setState(() {
            isSubmitting = false;
            _activeSubScreen = null;
          }),
          onFailed: () => setState(() => isSubmitting = false),
        ),
        SettingsSubScreen.changePassword => ChangePasswordScreen(
          key: _changePasswordKey,
          onActionStarted: () => setState(() => isSubmitting = true),
          onCompleted: () => setState(() {
            isSubmitting = false;
            _activeSubScreen = null;
          }),
          onFailed: () => setState(() => isSubmitting = false),
        ),
        SettingsSubScreen.externalCalendars => ExternalCalendarsScreen(
          key: _externalCalendarsKey,
        ),
        SettingsSubScreen.feeds => FeedsScreen(userSettings: userSettings),
        SettingsSubScreen.importExport => ImportExportScreen(
          onNavigateRequested: _onNavigateRequested,
        ),
      },
    );
  }

  void _onNavigateRequested(String route) {
    setState(() => _activeSubScreen = null);
    if (!mounted) return;
    if (DialogModeProvider.isDialogMode(context)) {
      Navigator.of(context).pop();
    }
    if (mounted) context.go(route);
  }

  Widget _buildSettingsPage() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileArea(),

            const SizedBox(height: 12),

            const SupportHeliumCard(),

            const SizedBox(height: 12),

            _buildSubSettingsArea(),

            const SizedBox(height: 12),

            _buildDangerZoneArea(),

            const SizedBox(height: 12),

            if (_version.isNotEmpty)
              Center(
                child: Text(
                  _version,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileArea() {
    return ShadowContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://support.heliumedu.com')),
                icon: Icon(
                  Icons.help_center,
                  color: context.colorScheme.primary,
                  size: 30,
                ),
                tooltip: 'Get support',
              ),
              const SizedBox(width: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_brightness),
                  ),
                ],
                selected: {themeNotifier.themeMode},
                onSelectionChanged: (Set<ThemeMode> selected) {
                  themeNotifier.setThemeMode(selected.first);

                  final colorSchemeTheme = switch (selected.first) {
                    ThemeMode.light => 0,
                    ThemeMode.dark => 1,
                    ThemeMode.system => 2,
                  };

                  context.read<AuthBloc>().add(
                    UpdateProfileEvent(
                      request: UpdateSettingsRequestModel(
                        colorSchemeTheme: colorSchemeTheme,
                      ),
                    ),
                  );
                },
                showSelectedIcon: false,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      initialValue: _email,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
              if (_emailChanging != null && _emailChanging!.isNotEmpty) ...[
                const SizedBox(height: 8),
                WarningContainer(
                  text:
                      'Change pending, click the link sent to $_emailChanging to verify',
                  icon: Icons.schedule,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubSettingsArea() {
    return ShadowContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.tune,
            label: 'Preferences',
            hint: 'Tailor Helium to your tastes',
            onTap: () => _navigateToSubSettings(SettingsSubScreen.preferences),
            iconColor: context.semanticColors.info,
            isFirst: true,
          ),
          const Divider(height: 1, indent: 68),
          _buildSettingsItem(
            icon: AppConstants.externalCalendarIcon,
            label: 'External Calendars',
            hint: 'Bring other calendars in to Helium',
            onTap: () =>
                _navigateToSubSettings(SettingsSubScreen.externalCalendars),
            iconColor: context.colorScheme.primary,
          ),
          const Divider(height: 1, indent: 68),
          _buildSettingsItem(
            icon: Icons.rss_feed,
            label: 'Feeds',
            hint: "Take Helium's calendars elsewhere",
            onTap: () => _navigateToSubSettings(SettingsSubScreen.feeds),
            iconColor: context.colorScheme.primary,
          ),
          if (!_hasOAuthProviders) const Divider(height: 1, indent: 68),
          if (!_hasOAuthProviders)
            _buildSettingsItem(
              icon: Icons.email_outlined,
              label: 'Change Email',
              hint: 'Update your email address',
              onTap: () =>
                  _navigateToSubSettings(SettingsSubScreen.changeEmail),
              iconColor: context.colorScheme.primary,
            ),
          if (_hasUsablePassword) const Divider(height: 1, indent: 68),
          if (_hasUsablePassword)
            _buildSettingsItem(
              icon: Icons.lock_outline,
              label: 'Change Password',
              hint: 'Update your password',
              onTap: () =>
                  _navigateToSubSettings(SettingsSubScreen.changePassword),
              iconColor: context.colorScheme.primary,
            ),
          const Divider(height: 1, indent: 68),
          _buildSettingsItem(
            icon: Icons.swap_horiz,
            label: 'Import/Export',
            hint: 'Backup and restore your data',
            onTap: () =>
                _navigateToSubSettings(SettingsSubScreen.importExport),
            iconColor: context.colorScheme.primary,
          ),
          const Divider(height: 1, indent: 68),
          _buildSettingsItem(
            icon: Icons.logout_outlined,
            label: 'Logout',
            hint: 'Sign out of your account',
            onTap: () => _showLogoutDialog(context),
            iconColor: context.semanticColors.warning,
            iconBackgroundColor: context.colorScheme.error.withValues(
              alpha: 0.1,
            ),
            labelColor: context.semanticColors.warning,
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _navigateToSubSettings(SettingsSubScreen subScreen) {
    setState(() => _activeSubScreen = subScreen);
  }

  void _expandDangerZone() {
    _dangerZoneTimer?.cancel();
    setState(() {
      _dangerZoneExpanded = true;
    });
    _dangerZoneTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _dangerZoneExpanded = false;
        });
      }
    });
  }

  void _resetDangerZoneTimer() {
    _dangerZoneTimer?.cancel();
    _dangerZoneTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _dangerZoneExpanded = false;
        });
      }
    });
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
    required Color iconColor,
    Color? iconBackgroundColor,
    Color? labelColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: isFirst ? const Radius.circular(16) : Radius.zero,
          bottomLeft: const Radius.circular(16),
          bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ?? iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 22,
                    tablet: 24,
                    desktop: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: labelColor != null
                          ? AppStyles.menuItem(
                              context,
                            ).copyWith(color: labelColor)
                          : AppStyles.menuItem(context),
                    ),
                    const SizedBox(height: 2),
                    Text(hint, style: AppStyles.menuItemHint(context)),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                size: Responsive.getIconSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZoneArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: _dangerZoneExpanded
          ? _buildDangerZoneExpanded()
          : _buildDangerZoneCollapsed(),
    );
  }

  Widget _buildDangerZoneCollapsed() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _expandDangerZone,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: context.colorScheme.error,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 22,
                    tablet: 24,
                    desktop: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Danger Zone',
                  style: AppStyles.menuItem(
                    context,
                  ).copyWith(color: context.colorScheme.error),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZoneExpanded() {
    return Column(
      children: [
        _buildDangerZoneItem(
          icon: Icons.delete_sweep_outlined,
          label: 'Delete All Events',
          hint: 'Permanently delete all Events',
          onTap: () {
            _resetDangerZoneTimer();
            _showDeleteAllEventsDialog(context);
          },
          isFirst: true,
        ),
        const Divider(height: 1, indent: 68),
        _buildDangerZoneItem(
          icon: Icons.delete_outline,
          label: 'Delete Account',
          hint: 'Permanently delete your account',
          onTap: () {
            _resetDangerZoneTimer();
            _showDeleteAccountDialog(context);
          },
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDangerZoneItem({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: isFirst ? const Radius.circular(16) : Radius.zero,
          bottomLeft: const Radius.circular(16),
          bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: context.colorScheme.error,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 22,
                    tablet: 24,
                    desktop: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppStyles.menuItem(
                        context,
                      ).copyWith(color: context.colorScheme.error),
                    ),
                    const SizedBox(height: 2),
                    Text(hint, style: AppStyles.menuItemHint(context)),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAllEventsDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.colorScheme.error,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 28,
                    tablet: 30,
                    desktop: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete All Events',
                    style: AppStyles.featureText(
                      context,
                    ).copyWith(color: context.colorScheme.error),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Text(
                'Are you sure you want to delete all Events? Anything associated with them, including attachments, notes, and other data, will also be deleted. This action cannot be undone.',
                style: AppStyles.standardBodyText(context),
              ),
            ),
            actions: [
              SizedBox(
                width: Responsive.getDialogWidth(context),
                child: Row(
                  children: [
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Cancel',
                        backgroundColor: context.colorScheme.outline,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Delete',
                        backgroundColor: context.colorScheme.error,
                        isLoading: isSubmitting,
                        onPressed: () {
                          setState(() {
                            isSubmitting = true;
                          });

                          Navigator.of(dialogContext).pop();

                          this.setState(() {
                            isLoading = true;
                          });

                          context.read<PlannerItemBloc>().add(
                            DeleteAllEventsEvent(origin: EventOrigin.dialog),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: context.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text('Logout', style: AppStyles.pageTitle(context)),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Text(
                'Are you sure you want to logout?',
                style: AppStyles.standardBodyText(context),
              ),
            ),
            actions: [
              SizedBox(
                width: Responsive.getDialogWidth(context),
                child: Row(
                  children: [
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Cancel',
                        backgroundColor: context.colorScheme.outline,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Logout',
                        backgroundColor: context.colorScheme.error,
                        isLoading: isSubmitting,
                        onPressed: () {
                          setState(() {
                            isSubmitting = true;
                          });

                          Navigator.of(dialogContext).pop();

                          parentContext.read<AuthBloc>().add(LogoutEvent());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext parentContext) {
    _deleteAccountPasswordController.text = '';
    bool isSubmitting = false;
    bool obscurePassword = true;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void handleSubmit() {
            if (_deleteAccountFormController.formKey.currentState!.validate()) {
              setState(() {
                isSubmitting = true;
              });

              final password = _hasUsablePassword
                  ? _deleteAccountPasswordController.text.trim()
                  : null;

              Navigator.of(dialogContext).pop();

              parentContext.read<AuthBloc>().add(
                DeleteAccountEvent(password: password),
              );
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.colorScheme.error,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 28,
                    tablet: 30,
                    desktop: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: AppStyles.featureText(
                      context,
                    ).copyWith(color: context.colorScheme.error),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: SingleChildScrollView(
                child: Form(
                  key: _deleteAccountFormController.formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasUsablePassword
                            ? 'To permanently delete your account—and all data you have stored in Helium—confirm your password below. This action cannot be undone.'
                            : 'To permanently delete your account—and all data you have stored in Helium—confirm by clicking the Delete button below. This action cannot be undone.',
                        style: AppStyles.standardBodyText(context),
                      ),
                      if (_hasUsablePassword) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: LabelAndTextFormField(
                                key: const Key(
                                  SettingsScreen.deleteAccountPasswordField,
                                ),
                                autofocus: kIsWeb,
                                controller: _deleteAccountPasswordController,
                                validator:
                                    BasicFormController.validateRequiredField,
                                onFieldSubmitted: (value) => handleSubmit(),
                                obscureText: obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                    size: Responsive.getIconSize(
                                      context,
                                      mobile: 20,
                                      tablet: 22,
                                      desktop: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: Responsive.getDialogWidth(context),
                child: Row(
                  children: [
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Cancel',
                        backgroundColor: context.colorScheme.outline,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Delete',
                        backgroundColor: context.colorScheme.error,
                        isLoading: isSubmitting,
                        onPressed: handleSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          },
        ),
    );
  }
}

