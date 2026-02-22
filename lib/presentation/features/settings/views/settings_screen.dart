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
import 'package:heliumapp/presentation/features/settings/views/change_password_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/external_calendars_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/feeds_screen.dart';
import 'package:heliumapp/presentation/features/settings/views/preferences_screen.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows as a dialog on desktop, or navigates on mobile.
void showSettings(BuildContext context) {
  if (Responsive.isMobile(context)) {
    context.push(AppRoute.settingScreen);
  } else {
    showScreenAsDialog(
      context,
      child: const SettingsScreen(),
      width: AppConstants.leftPanelDialogWidth,
      alignment: Alignment.centerLeft,
      insetPadding: const EdgeInsets.all(0),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenViewState();
}

class _SettingsScreenViewState extends BasePageScreenState<SettingsScreen> {
  @override
  String get screenTitle => 'Settings';

  @override
  IconData get icon => Icons.settings;

  @override
  ScreenType get screenType => ScreenType.subPage;

  final BasicFormController _deleteAccountFormController =
      BasicFormController();
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();

  final themeNotifier = ThemeNotifier();

  // State
  String _email = '';
  String _version = '';
  bool _hasUsablePassword = true;
  bool _dangerZoneExpanded = false;
  Timer? _dangerZoneTimer;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

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
            showSnackBar(context, state.message!, isError: true);
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is AuthProfileFetched) {
            final platform = await PackageInfo.fromPlatform();

            setState(() {
              _version = 'v${platform.version}';

              _email = state.user.email;
              _hasUsablePassword = state.user.hasUsablePassword;

              isLoading = false;
            });
          } else if (state is AuthLoggedOut) {
            if (!context.mounted) return;
            context.go(AppRoute.loginScreen);
          } else if (state is AuthAccountDeleted) {
            showSnackBar(
              context,
              "Sorry to see you go! We've deleted all traces of your existence from Helium.",
              isError: false,
              seconds: 6,
              useRootMessenger: true,
            );
            if (!context.mounted) return;
            // Close settings dialog if open
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const LoadingIndicator();
        }

        return _buildSettingsPage();
      },
    );
  }

  Widget _buildSettingsPage() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileArea(),

            const SizedBox(height: 12),

            _buildSupportArea(),

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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.08),
            context.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(AppConstants.patreonUrl)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: context.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Helium',
                        style: AppStyles.menuItem(context).copyWith(
                          color: context.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A passion project, free for everyone. '
                        'Your support helps cover Helium\'s hosting costs, and keeps development going.',
                        style: AppStyles.menuItemHint(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubSettingsArea() {
    return ShadowContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToSubSettings(
                context,
                (ctx) => showPreferences(ctx),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.semanticColors.info.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: context.semanticColors.info,
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
                            'Preferences',
                            style: AppStyles.menuItem(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tailor Helium to your tastes',
                            style: AppStyles.menuItemHint(context),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.3,
                      ),
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
          ),

          const Divider(height: 1, indent: 68),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _navigateToSubSettings(
                  context,
                  (ctx) => showExternalCalendars(ctx),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppConstants.externalCalendarIcon,
                        color: context.colorScheme.primary,
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
                            'External Calendars',
                            style: AppStyles.menuItem(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bring other calendars in to Helium',
                            style: AppStyles.menuItemHint(context),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.3,
                      ),
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
          ),

          const Divider(height: 1, indent: 68),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  _navigateToSubSettings(context, (ctx) => showFeeds(ctx)),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.rss_feed,
                        color: context.colorScheme.primary,
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
                          Text('Feeds', style: AppStyles.menuItem(context)),
                          const SizedBox(height: 2),
                          Text(
                            "Take Helium's calendars elsewhere",
                            style: AppStyles.menuItemHint(context),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.3,
                      ),
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
          ),

          if (_hasUsablePassword) const Divider(height: 1, indent: 68),

          if (_hasUsablePassword)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToSubSettings(
                  context,
                  (ctx) => showChangePassword(ctx),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: context.colorScheme.primary,
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
                              'Change Password',
                              style: AppStyles.menuItem(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update your password',
                              style: AppStyles.menuItemHint(context),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
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
            ),

          const Divider(height: 1, indent: 68),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(16),
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
                        Icons.logout_outlined,
                        color: context.semanticColors.warning,
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
                            'Logout',
                            style: AppStyles.menuItem(
                              context,
                            ).copyWith(color: context.semanticColors.warning),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out of your account',
                            style: AppStyles.menuItemHint(context),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.3,
                      ),
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
          ),
        ],
      ),
    );
  }

  /// Navigates to a sub-settings screen. In dialog mode, closes the settings
  /// dialog first, then opens the sub-dialog. This avoids double-stacked
  /// dialogs with double shadows.
  void _navigateToSubSettings(
    BuildContext context,
    void Function(BuildContext) showSubScreen,
  ) {
    if (DialogModeProvider.isDialogMode(context)) {
      // Get a context that survives the pop (Navigator's context)
      final navContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.of(context).pop();
      showSubScreen(navContext);
    } else {
      showSubScreen(context);
    }
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
        borderRadius: BorderRadius.circular(16),
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
        ),
      ],
    );
  }

  Widget _buildDangerZoneItem({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                'Are you sure you want to delete all Events? Anything associated with them, including attachments and other data, will also be deleted. This action cannot be undone.',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
