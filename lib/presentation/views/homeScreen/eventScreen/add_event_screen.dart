import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/config/app_route.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/event_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/event_request_model.dart';
import 'package:helium_student_flutter/data/models/planner/event_response_model.dart';
import 'package:helium_student_flutter/data/repositories/event_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/eventBloc/event_bloc.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_class_textfield.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_text_button.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';
import 'package:intl/intl.dart';
import 'package:easy_stepper/easy_stepper.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
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
  bool isLoadingEvent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isEditMode'] == true && args['eventId'] != null) {
      if (!isEditMode) {
        isEditMode = true;
        eventId = args['eventId'];
        _fetchEventData();
      }
    }
  }

  EventResponseModel? _fetchedEvent;

  Future<void> _fetchEventData() async {
    if (eventId == null) return;

    setState(() {
      isLoadingEvent = true;
    });

    try {
      print('📅 Fetching event data for ID: $eventId');
      final eventDataSource = EventRemoteDataSourceImpl(dioClient: DioClient());
      final eventRepo = EventRepositoryImpl(remoteDataSource: eventDataSource);

      final event = await eventRepo.getEventById(eventId: eventId!);

      // Store the fetched event (includes reminders and attachments)
      _fetchedEvent = event;

      // Pre-populate form fields
      _populateFormFields(event);

      print('✅ Event data loaded successfully');
      print('📋 Event has ${event.reminders.length} reminder(s)');
      print('📎 Event has ${event.attachments.length} attachment(s)');
    } catch (e) {
      print('❌ Error fetching event: $e');
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
          isLoadingEvent = false;
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
        final startDateTime = DateTime.parse(event.start);
        _startDate = startDateTime;
        if (!event.allDay) {
          _startTime = TimeOfDay.fromDateTime(startDateTime);
        }
      } catch (e) {
        print('Error parsing start date: $e');
      }

      // Parse and set end date/time
      if (event.end != null && event.end!.isNotEmpty) {
        try {
          final endDateTime = DateTime.parse(event.end!);
          _endDate = endDateTime;
          if (!event.allDay) {
            _endTime = TimeOfDay.fromDateTime(endDateTime);
          }
        } catch (e) {
          print('Error parsing end date: $e');
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

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    return time.format(context);
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
          onPrimary: Colors.white,
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
      initialEntryMode: TimePickerEntryMode.input
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

  String _formatDateTimeToISO(DateTime date, TimeOfDay? time) {
    if (time != null) {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      return dateTime.toIso8601String();
    }
    return date.toIso8601String();
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
    final startDateTime = _formatDateTimeToISO(
      _startDate!,
      isAllDay ? null : _startTime,
    );

    // Build end date/time: API requires non-null; default to start when not provided
    String? endDateTime;
    if (isShowEndDateTime && _endDate != null) {
      endDateTime = _formatDateTimeToISO(_endDate!, isAllDay ? null : _endTime);
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
        Navigator.pushNamed(
          context,
          AppRoutes.eventRemainderScreen,
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
    final startDateTime = _formatDateTimeToISO(
      _startDate!,
      isAllDay ? null : _startTime,
    );

    // Build end date/time: API requires non-null; default to start when not provided
    String? endDateTime;
    if (isShowEndDateTime && _endDate != null) {
      endDateTime = _formatDateTimeToISO(_endDate!, isAllDay ? null : _endTime);
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
        Navigator.pushNamed(
          context,
          AppRoutes.eventRemainderScreen,
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
                      color: blackColor.withOpacity(0.08),
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
                      style: AppTextStyle.aTextStyle.copyWith(
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
                              AppRoutes.addAssignmentScreen,
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
                child: isLoadingEvent
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
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: blackColor.withOpacity(0.7),
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
                                    borderRadius:
                                        BorderRadius.circular(16.adaptSize),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blackColor.withOpacity(0.06),
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
                                      defaultLineColor:
                                          greyColor.withOpacity(0.3),
                                      finishedLineColor: accentColor,
                                      activeLineColor: accentColor,
                                    ),
                                    activeStepBorderColor: accentColor,
                                    activeStepIconColor: whiteColor,
                                    activeStepBackgroundColor: accentColor,
                                    activeStepTextColor: accentColor,
                                    finishedStepBorderColor: accentColor,
                                    finishedStepBackgroundColor:
                                        accentColor.withOpacity(0.1),
                                    finishedStepIconColor: accentColor,
                                    finishedStepTextColor: blackColor,
                                    unreachedStepBorderColor:
                                        greyColor.withOpacity(0.3),
                                    unreachedStepBackgroundColor: softGrey,
                                    unreachedStepIconColor: greyColor,
                                    unreachedStepTextColor:
                                        textColor.withOpacity(0.5),
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
                                            : _goToEventReminderScreen(
                                                context,
                                              );
                                      }
                                    },
                                    steps: [
                                      EasyStep(
                                        customStep: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentColor.withOpacity(0.1),
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
                                            style:
                                                AppTextStyle.iTextStyle.copyWith(
                                              color: blackColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.fSize,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        topTitle: false,
                                      ),
                                      EasyStep(
                                        customStep: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentColor.withOpacity(0.1),
                                            border: Border.all(
                                              color: accentColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.notifications_active_outlined,
                                              color: accentColor,
                                              size: 20.adaptSize,
                                            ),
                                          ),
                                        ),
                                        customTitle: Padding(
                                          padding: EdgeInsets.only(top: 8.v),
                                          child: Text(
                                            'Reminder',
                                            style:
                                                AppTextStyle.iTextStyle.copyWith(
                                              color: blackColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.fSize,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        topTitle: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Title
                              Text(
                                'Title',
                                style: AppTextStyle.eTextStyle.copyWith(
                                  color: blackColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.v),
                              CustomClassTextField(
                                text: 'Enter Event Title',
                                controller: _titleController,
                              ),
                              SizedBox(height: 18.v),
                              // URL Field

                              // Schedule Section
                              Text(
                                'Schedule',
                                style: AppTextStyle.cTextStyle.copyWith(
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
                                      color: greyColor.withOpacity(0.3),
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
                                      style: AppTextStyle.eTextStyle.copyWith(
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
                                      color: greyColor.withOpacity(0.3),
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
                                        style: AppTextStyle.eTextStyle.copyWith(
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
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withOpacity(
                                                    0.8,
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
                                                  color: blackColor.withOpacity(
                                                    0.15,
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
                                                        ? _formatDateForDisplay(
                                                            _startDate!,
                                                          )
                                                        : 'Select Start Date',
                                                    style: AppTextStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _startDate != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withOpacity(
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
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withOpacity(
                                                    0.8,
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
                                                  color: blackColor.withOpacity(
                                                    0.15,
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
                                                        ? _formatDateForDisplay(
                                                            _endDate!,
                                                          )
                                                        : 'Select End Date',
                                                    style: AppTextStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _endDate != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withOpacity(
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
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.8),
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
                                        color: blackColor.withOpacity(0.15),
                                      ),
                                      color: whiteColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate != null
                                              ? _formatDateForDisplay(
                                                  _startDate!,
                                                )
                                              : 'Select Start Date',
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: _startDate != null
                                                    ? blackColor
                                                    : blackColor.withOpacity(
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
                                            'Start Time',
                                            style: AppTextStyle.eTextStyle
                                                .copyWith(
                                                  color: blackColor.withOpacity(
                                                    0.8,
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
                                                  color: blackColor.withOpacity(
                                                    0.15,
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
                                                        ? _formatTime(
                                                            _startTime!,
                                                          )
                                                        : 'Start Time',
                                                    style: AppTextStyle
                                                        .eTextStyle
                                                        .copyWith(
                                                          color:
                                                              _startTime != null
                                                              ? blackColor
                                                              : blackColor
                                                                    .withOpacity(
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
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor
                                                        .withOpacity(0.8),
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
                                                        .withOpacity(0.15),
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
                                                          ? _formatTime(
                                                              _endTime!,
                                                            )
                                                          : 'End Time',
                                                      style: AppTextStyle
                                                          .eTextStyle
                                                          .copyWith(
                                                            color:
                                                                _endTime != null
                                                                ? blackColor
                                                                : blackColor
                                                                      .withOpacity(
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
                                    style: AppTextStyle.eTextStyle.copyWith(
                                      color: blackColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.h,
                                      vertical: 6.v,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _priorityValue <= 33
                                          ? const Color(
                                              0xff28A745,
                                            ).withOpacity(0.1)
                                          : _priorityValue <= 66
                                          ? const Color(
                                              0xffFFC107,
                                            ).withOpacity(0.1)
                                          : const Color(
                                              0xffDC3545,
                                            ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_priorityValue.round()}',
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: _priorityValue <= 33
                                            ? const Color(0xff28A745)
                                            : _priorityValue <= 66
                                            ? const Color(0xffFFC107)
                                            : const Color(0xffDC3545),
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
                                  activeTrackColor: _priorityValue <= 33
                                      ? const Color(0xff28A745)
                                      : _priorityValue <= 66
                                      ? const Color(0xffFFC107)
                                      : const Color(0xffDC3545),
                                  inactiveTrackColor: greyColor.withOpacity(
                                    0.3,
                                  ),
                                  thumbColor: _priorityValue <= 33
                                      ? const Color(0xff28A745)
                                      : _priorityValue <= 66
                                      ? const Color(0xffFFC107)
                                      : const Color(0xffDC3545),
                                  overlayColor:
                                      (_priorityValue <= 33
                                              ? const Color(0xff28A745)
                                              : _priorityValue <= 66
                                              ? const Color(0xffFFC107)
                                              : const Color(0xffDC3545))
                                          .withOpacity(0.2),
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
                                  divisions: 100,
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
                                style: AppTextStyle.cTextStyle.copyWith(
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
                                    color: blackColor.withOpacity(0.15),
                                  ),
                                  color: whiteColor,
                                ),
                                child: TextFormField(
                                  controller: _detailsController,
                                  maxLines: 6,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add Event Details',
                                    hintStyle: AppTextStyle.eTextStyle.copyWith(
                                      color: blackColor.withOpacity(0.5),
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
                                child: CustomTextButton(
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
        border: Border.all(color: accentColor.withOpacity(0.2)),
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
          color: selected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyle.eTextStyle.copyWith(
            color: selected ? whiteColor : blackColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
