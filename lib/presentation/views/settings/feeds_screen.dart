// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/private_feed_remote_data_source.dart';
import 'package:heliumapp/data/repositories/private_feed_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/settings/feed_bloc.dart';
import 'package:heliumapp/presentation/bloc/settings/feed_event.dart';
import 'package:heliumapp/presentation/bloc/settings/feed_state.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:share_plus/share_plus.dart';

class FeedsSettingsScreen extends StatelessWidget {
  const FeedsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PrivateFeedBloc(
            privateFeedRepository: PrivateFeedRepositoryImpl(
              remoteDataSource: PrivateFeedRemoteDataSourceImpl(
                dioClient: DioClient(),
              ),
            ),
          )..add(FetchPrivateFeedUrlsEvent()),
        ),
      ],
      child: const FeedsSettingsView(),
    );
  }
}

class FeedsSettingsView extends StatefulWidget {
  const FeedsSettingsView({super.key});

  @override
  State<FeedsSettingsView> createState() => _FeedsSettingsViewState();
}

class _FeedsSettingsViewState extends State<FeedsSettingsView> {
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
                style: AppStyle.cTextStyle.copyWith(
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
    return MultiBlocListener(
      listeners: [
        BlocListener<PrivateFeedBloc, PrivateFeedState>(
          listener: (context, state) {
            if (state is PrivateFeedLoaded) {
              // if (state.calendars != null) {
              //   setState(() {
              //     _cachedExternalCalendars = state.calendars!;
              //   });
              // }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'hello world',
                    style: AppStyle.cTextStyle.copyWith(color: whiteColor),
                  ),
                  backgroundColor: greenColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is PrivateFeedError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 4),
                  ),
                );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xfff8f9fc),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 16.h),
                decoration: BoxDecoration(
                  color: whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: blackColor.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Text(
                      'Feeds',
                      style: AppStyle.bTextStyle.copyWith(
                        color: blackColor,
                      ),
                    ),
                    Icon(Icons.abc, color: transparentColor),
                  ],
                ),
              ),
              SizedBox(height: 12.v),
            ],
          ),
        ),
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
            color: blackColor.withValues(alpha: 0.04),
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
                    color: iconBgColor.withValues(alpha: 0.12),
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
                        style: AppStyle.bTextStyle.copyWith(
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
          Divider(height: 0, color: greyColor.withValues(alpha: 0.08)),
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
                    color: const Color(0xfff5f6f9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: greyColor.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    url,
                    style: AppStyle.fTextStyle.copyWith(
                      color: textColor.withValues(alpha: 0.7),
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
                          backgroundColor: buttonColor.withValues(alpha: 0.12),
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
