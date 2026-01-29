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
import 'package:heliumapp/presentation/widgets/page_header.dart';
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
    // TODO: make this prettier
    return Column(
      children: [
        Text(
          "Feeds allow you to take Helium's calendars elsewhere",
          style: context.paragraphText,
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthProfileFetched) {
          if (state.user.settings?.privateSlug != null) {
            final privateSlug = state.user.settings?.privateSlug;

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

        return buildLoading();
      },
    );
  }

  Widget _buildFeedCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String url,
    required String label,
    required Color buttonColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padding(
            //   padding: Responsive.getCardPadding(context),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
                    children: [Text(title, style: context.sectionHeading)],
                  ),
                ),
              ],
              // ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                            color: context.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: SelectableText(
                            url,
                            style: context.fTextStyle.copyWith(
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              height: 1.5,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: HeliumElevatedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                              showSnackBar(context, '$label URL copied');
                            },
                            icon: Icons.copy,
                            buttonText: 'Copy',
                            backgroundColor: buttonColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Builder(
                        builder: (buttonContext) => SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () {
                              final box = buttonContext.findRenderObject() as RenderBox?;
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
                            icon: Icon(
                              Icons.share_outlined,
                              color: buttonColor,
                              size: Responsive.getIconSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: buttonColor.withValues(
                                alpha: 0.12,
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
              Text(
                'Feeds are Disabled',
                style: context.bTextStyle.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 18,
                    tablet: 19,
                    desktop: 20,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: HeliumElevatedButton(
                  buttonText: 'Enable',
                  onPressed: () {
                    context.read<AuthBloc>().add(EnablePrivateFeedsEvent());
                  },
                ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.semanticColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.semanticColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.semanticColors.warning.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: context.semanticColors.warning,
                      size: Responsive.getIconSize(
                        context,
                        mobile: 20,
                        tablet: 22,
                        desktop: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Keep private feed URLs secret. If a feed is compromised, disabling and re-enabling feeds will regenerate URLs.',
                          style: context.eTextStyle.copyWith(
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            height: 1.5,
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 13,
                              tablet: 14,
                              desktop: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _buildFeedCard(
              context: context,
              icon: Icons.assignment_outlined,
              iconColor: Colors.orange[600]!,
              iconBgColor: Colors.orange,
              title: 'Assignments',
              url: homeworkUrl,
              label: 'Assignments',
              buttonColor: Colors.orange,
            ),

            _buildFeedCard(
              context: context,
              icon: Icons.calendar_today_outlined,
              iconColor: context.colorScheme.primary,
              iconBgColor: context.colorScheme.primary,
              title: 'Class Schedules',
              url: courseScheduleUrl,
              label: 'Class Schedules',
              buttonColor: context.colorScheme.primary,
            ),

            _buildFeedCard(
              context: context,
              icon: Icons.event_outlined,
              iconColor: context.semanticColors.success,
              iconBgColor: context.semanticColors.success,
              title: 'Events',
              url: eventsUrl,
              label: 'Events',
              buttonColor: context.semanticColors.success,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: HeliumElevatedButton(
                buttonText: 'Disable',
                onPressed: () async {
                  context.read<AuthBloc>().add(DisablePrivateFeedsEvent());
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
