import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/preferenceBloc/preference_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/preferenceBloc/preference_event.dart';
import 'package:helium_student_flutter/presentation/bloc/preferenceBloc/preference_states.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_text_button.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_list.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';
import 'package:helium_student_flutter/utils/custom_color_picker.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/datasources/external_calendar_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/external_calendar_model.dart';
import 'package:helium_student_flutter/data/models/planner/external_calendar_request_model.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:helium_student_flutter/data/repositories/external_calendar_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/externalCalendarBloc/external_calendar_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/externalCalendarBloc/external_calendar_event.dart';
import 'package:helium_student_flutter/presentation/bloc/externalCalendarBloc/external_calendar_state.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

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
          create: (context) => PreferenceBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ExternalCalendarBloc(
            externalCalendarRepository: externalCalendarRepository,
          )..add(FetchAllExternalCalendarsEvent()),
        ),
      ],
      child: const PreferenceView(),
    );
  }
}

class PreferenceView extends StatefulWidget {
  const PreferenceView({super.key});

  @override
  State<PreferenceView> createState() => _PreferenceViewState();
}

Color dialogSelectedColor = const Color(0xFF26A69A);
String? selectedDefaultPreference;
String? selectedTimezonePreference;
String? selectedReminderPreference;
String? selectedReminderTypePreference;

class _PreferenceViewState extends State<PreferenceView> {
  late TextEditingController _offsetController;
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
    _offsetController = TextEditingController(text: '0');
    _calendarTitleController = TextEditingController();
    _calendarUrlController = TextEditingController();
    // Fetch current preferences on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PreferenceBloc>().add(FetchPreferencesEvent());
      }
    });
  }

  @override
  void dispose() {
    _offsetController.dispose();
    _calendarTitleController.dispose();
    _calendarUrlController.dispose();
    super.dispose();
  }

  void _showDialogColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        contentPadding: EdgeInsets.zero,
        content: CustomColorPickerWidget(
          initialColor: dialogSelectedColor,
          onColorSelected: (color) {
            setState(() {
              dialogSelectedColor = color;
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
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
      _externalDialogSelectedColor =
          _externalHexToColor(existingCalendar.color);
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
                                    : Colors.transparent,
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
                  backgroundColor: Colors.transparent,
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
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 2),
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
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide: BorderSide(
                                  color: greyColor.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.adaptSize),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 2),
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
                                onTap:
                                    isSubmitting ? null : () => openColorPicker(setDialogState),
                                child: Container(
                                  width: 33,
                                  height: 33,
                                  decoration: BoxDecoration(
                                    color: _externalDialogSelectedColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
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
                                borderRadius:
                                    BorderRadius.circular(10.adaptSize),
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
                                  onPressed:
                                      isSubmitting ? null : closeDialog,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.v),
                                    side: BorderSide(
                                      color: primaryColor,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.adaptSize),
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
                                          final url = _calendarUrlController.text
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

                                          if (isEdit && existingCalendar != null) {
                                            context.read<ExternalCalendarBloc>().add(
                                              UpdateExternalCalendarEvent(
                                                calendarId: existingCalendar.id,
                                                payload: payload,
                                              ),
                                            );
                                          } else {
                                            context.read<ExternalCalendarBloc>().add(
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
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.v),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.adaptSize),
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
                                          style: AppTextStyle.cTextStyle.copyWith(
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
          UpdateExternalCalendarEvent(
            calendarId: calendar.id,
            payload: payload,
          ),
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
        border: Border.all(
          color: softGrey,
          width: 1,
        ),
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
            onTap:
                isActionInProgress ? null : () => _showExternalCalendarDialog(
                      existingCalendar: calendar,
                    ),
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
                                  borderRadius:
                                      BorderRadius.circular(8.adaptSize),
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PreferenceBloc, PreferenceState>(
          listener: (context, state) {
            setState(() {
              if (state.selectedDefaultPreference != null) {
                selectedDefaultPreference = state.selectedDefaultPreference;
              }
              if (state.selectedTimezonePreference != null) {
                selectedTimezonePreference = state.selectedTimezonePreference;
              }
              if (state.selectedReminderPreference != null) {
                selectedReminderPreference = state.selectedReminderPreference;
              }
              if (state.selectedReminderTypePreference != null) {
                selectedReminderTypePreference =
                    state.selectedReminderTypePreference;
              }
              dialogSelectedColor = state.selectedColor;
              if (_offsetController.text != state.offsetValue.toString()) {
                _offsetController.text = state.offsetValue.toString();
              }
            });
          },
        ),
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
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ExternalCalendarActionError) {
              if (!_isExternalCalendarDialogOpen) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: AppTextStyle.cTextStyle.copyWith(color: whiteColor),
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
        backgroundColor: softGrey,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: 16.v,
                    horizontal: 16.h
                ),
                decoration: BoxDecoration(
                  color: whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      'Preferences',
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
                        Text(
                          'Default View',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              "List",
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedDefaultPreference,
                            items: defaultPreferences.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDefaultPreference = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 22.h),
                        Text(
                          'Time Zone',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              "timezone",
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedTimezonePreference,
                            items: timezonesPreference.toSet().map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTimezonePreference = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 22.v),
                        Row(
                          children: [
                            Text(
                              'Color',
                              style: AppTextStyle.cTextStyle.copyWith(
                                color: blackColor.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(width: 12.h),
                            GestureDetector(
                              onTap: _showDialogColorPicker,
                              child: Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  color: dialogSelectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 22.h),
                        Text(
                          'Default Remainder',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              "Remainder",
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedReminderPreference,
                            items: remainderPreferences.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReminderPreference = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 22.h),

                        // BLoC Implementation for Offset Field
                        Text(
                          'Default Remainder OffSet',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        BlocConsumer<PreferenceBloc, PreferenceState>(
                          listener: (context, state) {
                            // Update text controller when state changes
                            if (_offsetController.text !=
                                state.offsetValue.toString()) {
                              _offsetController.text = state.offsetValue
                                  .toString();
                            }
                          },
                          builder: (context, state) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _offsetController,
                                      keyboardType: TextInputType.number,
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: blackColor.withOpacity(0.6),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 8.v,
                                        ),
                                        hintText: '',
                                      ),
                                      onChanged: (value) {
                                        final intValue = int.tryParse(value);
                                        if (intValue != null) {
                                          context.read<PreferenceBloc>().add(
                                            UpdateOffsetEvent(intValue),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          context.read<PreferenceBloc>().add(
                                            IncrementOffsetEvent(),
                                          );
                                        },
                                        child: Icon(
                                          Icons.arrow_drop_up,
                                          size: 20,
                                          color: blackColor.withOpacity(0.6),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          context.read<PreferenceBloc>().add(
                                            DecrementOffsetEvent(),
                                          );
                                        },
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          size: 20,
                                          color: blackColor.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 22.h),
                        Text(
                          'Default Remainder OffSet Type',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: blackColor.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              "Remainder Type",
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedReminderTypePreference,
                            items: remainderTypePreferences.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppTextStyle.eTextStyle.copyWith(
                                    color: blackColor.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReminderTypePreference = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 32.v),
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
                            ElevatedButton.icon(
                              onPressed: () => _showExternalCalendarDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.v,
                                  horizontal: 12.h,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8.adaptSize,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Icons.add,
                                size: 18.adaptSize,
                                color: whiteColor,
                              ),
                              label: Text(
                                'Add External Calendar',
                                style: AppTextStyle.cTextStyle.copyWith(
                                  color: whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.v),
                        BlocBuilder<ExternalCalendarBloc, ExternalCalendarState>(
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
                                  borderRadius:
                                      BorderRadius.circular(10.adaptSize),
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
                                  borderRadius:
                                      BorderRadius.circular(10.adaptSize),
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

                        SizedBox(height: 48.v),

                        BlocConsumer<PreferenceBloc, PreferenceState>(
                          listener: (context, state) {
                            if (state.submitSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    'Preferences updated successfully',
                                  ),
                                ),
                              );
                            } else if (state.submitError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(state.submitError!),
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            final isSubmitting = state.isSubmitting;
                            return CustomTextButton(
                              buttonText: 'Save',
                              isLoading: isSubmitting,
                              onPressed: () {
                                final tz = selectedTimezonePreference ?? 'UTC';
                                final viewIndex =
                                    selectedDefaultPreference == null
                                    ? 0
                                    : defaultPreferences.indexOf(
                                        selectedDefaultPreference!,
                                      );
                                // Normalize to #rrggbb (strip alpha and ensure #)
                                String colorHex =
                                    '#${dialogSelectedColor.value.toRadixString(16).substring(2)}';
                                if (colorHex.length == 9) {
                                  colorHex = '#${colorHex.substring(3)}';
                                }
                                colorHex = colorHex.toLowerCase();
                                final reminderTypeIndex = () {
                                  if (selectedReminderTypePreference == null) {
                                    return 0;
                                  }
                                  final idx = remainderTypePreferences.indexOf(
                                    selectedReminderTypePreference!,
                                  );
                                  return idx >= 0 ? idx : 0;
                                }();
                                final reminderPreferenceIndex = () {
                                  if (selectedReminderPreference == null) {
                                    return 0;
                                  }
                                  final idx = remainderPreferences.indexOf(
                                    selectedReminderPreference!,
                                  );
                                  return idx >= 0 ? idx : 0;
                                }();
                                final offsetVal =
                                    int.tryParse(_offsetController.text) ?? 0;

                                context.read<PreferenceBloc>().add(
                                  SubmitPreferencesEvent(
                                    timeZone: tz,
                                    defaultView: viewIndex,
                                    eventsColor: colorHex,
                                    defaultReminderType:
                                        reminderPreferenceIndex,
                                    defaultReminderOffset: offsetVal,
                                    defaultReminderOffsetType:
                                        reminderTypeIndex,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 22.h),
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
