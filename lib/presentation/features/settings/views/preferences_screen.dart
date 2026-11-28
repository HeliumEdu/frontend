import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/feedback/warning_container.dart';
import 'package:heliumapp/presentation/ui/layout/helium_full_screen_scroll_view.dart';
import 'package:heliumapp/presentation/ui/components/searchable_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/components/color_selector.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/locale_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.views');

class PreferencesScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  static const String timeZoneField = 'preferences_time_zone';
  static const String languageField = 'preferences_language';
  static const String dateFormatField = 'preferences_date_format';
  static const String timeFormatField = 'preferences_time_format';
  static const String numberFormatField = 'preferences_number_format';
  static const String dragAndDropField = 'preferences_drag_and_drop';

  const PreferencesScreen({
    super.key,
    required this.user,
    this.onActionStarted,
    this.onCompleted,
    this.onFailed,
  });

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  final _gradesSectionKey = GlobalKey();
  final TextEditingController _reminderOffsetController =
      TextEditingController();
  final TextEditingController _atRiskThresholdController =
      TextEditingController();
  final TextEditingController _onTrackToleranceController =
      TextEditingController();
  final TextEditingController _priorCreditsController =
      TextEditingController();
  final TextEditingController _priorGpaController = TextEditingController();

  bool _isSubmitting = false;
  bool _isChanged = false;
  bool _changeTrackingActive = false;

  late Color _selectedEventColor;
  late Color _selectedResourceColor;
  late Color _selectedGradeColor;
  late String _selectedDefaultView;
  late String _selectedWeekStartsOn;
  late String _selectedTimeZone;
  late String _selectedLanguage;
  late int _selectedDateFormat;
  late int _selectedTimeFormat;
  late int _selectedNumberFormat;
  late String _selectedReminderOffsetType;
  late String _selectedReminderType;
  late bool _isShowPlannerTooltips;
  late bool _isDragAndDropOnMobile;
  late bool _isSelectedColorByCategory;
  late bool _isRememberFilterSelection;
  late bool _isCollapseBusyDays;
  late bool _isShowWeekNumbers;

  String? _savedTimeZone;
  String? _savedDefaultView;
  bool? _hasCourseSchedules;

  bool get isChanged => _isChanged;

  void _markChanged() {
    if (_isChanged || !_changeTrackingActive) return;
    setState(() => _isChanged = true);
  }

  @override
  void initState() {
    super.initState();

    _populateScreenData(widget.user);
    context.read<CourseBloc>().add(
      FetchHasCourseSchedulesEvent(origin: EventOrigin.subScreen),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLinkedSection());
  }

  /// Scrolls to the section a link names, e.g. the Grades page's "Grade preferences".
  void _scrollToLinkedSection() {
    final section = router.activeLocation.queryParameters[DeepLinkParam.section];
    final sectionContext = _gradesSectionKey.currentContext;
    if (section != 'grades' || sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: MotionService().effectiveDuration(const Duration(milliseconds: 300)),
    );
  }

  @override
  void dispose() {
    _reminderOffsetController.removeListener(_markChanged);
    _atRiskThresholdController.removeListener(_markChanged);
    _onTrackToleranceController.removeListener(_markChanged);
    _priorCreditsController.removeListener(_markChanged);
    _priorGpaController.removeListener(_markChanged);
    _reminderOffsetController.dispose();
    _atRiskThresholdController.dispose();
    _onTrackToleranceController.dispose();
    _priorCreditsController.dispose();
    _priorGpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is HasCourseSchedulesFetched) {
              setState(() => _hasCourseSchedules = state.hasCourseSchedules);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              SnackBarHelper.show(context, state.message!, type: SnackType.error);
              setState(() => _isSubmitting = false);
              widget.onFailed?.call();
            } else if (state is AuthProfileUpdated) {
              if (!_isRememberFilterSelection) {
                PrefService().removeKeys(FilterStatePrefKey.allKeys);
              }
              setState(() {
                _isChanged = false;
                _isSubmitting = false;
              });
              widget.onCompleted?.call();
            }
          },
        ),
      ],
      child: HeliumFullScreenScrollView(
        keyboardDismissBehavior: PlatformBehavior.keyboardDismissBehavior,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppLocalizations.of(context).preferencesGeneralSection),
            if (_offersLanguageChoice) ...[
              _buildLanguageField(),
              const SizedBox(height: 14),
            ],
            SearchableDropdown(
              label: AppLocalizations.of(context).preferencesTimeZoneLabel,
              key: const Key(PreferencesScreen.timeZoneField),
              initialValue: TimeZoneConstants.items.firstWhere(
                (tz) => tz.value == _selectedTimeZone,
                orElse: () => TimeZoneConstants.items.firstWhere(
                  (tz) => tz.value == 'UTC',
                ),
              ),
              items: TimeZoneConstants.items,
              onChanged: (value) {
                setState(() {
                  _selectedTimeZone = value!.value!;
                  _isChanged = true;
                });
              },
            ),

            ?_buildTimeZoneChangeNotice(),
            const SizedBox(height: 14),
            _buildRegionalFormatFields(),

            _buildSectionHeader(AppLocalizations.of(context).preferencesPlannerSection),
            DropDown(
              label: AppLocalizations.of(context).preferencesDefaultViewLabel,
              initialValue: CalendarConstants.defaultViewItems.firstWhere(
                (dv) => dv.value == _selectedDefaultView,
              ),
              items: CalendarConstants.defaultViewItems,
              onChanged: (value) {
                setState(() {
                  _selectedDefaultView = value!.value!;
                  _isChanged = true;
                });
              },
            ),
            HeliumCheckboxListTile(
              title: Text(
                AppLocalizations.of(context).preferencesRememberFiltersLabel,
                style: AppStyles.formLabel(context),
              ),
              subtitle: Text(
                AppLocalizations.of(context).preferencesRememberFiltersDescription,
                style: AppStyles.smallSecondaryText(context),
              ),
              value: _isRememberFilterSelection,
              onChanged: (value) {
                setState(() {
                  _isRememberFilterSelection = value!;
                  _isChanged = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            HeliumCheckboxListTile(
              key: const Key(PreferencesScreen.dragAndDropField),
              title: Text(
                AppLocalizations.of(context).preferencesDragAndDropLabel,
                style: AppStyles.formLabel(context),
              ),
              value: _isDragAndDropOnMobile,
              onChanged: (value) {
                setState(() {
                  _isDragAndDropOnMobile = value!;
                  _isChanged = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (PlatformBehavior.showsHoverTooltips)
              HeliumCheckboxListTile(
                title: Text(
                  AppLocalizations.of(context).preferencesShowTooltipsLabel,
                  style: AppStyles.formLabel(context),
                ),
                value: _isShowPlannerTooltips,
                onChanged: (value) {
                  setState(() {
                    _isShowPlannerTooltips = value!;
                    _isChanged = true;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

            _buildSectionHeader(AppLocalizations.of(context).preferencesCalendarSection),
            DropDown(
              label: AppLocalizations.of(context).preferencesWeekStartsOnLabel,
              initialValue: CalendarConstants.dayNamesItems.firstWhere(
                (fd) => fd.value == _selectedWeekStartsOn,
              ),
              items: CalendarConstants.dayNamesItems,
              onChanged: (value) {
                setState(() {
                  _selectedWeekStartsOn = value!.value!;
                  _isChanged = true;
                });
              },
            ),
            HeliumCheckboxListTile(
              title: Text(
                AppLocalizations.of(context).preferencesCollapseBusyDaysLabel,
                style: AppStyles.formLabel(context),
              ),
              subtitle: Text(
                AppLocalizations.of(context).preferencesCollapseBusyDaysDescription,
                style: AppStyles.smallSecondaryText(context),
              ),
              value: _isCollapseBusyDays,
              onChanged: (value) {
                setState(() {
                  _isCollapseBusyDays = value!;
                  _isChanged = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            HeliumCheckboxListTile(
              title: Text(
                AppLocalizations.of(context).preferencesShowWeekNumbersLabel,
                style: AppStyles.formLabel(context),
              ),
              value: _isShowWeekNumbers,
              onChanged: (value) {
                setState(() {
                  _isShowWeekNumbers = value!;
                  _isChanged = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            _buildSectionHeader(AppLocalizations.of(context).preferencesDisplaySection),
            ColorSelector(
              label: AppLocalizations.of(context).preferencesEventsColorLabel,
              labelWidth: 160,
              selectedColor: _selectedEventColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedEventColor = color;
                  _isChanged = true;
                });
              },
            ),
            const SizedBox(height: 14),
            ColorSelector(
              label: AppLocalizations.of(context).preferencesGradesColorLabel,
              labelWidth: 160,
              selectedColor: _selectedGradeColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedGradeColor = color;
                  _isChanged = true;
                });
              },
            ),
            const SizedBox(height: 14),
            ColorSelector(
              label: AppLocalizations.of(context).preferencesResourcesColorLabel,
              labelWidth: 160,
              selectedColor: _selectedResourceColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedResourceColor = color;
                  _isChanged = true;
                });
              },
            ),
            const SizedBox(height: 4),
            HeliumCheckboxListTile(
              title: Text(
                AppLocalizations.of(context).preferencesColorByCategoryLabel,
                style: AppStyles.formLabel(context),
              ),
              subtitle: Text(
                AppLocalizations.of(context).preferencesColorByCategoryDescription,
                style: AppStyles.smallSecondaryText(context),
              ),
              value: _isSelectedColorByCategory,
              onChanged: (value) {
                setState(() {
                  _isSelectedColorByCategory = value!;
                  _isChanged = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            KeyedSubtree(key: _gradesSectionKey, child: _buildSectionHeader(AppLocalizations.of(context).preferencesGradesSection)),
            SpinnerField(
              label: AppLocalizations.of(context).preferencesAtRiskLabel,
              description: AppLocalizations.of(context).preferencesAtRiskDescription,
              maxSpinnerWidth: 120,
              controller: _atRiskThresholdController,
              minValue: 0,
              maxValue: 100,
            ),
            const SizedBox(height: 14),
            SpinnerField(
              label: AppLocalizations.of(context).preferencesOnTrackLabel,
              description: AppLocalizations.of(context).preferencesOnTrackDescription,
              maxSpinnerWidth: 120,
              controller: _onTrackToleranceController,
              minValue: 0,
              maxValue: 100,
            ),
            const SizedBox(height: 14),
            SpinnerField(
              label: AppLocalizations.of(context).preferencesPriorCreditsLabel,
              description: AppLocalizations.of(context).preferencesPriorCreditsDescription,
              maxSpinnerWidth: 120,
              controller: _priorCreditsController,
              minValue: 0,
              maxValue: 999.99,
              allowDecimal: true,
            ),
            const SizedBox(height: 14),
            SpinnerField(
              label: AppLocalizations.of(context).preferencesPriorGpaLabel,
              description: AppLocalizations.of(context).preferencesPriorGpaDescription,
              maxSpinnerWidth: 120,
              controller: _priorGpaController,
              minValue: 0,
              maxValue: 100,
              step: 0.1,
              allowDecimal: true,
            ),

            _buildSectionHeader(AppLocalizations.of(context).preferencesRemindersSection),
            DropDown(
              label: AppLocalizations.of(context).preferencesDefaultReminderLabel,
              initialValue: ReminderConstants.typeItems.firstWhere(
                (rt) => rt.value == _selectedReminderType,
              ),
              items: ReminderConstants.typeItems,
              onChanged: (value) {
                // Delay state update to avoid layout exception when items list changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    _selectedReminderType = value!.value!;
                    _isChanged = true;
                  });
                });
              },
            ),
            const SizedBox(height: 14),
            SpinnerField(
              label: AppLocalizations.of(context).preferencesRemindBeforeLabel,
              controller: _reminderOffsetController,
              maxValue: 100,
              maxSpinnerWidth: 120,
              trailing: DropDown(
                initialValue: ReminderConstants.offsetTypeItems.firstWhere(
                  (rot) => rot.value == _selectedReminderOffsetType,
                ),
                items: ReminderConstants.offsetTypeItems,
                onChanged: (value) {
                  setState(() {
                    _selectedReminderOffsetType = value!.value!;
                    _isChanged = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void onSubmit() {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    widget.onActionStarted?.call();

    final timeZone = _selectedTimeZone;
    final defaultView = CalendarConstants.defaultViews.indexOf(
      _selectedDefaultView,
    );
    final weekStartsOn = CalendarConstants.dayNames.indexOf(
      _selectedWeekStartsOn,
    );
    String eventsColor = HeliumColors.colorToHex(_selectedEventColor);
    if (eventsColor.length == 9) {
      eventsColor = '#${eventsColor.substring(3)}';
    }
    eventsColor = eventsColor.toLowerCase();
    String resourceColor = HeliumColors.colorToHex(_selectedResourceColor);
    if (resourceColor.length == 9) {
      resourceColor = '#${resourceColor.substring(3)}';
    }
    resourceColor = resourceColor.toLowerCase();
    String gradeColor = HeliumColors.colorToHex(_selectedGradeColor);
    if (gradeColor.length == 9) {
      gradeColor = '#${gradeColor.substring(3)}';
    }
    gradeColor = gradeColor.toLowerCase();
    final reminderType = ReminderConstants.typeForValue(_selectedReminderType);
    final reminderOffsetType = ReminderConstants.offsetTypes.indexOf(
      _selectedReminderOffsetType,
    );
    final reminderOffset = int.parse(_reminderOffsetController.text);
    final showPlannerTooltips = _isShowPlannerTooltips;
    final dragAndDropOnMobile = _isDragAndDropOnMobile;
    final colorByCategory = _isSelectedColorByCategory;
    final rememberFilterState = _isRememberFilterSelection;
    final collapseBusyDays = _isCollapseBusyDays;
    final showWeekNumbers = _isShowWeekNumbers;
    final atRiskThreshold = int.parse(_atRiskThresholdController.text);
    final onTrackTolerance = int.parse(_onTrackToleranceController.text);
    final priorCredits = HeliumNumber.normalize(_priorCreditsController.text);
    final priorGpa = HeliumNumber.normalize(_priorGpaController.text);

    context.read<AuthBloc>().add(
      UpdateProfileEvent(
        request: UpdateSettingsRequestModel(
          timeZone: timeZone,
          defaultView: _selectedDefaultView == _savedDefaultView ? null : defaultView,
          weekStartsOn: weekStartsOn,
          showPlannerTooltips: showPlannerTooltips,
          dragAndDropOnMobile: dragAndDropOnMobile,
          colorByCategory: colorByCategory,
          eventsColor: eventsColor,
          resourceColor: resourceColor,
          gradeColor: gradeColor,
          defaultReminderType: reminderType,
          defaultReminderOffset: reminderOffset,
          defaultReminderOffsetType: reminderOffsetType,
          rememberFilterState: rememberFilterState,
          collapseBusyDays: collapseBusyDays,
          showWeekNumbers: showWeekNumbers,
          atRiskThreshold: atRiskThreshold,
          onTrackTolerance: onTrackTolerance,
          priorCredits: priorCredits,
          priorGpa: priorGpa,
          dateFormat: _selectedDateFormat,
          timeFormat: _selectedTimeFormat,
          numberFormat: _selectedNumberFormat,
          language: _offersLanguageChoice ? _selectedLanguage : null,
        ),
      ),
    );
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  Widget _buildRegionalFormatFields() {
    final now = DateTime.now();
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _buildSegmentedField(
          key: const Key(PreferencesScreen.dateFormatField),
          label: AppLocalizations.of(context).preferencesDateFormatLabel,
          selected: _selectedDateFormat,
          segments: [
            for (final dateFormat in RegionalFormatConstants.dateFormats)
              ButtonSegment(value: dateFormat, label: Text(HeliumDateTime.dateFormatExample(dateFormat, now))),
          ],
          onChanged: (value) => _selectedDateFormat = value,
        ),
        _buildSegmentedField(
          key: const Key(PreferencesScreen.timeFormatField),
          label: AppLocalizations.of(context).preferencesTimeFormatLabel,
          selected: _selectedTimeFormat,
          segments: [
            for (final timeFormat in RegionalFormatConstants.timeFormats)
              ButtonSegment(value: timeFormat, label: Text(HeliumDateTime.timeFormatExample(timeFormat, now))),
          ],
          onChanged: (value) => _selectedTimeFormat = value,
        ),
        _buildSegmentedField(
          key: const Key(PreferencesScreen.numberFormatField),
          label: AppLocalizations.of(context).preferencesNumberFormatLabel,
          selected: _selectedNumberFormat,
          segments: [
            for (final numberFormat in RegionalFormatConstants.numberFormats)
              ButtonSegment(value: numberFormat, label: Text(HeliumNumber.numberFormatExample(numberFormat))),
          ],
          onChanged: (value) => _selectedNumberFormat = value,
        ),
      ],
    );
  }

  Widget _buildSegmentedField({
    required Key key,
    required String label,
    required int selected,
    required List<ButtonSegment<int>> segments,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppStyles.formLabel(context)),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          key: key,
          showSelectedIcon: false,
          segments: segments,
          selected: {selected},
          onSelectionChanged: (selection) {
            setState(() {
              onChanged(selection.first);
              _isChanged = true;
            });
          },
        ),
      ],
    );
  }

  bool get _offersLanguageChoice => HeliumLocale.offersLanguageChoice(
        languages: HeliumLocale.supportedLanguages,
        stored: widget.user.settings.language,
      );

  Widget _buildLanguageField() {
    final l10n = AppLocalizations.of(context);
    final items = [
      for (final (index, language) in HeliumLocale.supportedLanguages.indexed)
        DropDownItem<String>(id: index, value: language, label: HeliumLocale.nativeNames[language]!),
    ];
    return DropDown<String>(
      key: const Key(PreferencesScreen.languageField),
      label: l10n.preferencesLanguageLabel,
      initialValue: items.firstWhere((item) => item.value == _selectedLanguage),
      items: items,
      onChanged: (item) {
        setState(() {
          _selectedLanguage = item!.value!;
          _isChanged = true;
        });
      },
    );
  }

  Widget? _buildTimeZoneChangeNotice() {
    if (_hasCourseSchedules == false ||
        _isSubmitting ||
        _savedTimeZone == null ||
        _selectedTimeZone == _savedTimeZone) {
      return null;
    }

    final newLabel = _timeZoneLabel(_selectedTimeZone);
    if (newLabel == null) {
      _log.warning('Unknown time zone label, skipping the change notice');
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: WarningContainer(
        text: AppLocalizations.of(context).preferencesTimeZoneChangeNotice(newLabel),
        icon: Icons.access_time,
      ),
    );
  }

  String? _timeZoneLabel(String? timeZone) => TimeZoneConstants.items
      .firstWhereOrNull((item) => item.value == timeZone)
      ?.label;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(title, style: AppStyles.smallSecondaryTextEmphasis(context)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  void _populateScreenData(UserModel user) {
    final settings = user.settings;
    _selectedDefaultView = CalendarConstants.defaultViews[PlannerHelper.mapHeliumViewToApiView(
      PlannerHelper.mapApiViewToHeliumView(settings.defaultView),
    )];
    _savedDefaultView = _selectedDefaultView;
    _selectedWeekStartsOn =
        CalendarConstants.dayNames[settings.weekStartsOn];
    _selectedTimeZone = settings.timeZone.toString();
    _savedTimeZone = _selectedTimeZone;
    _selectedLanguage = settings.language;
    _selectedDateFormat = settings.dateFormat;
    _selectedTimeFormat = settings.timeFormat;
    _selectedNumberFormat = settings.numberFormat;
    _selectedReminderOffsetType = ReminderConstants
        .offsetTypes[settings.defaultReminderOffsetType];
    _selectedReminderType = ReminderConstants.itemForType(
      settings.defaultReminderType,
    ).value!;
    _selectedEventColor = settings.eventsColor;
    _selectedGradeColor = settings.gradeColor;
    _selectedResourceColor = settings.resourceColor;
    if (_reminderOffsetController.text !=
        settings.defaultReminderOffset.toString()) {
      _reminderOffsetController.text =
          settings.defaultReminderOffset.toString();
    }
    _isShowPlannerTooltips = settings.showPlannerTooltips;
    _isDragAndDropOnMobile = settings.dragAndDropOnMobile;
    _isSelectedColorByCategory = settings.colorByCategory;
    _isRememberFilterSelection = settings.rememberFilterState;
    _isCollapseBusyDays = settings.collapseBusyDays;
    _isShowWeekNumbers = settings.showWeekNumbers;
    if (_onTrackToleranceController.text !=
        settings.onTrackTolerance.toString()) {
      _onTrackToleranceController.text =
          settings.onTrackTolerance.toString();
    }
    if (_atRiskThresholdController.text !=
        settings.atRiskThreshold.toString()) {
      _atRiskThresholdController.text =
          settings.atRiskThreshold.toString();
    }
    final priorCredits = HeliumNumber.format(
      settings.priorCredits,
      fractionDigits: 2,
      trimZeros: true,
    );
    if (_priorCreditsController.text != priorCredits) {
      _priorCreditsController.text = priorCredits;
    }
    final priorGpa = HeliumNumber.format(
      settings.priorGpa,
      fractionDigits: 3,
      trimZeros: true,
    );
    if (_priorGpaController.text != priorGpa) {
      _priorGpaController.text = priorGpa;
    }

    if (!_changeTrackingActive) {
      _changeTrackingActive = true;
      _reminderOffsetController.addListener(_markChanged);
      _atRiskThresholdController.addListener(_markChanged);
      _onTrackToleranceController.addListener(_markChanged);
      _priorCreditsController.addListener(_markChanged);
      _priorGpaController.addListener(_markChanged);
    }
  }
}
