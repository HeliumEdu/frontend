// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/data/models/auth/update_settings_request_model.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenViewState();
}

class _SettingsScreenViewState extends BasePageScreenState<SettingsScreen> {
  @override
  String get screenTitle => 'Settings';

  @override
  ScreenType get screenType => ScreenType.subPage;

  @override
  bool get showLogout => true;

  final BasicFormController _deleteAccountFormController =
      BasicFormController();
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();

  final themeNotifier = ThemeNotifier();

  // State
  String _username = '';
  String _email = '';
  String _version = '';

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

  @override
  void dispose() {
    _deleteAccountPasswordController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is AuthProfileFetched) {
            final platform = await PackageInfo.fromPlatform();

            setState(() {
              _version = 'v${platform.version}';

              _username = state.user.username;
              _email = state.user.email;

              isLoading = false;
            });
          } else if (state is AuthLoggedOut) {
            if (context.mounted) {
              context.go(AppRoutes.loginScreen);
            }
          } else if (state is AuthAccountDeleted) {
            showSnackBar(
              context,
              'Sorry to see you go! We\'ve deleted all traces of your existence from Helium.',
              isError: false,
              seconds: 6,
            );
            if (context.mounted) {
              context.go(AppRoutes.loginScreen);
            }
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    // TODO: Blocker for Web: on larger screens, open settings as dialog instead of nav (ensure sub-pages also navigate within the popped up dialog)
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
            // TODO: Feature Parity: implement ability to change username, email
            _buildProfileArea(),

            const SizedBox(height: 12),

            _buildSubSettingsArea(),

            const SizedBox(height: 12),

            // TODO: Feature Parity: implement section for import/export, re-importing example schedule

            // TODO: Feature Parity: implement ability to delete all events
            _buildDeleteAccountArea(),

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
      padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      label: 'Username',
                      initialValue: _username,
                      readOnly: true,
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      label: 'Email',
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

  Widget _buildSubSettingsArea() {
    return ShadowContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push(AppRoutes.preferencesScreen);
              },
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
                          Text('Preferences', style: AppStyles.menuItem(context)),
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
                context.push(AppRoutes.externalCalendarsScreen);
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
                        Icons.cloud_download,
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
              onTap: () {
                context.push(AppRoutes.feedsScreen);
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

          const Divider(height: 1, indent: 68),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push(AppRoutes.changePasswordScreen);
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
        ],
      ),
    );
  }

  Widget _buildDeleteAccountArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDeleteAccountDialog(context),
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
                    Icons.delete_outline,
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
                        'Delete Account',
                        style: AppStyles.menuItem(
                          context,
                        ).copyWith(color: context.colorScheme.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permanently delete your account',
                        style: AppStyles.menuItemHint(context),
                      ),
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
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext parentContext) {
    _deleteAccountPasswordController.text = '';
    bool isSubmitting = false;
    bool obscurePassword = true;

    // TODO: Cleanup: refactor to a separate class
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

              final password = _deleteAccountPasswordController.text.trim();

              context.pop();

              context.read<AuthBloc>().add(
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
                        'To permanently delete your account—and all data you have stored in Helium—confirm your password below. This action cannot be undone.',
                        style: AppStyles.standardBodyText(context),
                      ),
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
                          context.pop();
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
