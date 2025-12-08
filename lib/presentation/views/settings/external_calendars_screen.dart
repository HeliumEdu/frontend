// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_mobile/core/dio_client.dart';
import 'package:helium_mobile/data/sources/external_calendar_remote_data_source.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_model.dart';
import 'package:helium_mobile/data/models/planner/external_calendar_request_model.dart';
import 'package:helium_mobile/data/repositories/external_calendar_repository_impl.dart';
import 'package:helium_mobile/presentation/bloc/settings/external_calendar_bloc.dart';
import 'package:helium_mobile/presentation/bloc/settings/external_calendar_event.dart';
import 'package:helium_mobile/presentation/bloc/settings/external_calendar_state.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_style.dart';

class ExternalCalendarsSettingsScreen extends StatelessWidget {
  const ExternalCalendarsSettingsScreen({super.key});

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
      ],
      child: const ExternalCalendarsSettingsView(),
    );
  }
}

class ExternalCalendarsSettingsView extends StatefulWidget {
  const ExternalCalendarsSettingsView({super.key});

  @override
  State<ExternalCalendarsSettingsView> createState() =>
      _ExternalCalendarsSettingsViewState();
}

Color dialogSelectedColor = const Color(0xff26A69A);

class _ExternalCalendarsSettingsViewState
    extends State<ExternalCalendarsSettingsView> {
  late TextEditingController _calendarTitleController;
  late TextEditingController _calendarUrlController;
  static const String _defaultExternalCalendarTitle = 'Holidays';
  static const String _defaultExternalCalendarUrl =
      'https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics';
  static const Color _defaultExternalCalendarColor = Color(0xffffad46);

  Color _externalDialogSelectedColor = _defaultExternalCalendarColor;
  bool _externalShownOnCalendar = false;
  bool _isExternalCalendarDialogOpen = false;
  List<ExternalCalendarModel> _cachedExternalCalendars = [];

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

  void _showExternalCalendarDialog({ExternalCalendarModel? existingCalendar}) {
    final bool isEdit = existingCalendar != null;

    if (isEdit) {
      _calendarTitleController.text = existingCalendar.title;
      _calendarUrlController.text = existingCalendar.url;
      _externalDialogSelectedColor = hexToColor(
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
                style: AppStyle.bTextStyle.copyWith(
                  color: blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: preferredColors
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
                          color: blackColor.withValues(alpha: 0.1),
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
                              style: AppStyle.aTextStyle.copyWith(
                                color: blackColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 28.v),
                          Text(
                            'Name',
                            style: AppStyle.cTextStyle.copyWith(
                              color: blackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.v),
                          TextField(
                            controller: _calendarTitleController,
                            decoration: InputDecoration(
                              hintText: 'Enter calendar name',
                              hintStyle: AppStyle.iTextStyle.copyWith(
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: softGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withValues(alpha: 0.3),
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
                            style: AppStyle.cTextStyle.copyWith(
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
                              hintStyle: AppStyle.iTextStyle.copyWith(
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: softGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.adaptSize,
                                ),
                                borderSide: BorderSide(
                                  color: greyColor.withValues(alpha: 0.3),
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
                                style: AppStyle.cTextStyle.copyWith(
                                  color: blackColor.withValues(alpha: 0.8),
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
                                style: AppStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Switch.adaptive(
                                value: _externalShownOnCalendar,
                                activeTrackColor: primaryColor,
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
                                color: redColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  10.adaptSize,
                                ),
                                border: Border.all(
                                  color: redColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                actionError!,
                                style: AppStyle.cTextStyle.copyWith(
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
                                    style: AppStyle.cTextStyle.copyWith(
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
                                                color: colorToHex(
                                                  _externalDialogSelectedColor,
                                                ),
                                                shownOnCalendar:
                                                    _externalShownOnCalendar,
                                              );

                                          if (isEdit) {
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
                                        ? primaryColor.withValues(alpha: 0.6)
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
                                          style: AppStyle.cTextStyle
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
    final Color calendarColor = hexToColor(calendar.color);
    return Container(
      margin: EdgeInsets.only(bottom: 12.v),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10.adaptSize),
        border: Border.all(color: softGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: 0.04),
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
                  style: AppStyle.cTextStyle.copyWith(
                    color: blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.v),
                Text(
                  calendar.url,
                  style: AppStyle.iTextStyle.copyWith(
                    color: textColor.withValues(alpha: 0.6),
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
            activeTrackColor: primaryColor,
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
                            style: AppStyle.bTextStyle.copyWith(
                              color: textColor,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${calendar.title}"? This action cannot be undone.',
                            style: AppStyle.cTextStyle.copyWith(
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(confirmContext);
                              },
                              child: Text(
                                'Cancel',
                                style: AppStyle.cTextStyle.copyWith(
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
                                style: AppStyle.cTextStyle.copyWith(
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
                    style: AppStyle.cTextStyle.copyWith(color: whiteColor),
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
                      style: AppStyle.cTextStyle.copyWith(
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
                      'External Calendars',
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
}
