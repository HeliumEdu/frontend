// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/components/searchable_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/components/color_selector.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';

class PreferencesScreen extends StatefulWidget {
  final UserSettingsModel? userSettings;
  final VoidCallback? onActionStarted;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const PreferencesScreen({
    super.key,
    this.userSettings,
    this.onActionStarted,
    this.onCompleted,
    this.onFailed,
  });

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController _reminderOffsetController =
      TextEditingController();
  final TextEditingController _atRiskThresholdController =
      TextEditingController();
  final TextEditingController _onTrackToleranceController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  Color _selectedEventColor = FallbackConstants.defaultEventsColor;
  Color _selectedResourceColor = FallbackConstants.defaultResourceColor;
  Color _selectedGradeColor = FallbackConstants.defaultGradeColor;
  String _selectedDefaultView =
      CalendarConstants.defaultViews[FallbackConstants.defaultViewIndex];
  String _selectedWeekStartsOn =
      CalendarConstants.dayNames[FallbackConstants.defaultWeekStartsOn];
  String _selectedTimeZone = FallbackConstants.defaultTimeZone;
  String _selectedReminderOffsetType = ReminderConstants
      .offsetTypes[FallbackConstants.defaultReminderOffsetType];
  String _selectedReminderType =
      ReminderConstants.types[FallbackConstants.defaultReminderType];
  bool _isShowPlannerTooltips = FallbackConstants.defaultShowPlannerTooltips;
  bool _isDragAndDropOnMobile = FallbackConstants.defaultDragAndDropOnMobile;
  bool _isSelectedColorByCategory = FallbackConstants.defaultColorByCategory;
  bool _isRememberFilterSelection =
      FallbackConstants.defaultRememberFilterState;
  bool _isCollapseBusyDays = FallbackConstants.defaultCollapseBusyDays;
  bool _isShowWeekNumbers = FallbackConstants.defaultShowWeekNumbers;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

  @override
  void dispose() {
    _reminderOffsetController.dispose();
    _atRiskThresholdController.dispose();
    _onTrackToleranceController.dispose();
    super.dispose();
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
    final reminderType = ReminderConstants.types.indexOf(_selectedReminderType);
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

    context.read<AuthBloc>().add(
      UpdateProfileEvent(
        request: UpdateSettingsRequestModel(
          timeZone: timeZone,
          defaultView: defaultView,
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
        ),
      ),
    );
  }

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileError) {
          SnackBarHelper.show(context, state.message!, type: SnackType.error);
          setState(() => _isSubmitting = false);
          widget.onFailed?.call();
        } else if (state is AuthProfileFetched) {
          setState(() => _isLoading = false);
          _populateInitialStateData(state);
        } else if (state is AuthProfileUpdated) {
          if (!_isRememberFilterSelection) {
            PrefService().setString('saved_filter_state', '');
          }
          widget.onCompleted?.call();
        }
      },
      child: _isLoading
          ? const Center(child: LoadingIndicator(expanded: false))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('GENERAL'),
            SearchableDropdown(
              label: 'Time zone',
              initialValue: TimeZoneConstants.items.firstWhere(
                (tz) => tz.value == _selectedTimeZone,
                orElse: () => TimeZoneConstants.items.firstWhere(
                  (tz) => tz.value == 'Etc/UTC',
                ),
              ),
              items: TimeZoneConstants.items,
              onChanged: (value) {
                setState(() {
                  _selectedTimeZone = value!.value!;
                });
              },
            ),

            _buildSectionHeader('PLANNER'),
            DropDown(
              label: 'Default view',
              initialValue: CalendarConstants.defaultViewItems.firstWhere(
                (dv) => dv.value == _selectedDefaultView,
              ),
              items: CalendarConstants.defaultViewItems,
              onChanged: (value) {
                setState(() {
                  _selectedDefaultView = value!.value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text(
                'Remember filter selections',
                style: AppStyles.formLabel(context),
              ),
              value: _isRememberFilterSelection,
              onChanged: (value) {
                setState(() {
                  _isRememberFilterSelection = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(
                'Drag-and-drop on touch devices',
                style: AppStyles.formLabel(context),
              ),
              value: _isDragAndDropOnMobile,
              onChanged: (value) {
                setState(() {
                  _isDragAndDropOnMobile = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(
                'Show tooltips',
                style: AppStyles.formLabel(context),
              ),
              value: _isShowPlannerTooltips,
              onChanged: (value) {
                setState(() {
                  _isShowPlannerTooltips = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            _buildSectionHeader('CALENDAR'),
            DropDown(
              label: 'Week starts on',
              initialValue: CalendarConstants.dayNamesItems.firstWhere(
                (fd) => fd.value == _selectedWeekStartsOn,
              ),
              items: CalendarConstants.dayNamesItems,
              onChanged: (value) {
                setState(() {
                  _selectedWeekStartsOn = value!.value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text(
                'Collapse busy days',
                style: AppStyles.formLabel(context),
              ),
              value: _isCollapseBusyDays,
              onChanged: (value) {
                setState(() {
                  _isCollapseBusyDays = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(
                'Show week numbers',
                style: AppStyles.formLabel(context),
              ),
              value: _isShowWeekNumbers,
              onChanged: (value) {
                setState(() {
                  _isShowWeekNumbers = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            _buildSectionHeader('DISPLAY'),
            Row(
              children: [
                SizedBox(width: 160, child: Text('Color for Events', style: AppStyles.formLabel(context))),
                ColorSelector(
                  selectedColor: _selectedEventColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedEventColor = color;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(width: 160, child: Text('Color for grades', style: AppStyles.formLabel(context))),
                ColorSelector(
                  selectedColor: _selectedGradeColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedGradeColor = color;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(width: 160, child: Text('Color for resources', style: AppStyles.formLabel(context))),
                ColorSelector(
                  selectedColor: _selectedResourceColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedResourceColor = color;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              title: Text(
                'Color by assignment category',
                style: AppStyles.formLabel(context),
              ),
              value: _isSelectedColorByCategory,
              onChanged: (value) {
                setState(() {
                  _isSelectedColorByCategory = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            _buildSectionHeader('GRADES'),
            Text(
              'At-risk threshold (%)',
              style: AppStyles.formLabel(context),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: SpinnerField(
                controller: _atRiskThresholdController,
                minValue: 0,
                maxValue: 100,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'On-track tolerance (%)',
              style: AppStyles.formLabel(context),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: SpinnerField(
                controller: _onTrackToleranceController,
                minValue: 0,
                maxValue: 100,
              ),
            ),

            _buildSectionHeader('REMINDERS'),
            DropDown(
              label: 'Default reminder',
              initialValue: ReminderConstants.typeItems.firstWhere(
                (rt) => rt.value == _selectedReminderType,
              ),
              items: ReminderConstants.typeItems
                  .where(
                    (t) =>
                        t.value == _selectedReminderType ||
                        (t.value != 'Text' && t.value != 'Popup'),
                  )
                  .toList(),
              onChanged: (value) {
                // Delay state update to avoid layout exception when items list changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    _selectedReminderType = value!.value!;
                  });
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Default "Remind before"',
              style: AppStyles.formLabel(context),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: SpinnerField(controller: _reminderOffsetController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropDown(
                    initialValue: ReminderConstants.offsetTypeItems.firstWhere(
                      (rot) => rot.value == _selectedReminderOffsetType,
                    ),
                    items: ReminderConstants.offsetTypeItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedReminderOffsetType = value!.value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(title, style: AppStyles.smallSecondaryTextLight(context)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  void _populateInitialStateData(AuthProfileFetched state) {
    setState(() {
      _selectedDefaultView =
          CalendarConstants.defaultViews[state.user.settings.defaultView];
      _selectedWeekStartsOn =
          CalendarConstants.dayNames[state.user.settings.weekStartsOn];
      _selectedTimeZone = state.user.settings.timeZone.toString();
      _selectedReminderOffsetType = ReminderConstants
          .offsetTypes[state.user.settings.defaultReminderOffsetType];
      _selectedReminderType =
          ReminderConstants.types[state.user.settings.defaultReminderType];
      _selectedEventColor = state.user.settings.eventsColor;
      _selectedGradeColor = state.user.settings.gradeColor;
      _selectedResourceColor = state.user.settings.resourceColor;
      if (_reminderOffsetController.text !=
          state.user.settings.defaultReminderOffset.toString()) {
        _reminderOffsetController.text =
            state.user.settings.defaultReminderOffset.toString();
      }
      _isShowPlannerTooltips = state.user.settings.showPlannerTooltips;
      _isDragAndDropOnMobile = state.user.settings.dragAndDropOnMobile;
      _isSelectedColorByCategory = state.user.settings.colorByCategory;
      _isRememberFilterSelection = state.user.settings.rememberFilterState;
      _isCollapseBusyDays = state.user.settings.collapseBusyDays;
      _isShowWeekNumbers = state.user.settings.showWeekNumbers;
      if (_onTrackToleranceController.text !=
          state.user.settings.onTrackTolerance.toString()) {
        _onTrackToleranceController.text =
            state.user.settings.onTrackTolerance.toString();
      }
      if (_atRiskThresholdController.text !=
          state.user.settings.atRiskThreshold.toString()) {
        _atRiskThresholdController.text =
            state.user.settings.atRiskThreshold.toString();
      }
    });
  }
}
