// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/searchable_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';

/// Shows as a dialog on desktop, or navigates on mobile.
void showPreferences(BuildContext context) {
  if (Responsive.isMobile(context)) {
    context.push(AppRoute.preferencesScreen);
  } else {
    showScreenAsDialog(
      context,
      child: const PreferencesScreen(),
      width: AppConstants.leftPanelDialogWidth,
      alignment: Alignment.centerLeft,
      insetPadding: const EdgeInsets.all(0),
    );
  }
}

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferenceViewState();
}

class _PreferenceViewState extends BasePageScreenState<PreferencesScreen> {
  final TextEditingController _reminderOffsetController =
      TextEditingController();

  // State
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
  bool _isSelectedColorByCategory = FallbackConstants.defaultColorByCategory;
  bool _isRememberFilterSelection =
      FallbackConstants.defaultRememberFilterState;

  @override
  String get screenTitle => 'Preferences';

  @override
  IconData get icon => Icons.tune;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function? get saveAction => _onSubmit;

  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(FetchProfileEvent());
  }

  @override
  void dispose() {
    _reminderOffsetController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is AuthProfileFetched) {
            _populateInitialStateData(state);
          } else if (state is AuthProfileUpdated) {
            if (!_isRememberFilterSelection) {
              PrefService().setString('saved_filter_state', '');
            }

            // No snackbar on updates

            if (DialogModeProvider.isDialogMode(context)) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          }

          if (state is! AuthLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Color for Events', style: AppStyles.formLabel(context)),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Feedback.forTap(context);
                      showColorPickerDialog(
                        parentContext: context,
                        initialColor: _selectedEventColor,
                        onSelected: (color) {
                          setState(() {
                            _selectedEventColor = color;
                          });
                        },
                      );
                    },
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: _selectedEventColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  'Color for grade badges',
                  style: AppStyles.formLabel(context),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => showColorPickerDialog(
                      parentContext: context,
                      initialColor: _selectedGradeColor,
                      onSelected: (color) {
                        setState(() {
                          _selectedGradeColor = color;
                        });
                      },
                    ),
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: _selectedGradeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  'Color for resource badges',
                  style: AppStyles.formLabel(context),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => showColorPickerDialog(
                      parentContext: context,
                      initialColor: _selectedResourceColor,
                      onSelected: (color) {
                        setState(() {
                          _selectedResourceColor = color;
                        });
                      },
                    ),
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: _selectedResourceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text(
                      'Show tooltips on Planner',
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
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
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
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text(
                      'Color by category',
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
                ),
              ],
            ),

            const SizedBox(height: 14),

            SearchableDropdown(
              label: 'Time zone',
              initialValue: TimeZoneConstants.items.firstWhere(
                (tz) => tz.value == _selectedTimeZone,
              ),
              items: TimeZoneConstants.items,
              onChanged: (value) {
                setState(() {
                  _selectedTimeZone = value!.value!;
                });
              },
            ),

            const SizedBox(height: 14),
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
                Expanded(
                  flex: 2,
                  child: SpinnerField(controller: _reminderOffsetController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
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
        _reminderOffsetController.text = state
            .user
            .settings
            .defaultReminderOffset
            .toString();
      }
      _isShowPlannerTooltips = state.user.settings.showPlannerTooltips;
      _isSelectedColorByCategory = state.user.settings.colorByCategory;
      _isRememberFilterSelection = state.user.settings.rememberFilterState;

      isLoading = false;
    });
  }

  void _onSubmit() {
    setState(() {
      isSubmitting = true;
    });

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
    final colorByCategory = _isSelectedColorByCategory;
    final rememberFilterState = _isRememberFilterSelection;

    context.read<AuthBloc>().add(
      UpdateProfileEvent(
        request: UpdateSettingsRequestModel(
          timeZone: timeZone,
          defaultView: defaultView,
          weekStartsOn: weekStartsOn,
          showPlannerTooltips: showPlannerTooltips,
          colorByCategory: colorByCategory,
          eventsColor: eventsColor,
          resourceColor: resourceColor,
          gradeColor: gradeColor,
          defaultReminderType: reminderType,
          defaultReminderOffset: reminderOffset,
          defaultReminderOffsetType: reminderOffsetType,
          rememberFilterState: rememberFilterState,
        ),
      ),
    );
  }
}
