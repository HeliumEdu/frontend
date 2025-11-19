import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/ical_feed_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/ical_feed_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/iCalFeedBloc/ical_feed_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/iCalFeedBloc/ical_feed_event.dart';
import 'package:helium_student_flutter/presentation/bloc/iCalFeedBloc/ical_feed_state.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';

class FeedSettingsScreen extends StatelessWidget {
  const FeedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ICalFeedBloc(
        iCalFeedRepository: ICalFeedRepositoryImpl(
          remoteDataSource: ICalFeedRemoteDataSourceImpl(
            dioClient: DioClient(),
          ),
        ),
      )..add(FetchICalFeedUrlsEvent()),
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
      body: BlocBuilder<ICalFeedBloc, ICalFeedState>(
        builder: (context, state) {
          if (state is ICalFeedLoading) {
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

          if (state is ICalFeedError) {
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
                          'Feed Settings',
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
                                          'Enable to generate iCal URLs for your calendars',
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
                                        context.read<ICalFeedBloc>().add(
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
                                  context.read<ICalFeedBloc>().add(
                                    FetchICalFeedUrlsEvent(),
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

          if (state is ICalFeedEnabling) {
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

          if (state is ICalFeedEnabled) {
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
                          'Feed Settings',
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
                                  context.read<ICalFeedBloc>().add(
                                    FetchICalFeedUrlsEvent(),
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

          if (state is ICalFeedLoaded) {
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
                          'Feed Settings',
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
                                          'Toggle to disable if you no longer want feeds to work',
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
                                        context.read<ICalFeedBloc>().add(
                                          DisablePrivateFeedsEvent(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.v),
                            Text(
                              'Calendar Feeds',
                              style: AppTextStyle.aTextStyle.copyWith(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8.v),
                            Text(
                              'Sync your schedule with Google Calendar or other calendar apps',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: textColor.withOpacity(0.6),
                                height: 1.4,
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
                              subtitle: 'Homework & assignments',
                              url: state.icalFeed.homeworkUrl,
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
                              subtitle: 'All classes & lectures',
                              url: state.icalFeed.allCalendarUrl,
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
                              subtitle: 'Campus events & activities',
                              url: state.icalFeed.eventsUrl,
                              label: 'Events',
                              buttonColor: greenColor,
                            ),

                            SizedBox(height: 24.v),

                            // Information Box
                            Container(
                              padding: EdgeInsets.all(16.h),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.h),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: primaryColor,
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
                                          'About Private Feeds',
                                          style: AppTextStyle.bTextStyle
                                              .copyWith(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                        ),
                                        SizedBox(height: 6.v),
                                        Text(
                                          'Private feed URLs can be added to Google Calendar, Outlook, Apple Calendar, and other compatible calendar applications to sync your Helium schedule.',
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

                            SizedBox(height: 16.v),

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
                                      Icons.lock_outline_rounded,
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
                                          'Security Notice',
                                          style: AppTextStyle.bTextStyle
                                              .copyWith(
                                                color: Colors.amber[900],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                        ),
                                        SizedBox(height: 6.v),
                                        Text(
                                          'Keep your feed URLs private and secure. If compromised, regenerate them by disabling and re-enabling private feeds.',
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

          if (state is ICalFeedDisabling) {
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

          if (state is ICalFeedDisabled) {
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
                          'Feed Settings',
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
                                  context.read<ICalFeedBloc>().add(
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
    required String subtitle,
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
                      SizedBox(height: 2.v),
                      Text(
                        subtitle,
                        style: AppTextStyle.fTextStyle.copyWith(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
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
                Text(
                  'iCal Feed URL',
                  style: AppTextStyle.fTextStyle.copyWith(
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10.v),
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
                    maxLines: 4,
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
