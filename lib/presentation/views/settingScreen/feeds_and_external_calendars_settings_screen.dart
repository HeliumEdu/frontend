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
import 'package:heliumedu/data/datasources/external_calendar_remote_data_source.dart';
import 'package:heliumedu/data/datasources/private_feed_remote_data_source.dart';
import 'package:heliumedu/data/models/planner/external_calendar_model.dart';
import 'package:heliumedu/data/models/planner/external_calendar_request_model.dart';
import 'package:heliumedu/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumedu/data/repositories/private_feed_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/externalCalendarBloc/external_calendar_bloc.dart';
import 'package:heliumedu/presentation/bloc/externalCalendarBloc/external_calendar_event.dart';
import 'package:heliumedu/presentation/bloc/externalCalendarBloc/external_calendar_state.dart';
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
    final dioClient = DioClient();
    final externalCalendarRepository = ExternalCalendarRepositoryImpl(
      remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
        dioClient: dioClient,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ExternalCalendarBloc(
            externalCalendarRepository: externalCalendarRepository,
          )..add(FetchAllExternalCalendarsEvent()),
        ),
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
      child: const FeedsAndExternalCalendarsSettingsView(),
    );
  }
}

class FeedsAndExternalCalendarsSettingsView extends StatefulWidget {
  const FeedsAndExternalCalendarsSettingsView({super.key});

  @override
  State<FeedsAndExternalCalendarsSettingsView> createState() => _FeedsAndExternalCalendarsSettingsViewState();
}

Color dialogSelectedColor = const Color(0xFF26A69A);
String? selectedDefaultPreference;
String? selectedTimezonePreference;
String? selectedReminderPreference;
String? selectedReminderTypePreference;

class _FeedsAndExternalCalendarsSettingsViewState extends State<FeedsAndExternalCalendarsSettingsView> {
  late TextEditingController _calendarTitleController;
  late TextEditingController _calendarUrlController;
  static const String _defaultExternalCalendarTitle = 'Holidays';
  static const String _defaultExternalCalendarUrl =
      'https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics';
  static const Color _defaultExternalCalendarColor = Color(0xFFffad46);

  Color _externalDialogSelectedColor = _defaultExternalCalendarColor;
  bool _externalShownOnCalendar = false;
  bool _isExternalCalendarDialogOpen = false;
  List<ExternalCalendarModel> _cachedExternalCalendars = [];

  static const List<Color> _externalCalendarColors = [
    Color(0xFFac725e),
    Color(0xFFd06b64),
    Color(0xFFf83a22),
    Color(0xFFfa573c),
    Color(0xFFffad46),
    Color(0xFF42d692),
    Color(0xFF16a765),
    Color(0xFF7bd148),
    Color(0xFFb3dc6c),
    Color(0xFFfad165),
    Color(0xFF92e1c0),
    Color(0xFF9fe1e7),
    Color(0xFF9fc6e7),
    Color(0xFF4986e7),
    Color(0xFF9a9cff),
    Color(0xFFb99aff),
    Color(0xFFc2c2c2),
    Color(0xFFcabdbf),
    Color(0xFFcca6ac),
    Color(0xFFf691b2),
    Color(0xFFcd74e6),
    Color(0xFFa47ae2),
  ];

  @override
  void initState() {
    super.initState();
    _calendarTitleController = TextEditingController();
    _calendarUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _calendarTitleController.dispose();
    _calendarUrlController.dispose();
    super.dispose();
  }

  void _resetExternalCalendarForm() {
    _calendarTitleController.text = _defaultExternalCalendarTitle;
    _calendarUrlController.text = _defaultExternalCalendarUrl;
    _externalDialogSelectedColor = _defaultExternalCalendarColor;
    _externalShownOnCalendar = false;
  }

  Color _externalHexToColor(String hex) {
    try {
      String value = hex.trim().toLowerCase();
      if (!value.startsWith('#')) {
        value = '#$value';
      }
      if (value.length == 4) {
        final r = value[1], g = value[2], b = value[3];
        value = '#$r$r$g$g$b$b';
      } else if (value.length == 9) {
        value = '#${value.substring(3)}';
      }
      return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF16a765);
    }
  }

  String _externalColorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  }

  void _showExternalCalendarDialog({ExternalCalendarModel? existingCalendar}) {
    final bool isEdit = existingCalendar != null;

    if (isEdit) {
      _calendarTitleController.text = existingCalendar!.title;
      _calendarUrlController.text = existingCalendar.url;
      _externalDialogSelectedColor = _externalHexToColor(
        existingCalendar.color,
      );
      _externalShownOnCalendar = existingCalendar.shownOnCalendar;
    } else {
      _resetExternalCalendarForm();
    }

    setState(() {
      _isExternalCalendarDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final externalBloc = context.read<ExternalCalendarBloc>();
        bool isSubmitting = false;
        String? actionError;

        void closeDialog() {
          if (Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
          setState(() {
            _isExternalCalendarDialogOpen = false;
          });
          _resetExternalCalendarForm();
        }

        void openColorPicker(StateSetter setDialogState) {
          showDialog(
            context: dialogContext,
            builder: (colorDialogContext) => AlertDialog(
              backgroundColor: whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              title: Text(
                'Select Color',
                style: AppTextStyle.bTextStyle.copyWith(
                  color: blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _externalCalendarColors
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _externalDialogSelectedColor = color;
                            });
                            Navigator.pop(colorDialogContext);
                          },
                          child: Container(
                            width: 40.adaptSize,
                            height: 40.adaptSize,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8.adaptSize),
                              border: Border.all(
                                color: _externalDialogSelectedColor == color
                                    ? blackColor
                                    : transparentColor,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return BlocProvider.value(
              value: externalBloc,
              child: BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
                listener: (listenerContext, state) {
                  if (state is ExternalCalendarActionInProgress) {
                    setDialogState(() {
                      isSubmitting = true;
                      actionError = null;
                    });
                  } else if (state is ExternalCalendarActionSuccess) {
                    setDialogState(() {
                      isSubmitting = false;
                      actionError = null;
                    });
                    closeDialog();
                  } else if (state is ExternalCalendarActionError) {
                    setDialogState(() {
                      isSubmitting = false;
                      actionError = state.message;
                    });
                  }
                },
                child: Dialog(
                  backgroundColor: transparentColor,
                  child: Container(
                    padding: EdgeInsets.all(24.h),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(16.adaptSize),
                      boxShadow: [
                        BoxShadow(
                          color: blackColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              isEdit
                                  ? 'Edit External Calendar'
                                  : 'Add External Calendar',
                              style: AppTextStyle.aTextStyle.copyWith(
                                color: blackColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 28.v),
                          Text(
                            'Name',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          TextField(
                            controller: _calendarTitleController,
                            decoration: InputDecoration(
                              hintText: 'Enter calendar name',
                              hintStyle: AppTextStyle.iTextStyle.copyWith(
                                color: textColor.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: softGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.h,
                                vertical: 10.v,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.v),
                          Text(
                            'URL',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          TextField(
                            controller: _calendarUrlController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              hintText: 'https://...',
                              hintStyle: AppTextStyle.iTextStyle.copyWith(
                                color: textColor.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: softGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.h,
                                vertical: 10.v,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.v),
                          Row(
                            children: [
                              Text(
                                'Color',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: blackColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 12.h),
                              GestureDetector(
                                onTap: isSubmitting
                                    ? null
                                    : () => openColorPicker(setDialogState),
                                child: Container(
                                  width: 33,
                                  height: 33,
                                  decoration: BoxDecoration(
                                    color: _externalDialogSelectedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: greyColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.v),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Show on calendar',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Switch.adaptive(
                                value: _externalShownOnCalendar,
                                activeColor: primaryColor,
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        setDialogState(() {
                                          _externalShownOnCalendar = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                          if (actionError != null) ...[
                            SizedBox(height: 16.v),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.h),
                              decoration: BoxDecoration(
                                color: redColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  10.adaptSize,
                                ),
                                border: Border.all(
                                  color: redColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                actionError!,
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: redColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 28.v),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSubmitting ? null : closeDialog,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.v,
                                    ),
                                    side: BorderSide(
                                      color: primaryColor,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8.adaptSize,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: AppTextStyle.cTextStyle.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.h),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          final name = _calendarTitleController
                                              .text
                                              .trim();
                                          final url = _calendarUrlController
                                              .text
                                              .trim();

                                          if (name.isEmpty) {
                                            setDialogState(() {
                                              actionError =
                                                  'Please enter a calendar name';
                                            });
                                            return;
                                          }

                                          if (url.isEmpty) {
                                            setDialogState(() {
                                              actionError =
                                                  'Please enter a calendar URL';
                                            });
                                            return;
                                          }

                                          setDialogState(() {
                                            actionError = null;
                                            isSubmitting = true;
                                          });

                                          final payload =
                                              ExternalCalendarRequestModel(
                                                title: name,
                                                url: url,
                                                color: _externalColorToHex(
                                                  _externalDialogSelectedColor,
                                                ),
                                                shownOnCalendar:
                                                    _externalShownOnCalendar,
                                              );

                                          if (isEdit &&
                                              existingCalendar != null) {
                                            context
                                                .read<ExternalCalendarBloc>()
                                                .add(
                                                  UpdateExternalCalendarEvent(
                                                    calendarId:
                                                        existingCalendar.id,
                                                    payload: payload,
                                                  ),
                                                );
                                          } else {
                                            context
                                                .read<ExternalCalendarBloc>()
                                                .add(
                                                  CreateExternalCalendarEvent(
                                                    payload: payload,
                                                  ),
                                                );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubmitting
                                        ? primaryColor.withOpacity(0.6)
                                        : primaryColor,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.v,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8.adaptSize,
                                      ),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? SizedBox(
                                          width: 20.adaptSize,
                                          height: 20.adaptSize,
                                          child: CircularProgressIndicator(
                                            color: whiteColor,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Confirm',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: whiteColor,
                                                fontWeight: FontWeight.w600,
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
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isExternalCalendarDialogOpen = false;
      });
      _resetExternalCalendarForm();
    });
  }

  void _handleExternalCalendarToggle(
    ExternalCalendarModel calendar,
    bool value,
  ) {
    final payload = ExternalCalendarRequestModel(
      title: calendar.title,
      url: calendar.url,
      color: calendar.color,
      shownOnCalendar: value,
    );

    context.read<ExternalCalendarBloc>().add(
      UpdateExternalCalendarEvent(calendarId: calendar.id, payload: payload),
    );
  }

  Widget _buildExternalCalendarCard(
    ExternalCalendarModel calendar,
    bool isActionInProgress,
  ) {
    final Color calendarColor = _externalHexToColor(calendar.color);
    return Container(
      margin: EdgeInsets.only(bottom: 12.v),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10.adaptSize),
        border: Border.all(color: softGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: calendarColor,
              borderRadius: BorderRadius.circular(3.adaptSize),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calendar.title,
                  style: AppTextStyle.cTextStyle.copyWith(
                    color: blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.v),
                Text(
                  calendar.url,
                  style: AppTextStyle.iTextStyle.copyWith(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12.fSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.h),
          Switch.adaptive(
            value: calendar.shownOnCalendar,
            activeColor: primaryColor,
            onChanged: isActionInProgress
                ? null
                : (value) => _handleExternalCalendarToggle(calendar, value),
          ),
          SizedBox(width: 8.h),
          GestureDetector(
            onTap: isActionInProgress
                ? null
                : () => _showExternalCalendarDialog(existingCalendar: calendar),
            child: Icon(
              Icons.edit_outlined,
              color: isActionInProgress ? greyColor : primaryColor,
              size: 20.adaptSize,
            ),
          ),
          SizedBox(width: 12.h),
          GestureDetector(
            onTap: isActionInProgress
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (confirmContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                          title: Text(
                            'Delete Calendar',
                            style: AppTextStyle.bTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${calendar.title}"? This action cannot be undone.',
                            style: AppTextStyle.cTextStyle.copyWith(
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(confirmContext);
                              },
                              child: Text(
                                'Cancel',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(confirmContext);
                                context.read<ExternalCalendarBloc>().add(
                                  DeleteExternalCalendarEvent(
                                    calendarId: calendar.id,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: redColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8.adaptSize,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Delete',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: whiteColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
            child: Icon(
              Icons.delete_outline,
              color: isActionInProgress ? greyColor : redColor,
              size: 20.adaptSize,
            ),
          ),
        ],
      ),
    );
  }

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
    return MultiBlocListener(
      listeners: [
        BlocListener<ExternalCalendarBloc, ExternalCalendarState>(
          listener: (context, state) {
            if (state is ExternalCalendarActionSuccess) {
              if (state.calendars != null) {
                setState(() {
                  _cachedExternalCalendars = state.calendars!;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
                  ),
                  backgroundColor: greenColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ExternalCalendarActionError) {
              if (!_isExternalCalendarDialogOpen) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(
                        color: whiteColor,
                      ),
                    ),
                    backgroundColor: redColor,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } else if (state is ExternalCalendarsLoaded) {
              setState(() {
                _cachedExternalCalendars = state.calendars;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
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
                      color: blackColor.withOpacity(0.05),
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
                      'Feeds & External Calendars',
                      style: AppTextStyle.bTextStyle.copyWith(
                        color: blackColor,
                      ),
                    ),
                    Icon(Icons.abc, color: transparentColor),
                  ],
                ),
              ),
              SizedBox(height: 12.v),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'External Calendars',
                              style: AppTextStyle.bTextStyle.copyWith(
                                color: blackColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showExternalCalendarDialog,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 8.v,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(
                                    8.adaptSize,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: whiteColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.v),
                        BlocBuilder<
                          ExternalCalendarBloc,
                          ExternalCalendarState
                        >(
                          buildWhen: (previous, current) {
                            return current is ExternalCalendarsLoading ||
                                current is ExternalCalendarsLoaded ||
                                current is ExternalCalendarsError ||
                                current is ExternalCalendarActionSuccess ||
                                current is ExternalCalendarActionInProgress ||
                                current is ExternalCalendarActionError;
                          },
                          builder: (context, state) {
                            final bool isActionInProgress =
                                state is ExternalCalendarActionInProgress;

                            if (state is ExternalCalendarsLoading &&
                                _cachedExternalCalendars.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.v),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (state is ExternalCalendarsError &&
                                _cachedExternalCalendars.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16.h),
                                decoration: BoxDecoration(
                                  color: redColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                    10.adaptSize,
                                  ),
                                  border: Border.all(
                                    color: redColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  state.message,
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: redColor,
                                  ),
                                ),
                              );
                            }

                            List<ExternalCalendarModel> calendars;
                            if (state is ExternalCalendarsLoaded) {
                              calendars = state.calendars;
                            } else if (state is ExternalCalendarActionSuccess &&
                                state.calendars != null) {
                              calendars = state.calendars!;
                            } else {
                              calendars = _cachedExternalCalendars;
                            }

                            if (calendars.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20.h),
                                decoration: BoxDecoration(
                                  color: softGrey,
                                  borderRadius: BorderRadius.circular(
                                    10.adaptSize,
                                  ),
                                ),
                                child: Text(
                                  'No external calendars added yet.',
                                  style: AppTextStyle.cTextStyle.copyWith(
                                    color: textColor.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return Column(
                              children: calendars
                                  .map(
                                    (calendar) => _buildExternalCalendarCard(
                                      calendar,
                                      isActionInProgress,
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                        BlocBuilder<PrivateFeedBloc, PrivateFeedState>(
                          buildWhen: (previous, current) {
                            return current is PrivateFeedLoading ||
                                current is PrivateFeedLoaded ||
                                current is PrivateFeedError ||
                                current is PrivateFeedEnabling ||
                                current is PrivateFeedDisabling ||
                                current is PrivateFeedEnabled ||
                                current is PrivateFeedDisabled;
                          },
                          builder: (context, state) {
                            if (state is PrivateFeedLoading) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: primaryColor,
                                      valueColor: AlwaysStoppedAnimation(
                                        whiteColor,
                                      ),
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
                                            color: greyColor.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                            style: AppTextStyle.bTextStyle
                                                .copyWith(color: textColor),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Toggle row (disabled state)
                                              Container(
                                                padding: EdgeInsets.all(16.h),
                                                decoration: BoxDecoration(
                                                  color: whiteColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: blackColor
                                                          .withOpacity(0.04),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        10.h,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: redColor
                                                            .withOpacity(0.08),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.rss_feed,
                                                        color: redColor,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12.h),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Private Feeds',
                                                            style: AppTextStyle
                                                                .bTextStyle
                                                                .copyWith(
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          SizedBox(height: 4.v),
                                                          Text(
                                                            'Enable to generate Private Feed URLs for your calendars',
                                                            style: AppTextStyle
                                                                .cTextStyle
                                                                .copyWith(
                                                                  color: textColor
                                                                      .withOpacity(
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
                                                          context
                                                              .read<
                                                                PrivateFeedBloc
                                                              >()
                                                              .add(
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
                                                  color: redColor.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
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
                                                style: AppTextStyle.bTextStyle
                                                    .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 12.v),
                                              Text(
                                                state.message,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.6),
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
                                                    context
                                                        .read<PrivateFeedBloc>()
                                                        .add(
                                                          FetchPrivateFeedUrlsEvent(),
                                                        );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryColor,
                                                    foregroundColor: whiteColor,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Retry',
                                                    style: AppTextStyle
                                                        .cTextStyle
                                                        .copyWith(
                                                          color: whiteColor,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                            color: greyColor.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                            style: AppTextStyle.bTextStyle
                                                .copyWith(color: textColor),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: greenColor.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
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
                                                style: AppTextStyle.bTextStyle
                                                    .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 12.v),
                                              Text(
                                                state.message,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.6),
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
                                                    context
                                                        .read<PrivateFeedBloc>()
                                                        .add(
                                                          FetchPrivateFeedUrlsEvent(),
                                                        );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryColor,
                                                    foregroundColor: whiteColor,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Load Feed URLs',
                                                    style: AppTextStyle
                                                        .cTextStyle
                                                        .copyWith(
                                                          color: whiteColor,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                            color: greyColor.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                            style: AppTextStyle.bTextStyle
                                                .copyWith(color: textColor),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Toggle (enabled state)
                                              Container(
                                                padding: EdgeInsets.all(16.h),
                                                decoration: BoxDecoration(
                                                  color: whiteColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: blackColor
                                                          .withOpacity(0.04),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        10.h,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: primaryColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Private Feeds',
                                                            style: AppTextStyle
                                                                .bTextStyle
                                                                .copyWith(
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          SizedBox(height: 4.v),
                                                          Text(
                                                            'Toggle if you want to disable Feeds',
                                                            style: AppTextStyle
                                                                .cTextStyle
                                                                .copyWith(
                                                                  color: textColor
                                                                      .withOpacity(
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
                                                          context
                                                              .read<
                                                                PrivateFeedBloc
                                                              >()
                                                              .add(
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
                                                iconColor: primaryColor,
                                                iconBgColor: primaryColor,
                                                title: 'Assignments',
                                                url: state
                                                    .privateFeed
                                                    .homeworkUrl,
                                                label: 'Assignments',
                                                buttonColor: primaryColor,
                                              ),

                                              SizedBox(height: 14.v),

                                              // Class Schedule Card
                                              _buildFeedCard(
                                                context: context,
                                                icon: Icons
                                                    .calendar_today_outlined,
                                                iconColor: Colors.orange,
                                                iconBgColor: Colors.orange,
                                                title: 'Class Schedule',
                                                url: state
                                                    .privateFeed
                                                    .classSchedulesUrl,
                                                label: 'Class Schedule',
                                                buttonColor: Colors.orange,
                                              ),

                                              SizedBox(height: 14.v),

                                              // Events Card
                                              _buildFeedCard(
                                                context: context,
                                                icon: Icons.event_outlined,
                                                iconColor: greenColor,
                                                iconBgColor: greenColor,
                                                title: 'Events',
                                                url:
                                                    state.privateFeed.eventsUrl,
                                                label: 'Events',
                                                buttonColor: greenColor,
                                              ),

                                              SizedBox(height: 24.v),

                                              // Security Warning
                                              Container(
                                                padding: EdgeInsets.all(16.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.amber
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        8.h,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .privacy_tip_outlined,
                                                        color:
                                                            Colors.amber[700],
                                                        size: 20,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12.h),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Keep private feed URLs secret. If a feed is compromised, disabling and re-enabling feeds will regenerate URLs.',
                                                            style: AppTextStyle
                                                                .eTextStyle
                                                                .copyWith(
                                                                  color: textColor
                                                                      .withOpacity(
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
                                        color: redColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: redColor,
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
                                            color: greyColor.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                            style: AppTextStyle.bTextStyle
                                                .copyWith(color: textColor),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: redColor.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  Icons.block_rounded,
                                                  size: 40,
                                                  color: redColor,
                                                ),
                                              ),
                                              SizedBox(height: 20.v),
                                              Text(
                                                'Private Feeds Disabled',
                                                style: AppTextStyle.bTextStyle
                                                    .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                              ),
                                              SizedBox(height: 12.v),
                                              Text(
                                                state.message,
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.6),
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
                                                    context
                                                        .read<PrivateFeedBloc>()
                                                        .add(
                                                          EnablePrivateFeedsEvent(),
                                                        );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryColor,
                                                    foregroundColor: whiteColor,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Enable Again',
                                                    style: AppTextStyle
                                                        .cTextStyle
                                                        .copyWith(
                                                          color: whiteColor,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                      ],
                    ),
                  ),
                ),
              ),
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
            color: blackColor.withOpacity(0.04),
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
          Divider(height: 0, color: greyColor.withOpacity(0.08)),
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
                    border: Border.all(color: greyColor.withOpacity(0.1)),
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
