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
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/presentation/ui/feedback/confirm_action_dialog.dart';
import 'package:heliumapp/presentation/ui/feedback/info_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';
import 'package:share_plus/share_plus.dart';

class FeedsScreen extends StatefulWidget {
  final UserModel user;

  const FeedsScreen({super.key, required this.user});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  PrivateFeedModel? get _feedUrls {
    final slug = widget.user.settings.privateSlug;
    return slug != null
        ? PrivateFeedModel(
            eventsPrivateUrl: '${ApiUrl.baseUrl}/feed/private/$slug/events.ics',
            homeworkPrivateUrl:
                '${ApiUrl.baseUrl}/feed/private/$slug/homework.ics',
            courseSchedulesPrivateUrl:
                '${ApiUrl.baseUrl}/feed/private/$slug/courseschedules.ics',
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          SnackBarHelper.show(context, state.message!, type: SnackType.error);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoContainer(
              text: "Feeds allow you to take Helium's calendars elsewhere.",
              trailing: HeliumIconButton(
                icon: Icons.menu_book_outlined,
                backgroundColor: context.colorScheme.onSurfaceVariant,
                tooltip: 'Learn more',
                onPressed: () =>
                    UrlHelpers.launchWebUrl(AppConstants.supportFeedsUrl),
              ),
            ),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const LoadingIndicator();
              }

              final feedUrls = _feedUrls;
              if (feedUrls != null) {
                return Expanded(
                  child: _buildFeedsEnabledArea(
                    feedUrls.homeworkPrivateUrl,
                    feedUrls.eventsPrivateUrl,
                    feedUrls.courseSchedulesPrivateUrl,
                  ),
                );
              } else {
                return Expanded(child: _buildFeedsDisabledArea());
              }
            },
          ),
        ],
      ),
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
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10.0),
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
                Row(
                  children: [
                    Expanded(
                      child: HeliumElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: url));
                          SnackBarHelper.show(
                            context,
                            '$label feed URL copied.',
                            copyable: false,
                          );
                        },
                        icon: Icons.copy,
                        buttonText: 'Copy',
                        backgroundColor: color,
                        minHeight: 36,
                        // Standard density so the Copy and Share buttons stay a
                        // consistent 36px on both mobile and web instead of the
                        // adaptive density shrinking them on desktop.
                        visualDensity: VisualDensity.standard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (buttonContext) => IconButton(
                        onPressed: () async {
                          final box =
                              buttonContext.findRenderObject() as RenderBox?;
                          final sharePositionOrigin = box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null;

                          try {
                            await SharePlus.instance.share(
                              ShareParams(
                                text: url,
                                sharePositionOrigin: sharePositionOrigin,
                              ),
                            );
                          } on PlatformException {
                            final context =
                                rootScaffoldMessengerKey.currentContext;
                            if (context != null && context.mounted) {
                              SnackBarHelper.show(
                                context,
                                'Failed to share link.',
                                type: SnackType.error,
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.share_outlined, color: color),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: color.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ],
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
      child: HeliumFullScreenScrollView(
        child: Column(
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.0),
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

  Future<void> _showDisableFeedsDialog() async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Disable All Feeds',
      message:
          'Disabling Feeds will break any existing integrations. Enabling again later will generate new URLs, and will not re-establish these connections. This action cannot be undone.',
      actionText: 'Disable',
      icon: Icons.warning_rounded,
    );
    if (!confirmed || !mounted) return;
    context.read<AuthBloc>().add(DisablePrivateFeedsEvent());
  }

  Widget _buildFeedsEnabledArea(
    String homeworkUrl,
    String eventsUrl,
    String courseScheduleUrl,
  ) {
    return HeliumFullScreenScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            color: widget.user.settings.eventsColor,
            url: eventsUrl,
            label: 'Events',
          ),

          const Divider(height: 24),

          HeliumElevatedButton(
            icon: Icons.link_off,
            buttonText: 'Disable All',
            onPressed: _showDisableFeedsDialog,
            backgroundColor: context.colorScheme.error,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
