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
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/info_container.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/presentation/widgets/warning_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:share_plus/share_plus.dart';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsViewState();
}

class _FeedsViewState extends BasePageScreenState<FeedsScreen> {
  @override
  String get screenTitle => 'Feeds';

  @override
  IconData? get icon => Icons.rss_feed;

  @override
  ScreenType get screenType => ScreenType.subPage;

  PrivateFeedModel? _feedUrls;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is AuthProfileFetched) {
            setState(() {
              isLoading = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: InfoContainer(
        text: "Feeds allow you to take Helium's calendars elsewhere",
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
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

            return _buildFeedsEnabledArea(
              _feedUrls!.homeworkPrivateUrl,
              _feedUrls!.eventsPrivateUrl,
              _feedUrls!.courseSchedulesPrivateUrl,
            );
          } else {
            return _buildFeedsDisabledArea();
          }
        }

        return const LoadingIndicator();
      },
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
              // ),
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
                            showSnackBar(context, '$label URL copied');
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
                                  buttonContext.findRenderObject()
                                      as RenderBox?;
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
    return Expanded(
      child: Center(
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
                buttonText: 'Enable',
                onPressed: () {
                  context.read<AuthBloc>().add(EnablePrivateFeedsEvent());
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedsEnabledArea(
    String homeworkUrl,
    String eventsUrl,
    String courseScheduleUrl,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Cleanup: might need to re-evaluate web issue with this icon
            const WarningContainer(
              text:
                  'Keep private feed URLs secret. If a feed is compromised, disabling and re-enabling feeds will regenerate URLs.',
              icon: Icons.privacy_tip_outlined,
            ),

            const SizedBox(height: 12),

            _buildFeedCard(
              context: context,
              icon: Icons.assignment_outlined,
              color: context.semanticColors.warning,
              url: homeworkUrl,
              label: 'Assignments',
            ),

            _buildFeedCard(
              context: context,
              icon: Icons.date_range_outlined,
              color: context.colorScheme.primary,
              url: courseScheduleUrl,
              label: 'Class Schedules',
            ),

            _buildFeedCard(
              context: context,
              icon: Icons.event_outlined,
              color: context.semanticColors.success,
              url: eventsUrl,
              label: 'Events',
            ),

            const SizedBox(height: 25),

            HeliumElevatedButton(
              buttonText: 'Disable',
              onPressed: () async {
                context.read<AuthBloc>().add(DisablePrivateFeedsEvent());
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
