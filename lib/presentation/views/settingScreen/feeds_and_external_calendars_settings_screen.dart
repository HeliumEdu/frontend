// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/private_feed_remote_data_source.dart';
import 'package:heliumedu/data/repositories/private_feed_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/privateFeedBloc/private_feed_bloc.dart';
import 'package:heliumedu/presentation/bloc/privateFeedBloc/private_feed_event.dart';
import 'package:heliumedu/presentation/bloc/privateFeedBloc/private_feed_state.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:share_plus/share_plus.dart';

class FeedsAndExternalCalendarsSettingsScreen extends StatelessWidget {
  const FeedsAndExternalCalendarsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrivateFeedBloc(
        privateFeedRepository: PrivateFeedRepositoryImpl(
          remoteDataSource: PrivateFeedRemoteDataSourceImpl(
            dioClient: DioClient(),
          ),
        ),
      )..add(FetchPrivateFeedUrlsEvent()),
      child: const FeedSettingsView(),
    );
  }
}

class FeedSettingsView extends StatelessWidget {
  const FeedSettingsView({super.key});

  void _copyToClipboard(BuildContext context, String url, String label) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: whiteColor),
            SizedBox(width: 8.h),
            Expanded(
              child: Text(
                '$label URL copied!',
                style: AppTextStyle.cTextStyle.copyWith(
                  color: whiteColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: greenColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.h),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _shareUrl(String url) async {
    await Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: BlocBuilder<PrivateFeedBloc, PrivateFeedState>(
        builder: (context, state) {
          if (state is PrivateFeedLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    valueColor: AlwaysStoppedAnimation(whiteColor),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    'Loading Feed URLs...',
                    style: AppTextStyle.bTextStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PrivateFeedError) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.h,
                      vertical: 16.v,
                    ),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          'Feeds & External Calendars',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(width: 40.h),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Toggle row (disabled state)
                            Container(
                              padding: EdgeInsets.all(16.h),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.h),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.rss_feed,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  SizedBox(width: 12.h),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Private Feeds',
                                          style: AppTextStyle.bTextStyle
                                              .copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: 4.v),
                                        Text(
                                          'Enable to generate Private Feed URLs for your calendars',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: textColor.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: false,
                                    activeColor: primaryColor,
                                    onChanged: (val) {
                                      if (val) {
                                        context.read<PrivateFeedBloc>().add(
                                          EnablePrivateFeedsEvent(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.v),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: redColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: redColor,
                              ),
                            ),
                            SizedBox(height: 20.v),
                            Text(
                              'Error Loading Feed URLs',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12.v),
                            Text(
                              state.message,
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withOpacity(0.6),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32.v),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<PrivateFeedBloc>().add(
                                    FetchPrivateFeedUrlsEvent(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: whiteColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Retry',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

          if (state is PrivateFeedEnabling) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.v),
                  Text(
                    'Enabling Private Feeds...',
                    style: AppTextStyle.bTextStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8.v),
                  Text(
                    'This may take a moment',
                    style: AppTextStyle.cTextStyle.copyWith(
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PrivateFeedEnabled) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.v,
                      horizontal: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          'Feeds & External Calendars',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(width: 40.h),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: greenColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 40,
                                color: greenColor,
                              ),
                            ),
                            SizedBox(height: 20.v),
                            Text(
                              'Private Feeds Enabled!',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12.v),
                            Text(
                              state.message,
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withOpacity(0.6),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32.v),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<PrivateFeedBloc>().add(
                                    FetchPrivateFeedUrlsEvent(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: whiteColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Load Feed URLs',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

          if (state is PrivateFeedLoaded) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.v,
                      horizontal: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          'Feeds & External Calendars',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(width: 40.h),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.h,
                          vertical: 24.v,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toggle (enabled state)
                            Container(
                              padding: EdgeInsets.all(16.h),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.h),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.rss_feed,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 12.h),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Private Feeds',
                                          style: AppTextStyle.bTextStyle
                                              .copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: 4.v),
                                        Text(
                                          'Toggle if you want to disable Feeds',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: textColor.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: true,
                                    activeColor: primaryColor,
                                    onChanged: (val) {
                                      if (!val) {
                                        context.read<PrivateFeedBloc>().add(
                                          DisablePrivateFeedsEvent(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.v),

                            // Assignments Card
                            _buildFeedCard(
                              context: context,
                              icon: Icons.assignment_outlined,
                              iconColor: Colors.orange[600]!,
                              iconBgColor: Colors.orange,
                              title: 'Assignments',
                              url: state.privateFeed.homeworkUrl,
                              label: 'Assignments',
                              buttonColor: Colors.orange,
                            ),

                            SizedBox(height: 14.v),

                            // Class Schedule Card
                            _buildFeedCard(
                              context: context,
                              icon: Icons.calendar_today_outlined,
                              iconColor: primaryColor,
                              iconBgColor: primaryColor,
                              title: 'Class Schedule',
                              url: state.privateFeed.classSchedulesUrl,
                              label: 'Class Schedule',
                              buttonColor: primaryColor,
                            ),

                            SizedBox(height: 14.v),

                            // Events Card
                            _buildFeedCard(
                              context: context,
                              icon: Icons.event_outlined,
                              iconColor: greenColor,
                              iconBgColor: greenColor,
                              title: 'Events',
                              url: state.privateFeed.eventsUrl,
                              label: 'Events',
                              buttonColor: greenColor,
                            ),

                            SizedBox(height: 24.v),

                            // Security Warning
                            Container(
                              padding: EdgeInsets.all(16.h),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.h),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.privacy_tip_outlined,
                                      color: Colors.amber[700],
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12.h),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Keep private feed URLs secret. If a feed is compromised, disabling and re-enabling feeds will regenerate URLs.',
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: textColor.withOpacity(
                                                  0.7,
                                                ),
                                                height: 1.5,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 32.v),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PrivateFeedDisabling) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.red[600],
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.v),
                  Text(
                    'Disabling Private Feeds...',
                    style: AppTextStyle.bTextStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PrivateFeedDisabled) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.v,
                      horizontal: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          'Feeds & External Calendars',
                          style: AppTextStyle.bTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(width: 40.h),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.block_rounded,
                                size: 40,
                                color: Colors.red[600],
                              ),
                            ),
                            SizedBox(height: 20.v),
                            Text(
                              'Private Feeds Disabled',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 12.v),
                            Text(
                              state.message,
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withOpacity(0.6),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32.v),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<PrivateFeedBloc>().add(
                                    EnablePrivateFeedsEvent(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: whiteColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Enable Again',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

          return const SizedBox.shrink();
        },
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.h),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 14.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.bTextStyle.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: Colors.grey.withOpacity(0.08)),
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.h,
                    vertical: 12.v,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: SelectableText(
                    url,
                    style: AppTextStyle.fTextStyle.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                      height: 1.5,
                    ),
                    maxLines: 2,
                  ),
                ),
                SizedBox(height: 12.v),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _copyToClipboard(context, url, label),
                          icon: Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: whiteColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.h),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () => _shareUrl(url),
                        icon: Icon(
                          Icons.share_outlined,
                          color: buttonColor,
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: buttonColor.withOpacity(0.12),
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
    );
  }
}
