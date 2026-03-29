// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:share_plus/share_plus.dart';

class FeedsScreen extends StatefulWidget {
  final UserSettingsModel? userSettings;

  const FeedsScreen({super.key, this.userSettings});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  PrivateFeedModel? _feedUrls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: InfoContainer(
            text: "Feeds allow you to take Helium's calendars elsewhere",
          ),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthProfileFetched) {
              if (state.user.settings.privateSlug != null) {
                final privateSlug = state.user.settings.privateSlug;

                _feedUrls = PrivateFeedModel(
                  eventsPrivateUrl:
                      '${ApiUrl.baseUrl}/feed/private/$privateSlug/events.ics',
                  homeworkPrivateUrl:
                      '${ApiUrl.baseUrl}/feed/private/$privateSlug/homework.ics',
                  courseSchedulesPrivateUrl:
                      '${ApiUrl.baseUrl}/feed/private/$privateSlug/courseschedules.ics',
                );

                return Expanded(
                  child: _buildFeedsEnabledArea(
                    _feedUrls!.homeworkPrivateUrl,
                    _feedUrls!.eventsPrivateUrl,
                    _feedUrls!.courseSchedulesPrivateUrl,
                  ),
                );
              } else {
                return Expanded(child: _buildFeedsDisabledArea());
              }
            }

            return const LoadingIndicator();
          },
        ),
      ],
    );
  }

  Widget _buildFeedCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String url,
    required String label,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppStyles.featureText(context)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          url,
                          style: AppStyles.standardBodyTextLight(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HeliumElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url));
                            SnackBarHelper.show(
                              context,
                              '$label feed URL copied',
                            );
                          },
                          icon: Icons.copy,
                          buttonText: 'Copy',
                          backgroundColor: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Builder(
                        builder: (buttonContext) => AspectRatio(
                          aspectRatio: 1,
                          child: IconButton(
                            onPressed: () {
                              final box =
                                  buttonContext.findRenderObject() as RenderBox?;
                              final sharePositionOrigin = box != null
                                  ? box.localToGlobal(Offset.zero) & box.size
                                  : null;

                              SharePlus.instance.share(
                                ShareParams(
                                  text: url,
                                  sharePositionOrigin: sharePositionOrigin,
                                ),
                              );
                            },
                            icon: Icon(Icons.share_outlined, color: color),
                            style: IconButton.styleFrom(
                              backgroundColor: color.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedsDisabledArea() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.block_rounded,
                size: Responsive.getIconSize(
                  context,
                  mobile: 40,
                  tablet: 44,
                  desktop: 48,
                ),
                color: context.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text('Feeds are Disabled', style: AppStyles.headingText(context)),
            const SizedBox(height: 25),

            HeliumElevatedButton(
              icon: Icons.link,
              buttonText: 'Enable',
              onPressed: () {
                context.read<AuthBloc>().add(EnablePrivateFeedsEvent());
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDisableFeedsDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: context.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text('Disable All Feeds', style: AppStyles.pageTitle(context)),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Text(
                'Disabling feeds will break any existing integrations. Enabling again later will generated new URLs, and will not re-establish these connections. This action cannot be undone.',
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
                        buttonText: 'Disable',
                        backgroundColor: context.colorScheme.error,
                        isLoading: isSubmitting,
                        onPressed: () {
                          setState(() {
                            isSubmitting = true;
                          });

                          Navigator.of(dialogContext).pop();

                          parentContext
                              .read<AuthBloc>()
                              .add(DisablePrivateFeedsEvent());
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

  Widget _buildFeedsEnabledArea(
    String homeworkUrl,
    String eventsUrl,
    String courseScheduleUrl,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeliumElevatedButton(
            icon: Icons.link_off,
            buttonText: 'Disable All',
            onPressed: () => _showDisableFeedsDialog(context),
            backgroundColor: context.colorScheme.error,
          ),

          const SizedBox(height: 12),

          const WarningContainer(
            text:
                'Keep private feed URLs secret. Disabling and re-enabling a feed will regenerate its URL.',
            icon: Icons.privacy_tip_outlined,
          ),

          const SizedBox(height: 12),

          _buildFeedCard(
            context: context,
            icon: AppConstants.assignmentIcon,
            color: PlannerTypeColors.homework,
            url: homeworkUrl,
            label: 'Assignments',
          ),

          _buildFeedCard(
            context: context,
            icon: AppConstants.courseScheduleIcon,
            color: PlannerTypeColors.classSchedules,
            url: courseScheduleUrl,
            label: 'Class Schedules',
          ),

          _buildFeedCard(
            context: context,
            icon: AppConstants.eventIcon,
            color: PlannerTypeColors.events(widget.userSettings?.eventsColor),
            url: eventsUrl,
            label: 'Events',
          ),
        ],
      ),
    );
  }
}
