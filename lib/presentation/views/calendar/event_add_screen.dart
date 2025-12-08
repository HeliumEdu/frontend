// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/models/auth/user_profile_model.dart';
import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/event_response_model.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/event/event_bloc.dart';
import 'package:heliumapp/presentation/widgets/helium_course_textfield.dart';
import 'package:heliumapp/presentation/widgets/helium_text_button.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/app_helpers.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class EventAddScreen extends StatefulWidget {
  const EventAddScreen({super.key});

  @override
  State<EventAddScreen> createState() => _EventAddScreenState();
}

class _EventAddScreenState extends State<EventAddScreen> {
  final DioClient _dioClient = DioClient();
  late UserSettings _userSettings;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool isAllDay = false;
  bool isShowEndDateTime = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double _priorityValue = 50.0;

  bool isEditMode = false;
  int? eventId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final awaitedSettings = await _dioClient.getSettings();
    setState(() {
      _userSettings = awaitedSettings;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isEditMode'] == true && args['eventId'] != null) {
      isEditMode = true;
      eventId = args['eventId'];
      _fetchEventData();
    }
  }

  EventResponseModel? _fetchedEvent;

  Future<void> _fetchEventData() async {
    if (eventId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      log.info('📅 Fetching event data for ID: $eventId');
      final eventDataSource = EventRemoteDataSourceImpl(dioClient: DioClient());
      final eventRepo = EventRepositoryImpl(remoteDataSource: eventDataSource);

      final event = await eventRepo.getEventById(eventId: eventId!);

      // Store the fetched event (includes reminders and attachments)
      _fetchedEvent = event;

      // Pre-populate form fields
      _populateFormFields(event);

      log.info('✅ Event data loaded successfully');
      log.info('📋 Event has ${event.reminders.length} reminder(s)');
      log.info('📎 Event has ${event.attachments.length} attachment(s)');
    } catch (e) {
      log.info('❌ Error fetching event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: ${e.toString()}'),
            backgroundColor: redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _populateFormFields(EventResponseModel event) {
    setState(() {
      // Set basic fields
      _titleController.text = event.title;
      _urlController.text = event.url ?? '';
      _detailsController.text = event.comments ?? '';

      // Set checkboxes
      isAllDay = event.allDay;
      isShowEndDateTime = event.showEndTime;

      // Set priority
      _priorityValue = event.priority.toDouble();

      // Parse and set start date/time
      try {
        final startDateTime = parseDateTime(
          event.start,
          _userSettings.timeZone,
        );
        _startDate = startDateTime;
        if (!event.allDay) {
          _startTime = TimeOfDay.fromDateTime(startDateTime);
        }
      } catch (e) {
        log.info('Error parsing start date: $e');
      }

      // Parse and set end date/time
      if (event.end != null && event.end!.isNotEmpty) {
        try {
          final endDateTime = parseDateTime(event.end!, _userSettings.timeZone);
          _endDate = endDateTime;
          if (!event.allDay) {
            _endTime = TimeOfDay.fromDateTime(endDateTime);
          }
        } catch (e) {
          log.info('Error parsing end date: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: whiteColor,
              onSurface: blackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _getPriorityValue() {
    return _priorityValue.round();
  }

  void _handleUpdateEvent(BuildContext context) {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter event title'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (!isAllDay && _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start time'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    // Build start date/time
    final startDateTime = formatDateTimeToApi(
      _startDate!,
      isAllDay ? null : _startTime,
      _userSettings.timeZone,
    );

    // Build end date/time: API requires non-null; default to start when not provided
    String? endDateTime;
    if (isShowEndDateTime && _endDate != null) {
      endDateTime = formatDateTimeToApi(
        _endDate!,
        isAllDay ? null : _endTime,
        _userSettings.timeZone,
      );
    } else {
      endDateTime = startDateTime;
    }

    // Create request model
    final request = EventRequestModel(
      title: _titleController.text.trim(),
      allDay: isAllDay,
      showEndTime: isShowEndDateTime,
      start: startDateTime,
      end: endDateTime,
      priority: _getPriorityValue(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      comments: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
    );

    // Update the event first, then go to reminder screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    (() async {
      try {
        final ds = EventRemoteDataSourceImpl(dioClient: DioClient());
        final repo = EventRepositoryImpl(remoteDataSource: ds);
        final updated = await repo.updateEvent(
          eventId: eventId!,
          request: request,
        );
        if (context.mounted) Navigator.of(context).pop();
        await Navigator.pushNamed(
          context,
          AppRoutes.calendarAddEventReminderScreen,
          arguments: {
            'eventId': updated.id,
            'isEditMode': true,
            'existingReminders': _fetchedEvent?.reminders ?? [],
            'existingAttachments': _fetchedEvent?.attachments ?? [],
          },
        );
      } catch (e) {
        if (context.mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update event: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    })();
  }

  void _goToEventReminderScreen(BuildContext context) {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter event title'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    if (!isAllDay && _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a start time'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    // Build start date/time
    final startDateTime = formatDateTimeToApi(
      _startDate!,
      isAllDay ? null : _startTime,
      _userSettings.timeZone,
    );

    // Build end date/time: API requires non-null; default to start when not provided
    String? endDateTime;
    if (isShowEndDateTime && _endDate != null) {
      endDateTime = formatDateTimeToApi(
        _endDate!,
        isAllDay ? null : _endTime,
        _userSettings.timeZone,
      );
    } else {
      endDateTime = startDateTime;
    }

    // Create request model
    final request = EventRequestModel(
      title: _titleController.text.trim(),
      allDay: isAllDay,
      showEndTime: isShowEndDateTime,
      start: startDateTime,
      end: endDateTime,
      priority: _getPriorityValue(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      comments: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
    );

    // Create the event first, then navigate to reminder screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    (() async {
      try {
        final ds = EventRemoteDataSourceImpl(dioClient: DioClient());
        final repo = EventRepositoryImpl(remoteDataSource: ds);
        final created = await repo.createEvent(request: request);
        if (context.mounted) Navigator.of(context).pop();
        await Navigator.pushNamed(
          context,
          AppRoutes.calendarAddEventReminderScreen,
          arguments: {'eventId': created.id, 'isEditMode': false},
        );
      } catch (e) {
        if (context.mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
            backgroundColor: redColor,
          ),
        );
      }
    })();
  }

  Color _getColorForPriority(double value) {
    // Clamp value to 1–100
    value = value.clamp(1, 100);

    // Determine bucket index (0–9)
    int index = ((value - 1) / 10).floor();

    const colors = [
      Color(0xff6FCC43), // (green)
      Color(0xff86D238),
      Color(0xffA1D72E),
      Color(0xffBEDC26),
      Color(0xffD9DF1E),
      Color(0xffF2DD19),
      Color(0xffFBC313),
      Color(0xffF79E0E),
      Color(0xffEF6A0B),
      Color(0xffD92727), // (red)
    ];

    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = primaryColor;
    return BlocProvider(
      create: (context) => EventBloc(
        eventRepository: EventRepositoryImpl(
          remoteDataSource: EventRemoteDataSourceImpl(dioClient: DioClient()),
        ),
      ),
      child: Scaffold(
        backgroundColor: softGrey,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.v, horizontal: 12.h),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: blackColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        color: blackColor,
                        size: 24,
                      ),
                    ),
                    Text(
                      isEditMode ? 'Edit Event' : 'Add Events',
                      style: AppStyle.aTextStyle.copyWith(
                        color: blackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Assignment/Event pill toggle (hidden in edit mode)
                    if (!isEditMode)
                      _AssignmentEventToggle(
                        isEventSelected: true,
                        accentColor: accentColor,
                        onChanged: (toEvent) {
                          if (!toEvent) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.calendarAddAssignmentScreen,
                            );
                          }
                        },
                      )
                    else
                      SizedBox(width: 24),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: primaryColor,
                              valueColor: AlwaysStoppedAnimation(whiteColor),
                            ),
                            SizedBox(height: 16.v),
                            Text(
                              'Loading event...',
                              style: AppStyle.cTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stepper
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 12.v,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 20.v,
                                  ),
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(
                                      16.adaptSize,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blackColor.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: EasyStepper(
                                    activeStep: 0,
                                    lineStyle: LineStyle(
                                      lineLength: 60.h,
                                      lineThickness: 3,
                                      lineSpace: 4,
                                      lineType: LineType.normal,
                                      defaultLineColor: greyColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      finishedLineColor: accentColor,
                                      activeLineColor: accentColor,
                                    ),
                                    activeStepBorderColor: accentColor,
                                    activeStepIconColor: whiteColor,
                                    activeStepBackgroundColor: accentColor,
                                    activeStepTextColor: accentColor,
                                    finishedStepBorderColor: accentColor,
                                    finishedStepBackgroundColor: accentColor
                                        .withValues(alpha: 0.1),
                                    finishedStepIconColor: accentColor,
                                    finishedStepTextColor: blackColor,
                                    unreachedStepBorderColor: greyColor
                                        .withValues(alpha: 0.3),
                                    unreachedStepBackgroundColor: softGrey,
                                    unreachedStepIconColor: greyColor,
                                    unreachedStepTextColor: textColor
                                        .withValues(alpha: 0.5),
                                    borderThickness: 2,
                                    internalPadding: 12,
                                    showLoadingAnimation: false,
                                    stepRadius: 28.adaptSize,
                                    showStepBorder: true,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.h,
                                      vertical: 8.v,
                                    ),
                                    stepShape: StepShape.circle,
                                    stepBorderRadius: 15,
                                    steppingEnabled: true,
                                    disableScroll: true,
                                    onStepReached: (index) {
                                      if (index == 1) {
                                        isEditMode
                                            ? _handleUpdateEvent(context)
                                            : _goToEventReminderScreen(context);
                                      }
                                    },
                                    steps: [
                                      EasyStep(
                                        customStep: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            border: Border.all(
                                              color: accentColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.edit_outlined,
                                              color: whiteColor,
                                              size: 20.adaptSize,
                                            ),
                                          ),
                                        ),
                                        customTitle: Padding(
                                          padding: EdgeInsets.only(top: 8.v),
                                          child: Text(
                                            'Event',
                                            style: AppStyle.iTextStyle
                                                .copyWith(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.fSize,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        placeTitleAtStart: false,
                                      ),
                                      EasyStep(
                                        customStep: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            border: Border.all(
                                              color: accentColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons
                                                  .notifications_active_outlined,
                                              color: accentColor,
                                              size: 20.adaptSize,
                                            ),
                                          ),
                                        ),
                                        customTitle: Padding(
                                          padding: EdgeInsets.only(top: 8.v),
                                          child: Text(
                                            'Reminder',
                                            style: AppStyle.iTextStyle
                                                .copyWith(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.fSize,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        placeTitleAtStart: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Title
                              Text(
                                'Title',
                                style: AppStyle.eTextStyle.copyWith(
                                  color: blackColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.v),
                              HeliumCourseTextField(
                                text: '',
                                controller: _titleController,
                              ),
                              SizedBox(height: 18.v),
                              // URL Field

                              // Schedule Section
                              Text(
                                'Schedule',
                                style: AppStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12.v),
                              // All Day Checkbox
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: greyColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isAllDay,
                                      onChanged: (val) {
                                        setState(() => isAllDay = val ?? false);
                                      },
                                      activeColor: primaryColor,
                                    ),
                                    Text(
                                      'All Day',
                                      style: AppStyle.eTextStyle.copyWith(
                                        color: blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.v),
                              // Show End Date Checkbox
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: greyColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isShowEndDateTime,
                                      onChanged: (val) {
                                        setState(
                                          () =>
                                              isShowEndDateTime = val ?? false,
                                        );
                                      },
                                      activeColor: primaryColor,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Show End',
                                        style: AppStyle.eTextStyle.copyWith(
                                          color: blackColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.v),
                              // Dates: show in one row when Show End is enabled, otherwise only Start Date
                              if (isShowEndDateTime) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Date',
                                            style: AppStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          SizedBox(height: 8.v),
                                          GestureDetector(
                                            onTap: () =>
                                                _selectDate(context, true),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.h,
                                                vertical: 12.v,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: blackColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                ),
                                                color: whiteColor,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _startDate != null
                                                        ? formatDateForDisplay(
                                                            _startDate!,
                                                          )
                                                        : '',
                                                    style: AppStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _startDate != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                        ),
                                                  ),
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: accentColor,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.h),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'End Date',
                                            style: AppStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          SizedBox(height: 8.v),
                                          GestureDetector(
                                            onTap: () =>
                                                _selectDate(context, false),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.h,
                                                vertical: 12.v,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: blackColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                ),
                                                color: whiteColor,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _endDate != null
                                                        ? formatDateForDisplay(
                                                            _endDate!,
                                                          )
                                                        : 'Select End Date',
                                                    style: AppStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _endDate != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                        ),
                                                  ),
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: accentColor,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Start Date',
                                  style: AppStyle.eTextStyle.copyWith(
                                    color: blackColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8.v),
                                GestureDetector(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.h,
                                      vertical: 12.v,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: blackColor.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                      color: whiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate != null
                                              ? formatDateForDisplay(
                                                  _startDate!,
                                                )
                                              : '',
                                          style: AppStyle.eTextStyle
                                              .copyWith(
                                                color: _startDate != null
                                                    ? blackColor
                                                    : blackColor.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: accentColor,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              // Start and End Time (only show when All Day is false)
                              if (!isAllDay) ...[
                                SizedBox(height: 16.v),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '',
                                            style: AppStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          SizedBox(height: 8.v),
                                          GestureDetector(
                                            onTap: () =>
                                                _selectTime(context, true),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.h,
                                                vertical: 12.v,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: blackColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                ),
                                                color: whiteColor,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _startTime != null
                                                        ? formatTimeForDisplay(
                                                            _startTime!,
                                                          )
                                                        : '',
                                                    style: AppStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _startTime != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                        ),
                                                  ),
                                                  Icon(
                                                    Icons.access_time,
                                                    color: accentColor,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isShowEndDateTime) ...[
                                      SizedBox(width: 12.h),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'End Time',
                                              style: AppStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor
                                                        .withValues(alpha: 0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            SizedBox(height: 8.v),
                                            GestureDetector(
                                              onTap: () =>
                                                  _selectTime(context, false),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.h,
                                                  vertical: 12.v,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: blackColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                                  color: whiteColor,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _endTime != null
                                                          ? formatTimeForDisplay(
                                                              _endTime!,
                                                            )
                                                          : 'End Time',
                                                      style: AppStyle
                                                          .eTextStyle
                                                          .copyWith(
                                                            color:
                                                                _endTime != null
                                                                ? blackColor
                                                                : blackColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                          ),
                                                    ),
                                                    Icon(
                                                      Icons.access_time,
                                                      color: accentColor,
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              // End Date section moved above when Show End is enabled
                              SizedBox(height: 12.v),
                              // Priority Slider
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Priority',
                                    style: AppStyle.eTextStyle.copyWith(
                                      color: blackColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.h,
                                      vertical: 6.v,
                                    ),
                                    child: Text(
                                      '${(_priorityValue / 10).round()}',
                                      style: AppStyle.eTextStyle.copyWith(
                                        color: _getColorForPriority(
                                          _priorityValue,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.v),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _getColorForPriority(
                                    _priorityValue,
                                  ),
                                  inactiveTrackColor: greyColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  thumbColor: _getColorForPriority(
                                    _priorityValue,
                                  ),
                                  overlayColor: (_getColorForPriority(
                                    _priorityValue,
                                  )).withValues(alpha: 0.2),
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 12.0,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: 20.0,
                                  ),
                                  trackHeight: 6.0,
                                ),
                                child: Slider(
                                  value: _priorityValue,
                                  min: 0,
                                  max: 100,
                                  divisions: 10,
                                  label: '${_priorityValue.round()}',
                                  onChanged: (value) {
                                    setState(() {
                                      _priorityValue = value;
                                    });
                                  },
                                ),
                              ),

                              SizedBox(height: 24.v),
                              // Details Section
                              Text(
                                'Details',
                                style: AppStyle.cTextStyle.copyWith(
                                  color: blackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12.v),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: blackColor.withValues(alpha: 0.15),
                                  ),
                                  color: whiteColor,
                                ),
                                child: TextFormField(
                                  controller: _detailsController,
                                  maxLines: 6,
                                  style: AppStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '',
                                    hintStyle: AppStyle.eTextStyle.copyWith(
                                      color: blackColor.withValues(alpha: 0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12.v,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.v),
                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: HeliumTextButton(
                                  buttonText: 'Save',
                                  onPressed: () => isEditMode
                                      ? _handleUpdateEvent(context)
                                      : _goToEventReminderScreen(context),
                                ),
                              ),
                              SizedBox(height: 20.v),
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
}

class _AssignmentEventToggle extends StatelessWidget {
  final bool isEventSelected;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _AssignmentEventToggle({
    required this.isEventSelected,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = softGrey;
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            context: context,
            label: 'Assignment',
            selected: !isEventSelected,
            onTap: () => onChanged(false),
            accentColor: accentColor,
          ),
          _segment(
            context: context,
            label: 'Event',
            selected: isEventSelected,
            onTap: () => onChanged(true),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
        decoration: BoxDecoration(
          color: selected ? accentColor : transparentColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppStyle.eTextStyle.copyWith(
            color: selected ? whiteColor : blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
