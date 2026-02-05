// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/update_settings_request_model.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_state.dart';
import 'package:heliumapp/presentation/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/searchable_dropdown.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferenceViewState();
}

class _PreferenceViewState extends BasePageScreenState<PreferencesScreen> {
  final TextEditingController _reminderOffsetController =
      TextEditingController();

  // State
  Color _selectedEventColor = const Color(0xffe74674);
  Color _selectedMaterialColor = const Color(0xffdc7d50);
  Color _selectedGradeColor = const Color(0xff9d629d);
  String? _selectedDefaultView;
  String? _selectedWeekStartsOn;
  String? _selectedTimezone;
  String? _selectedReminderOffsetType;
  String? _selectedReminderType;
  bool _isSelectedColorByCategory = false;

  @override
  String get screenTitle => 'Settings';

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
            showSnackBar(context, 'Preferences saved');

            context.pop();
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
                  _selectedDefaultView = value!.value;
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
                  _selectedWeekStartsOn = value!.value;
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
                            context.pop();
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
                Text('Color for grade badges', style: AppStyles.formLabel(context)),
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
                          Navigator.pop(context);
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
                Text('Color for resource badges', style: AppStyles.formLabel(context)),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => showColorPickerDialog(
                      parentContext: context,
                      initialColor: _selectedMaterialColor,
                      onSelected: (color) {
                        setState(() {
                          _selectedMaterialColor = color;
                          Navigator.pop(context);
                        });
                      },
                    ),
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: _selectedMaterialColor,
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
                    title: Text('Color by category', style: AppStyles.formLabel(context)),
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

            // TODO: Feature Parity: implement "remember filter selection", make it apply to "show X on page" in todos view as well
            const SizedBox(height: 14),

            SearchableDropdown(
              label: 'Time zone',
              initialValue: TimeZoneConstants.items.firstWhere(
                (tz) => tz.value == _selectedTimezone,
              ),
              items: TimeZoneConstants.items,
              onChanged: (value) {
                setState(() {
                  _selectedTimezone = value!.value;
                });
              },
            ),

            const SizedBox(height: 14),
            DropDown(
              label: 'Default reminder type',
              initialValue: ReminderConstants.typeItems.firstWhere(
                (rt) => rt.value == _selectedReminderType,
              ),
              items: ReminderConstants.typeItems
                  .where(
                    (t) => _selectedReminderType != 'Text' && t.value != 'Text',
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReminderType = value!.value;
                });
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: LabelAndTextFormField(
                    label: 'Default reminder offset',
                    controller: _reminderOffsetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _reminderOffsetController.text = '0';
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          _reminderOffsetController.text =
                              (HeliumConversion.toInt(
                                        _reminderOffsetController.text,
                                      )! +
                                      1)
                                  .toString();
                        },
                        child: Icon(
                          Icons.arrow_drop_up,
                          size: Responsive.getIconSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          color: context.colorScheme.primary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _reminderOffsetController.text =
                              (HeliumConversion.toInt(
                                        _reminderOffsetController.text,
                                      )! -
                                      1)
                                  .toString();
                        },
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: Responsive.getIconSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            DropDown(
              label: 'Default reminder offset type',
              initialValue: ReminderConstants.offsetTypeItems.firstWhere(
                (rot) => rot.value == _selectedReminderOffsetType,
              ),
              items: ReminderConstants.offsetTypeItems,
              onChanged: (value) {
                setState(() {
                  _selectedReminderOffsetType = value!.value;
                });
              },
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
          CalendarConstants.defaultViews[state.user.settings!.defaultView];
      _selectedWeekStartsOn =
          CalendarConstants.dayNames[state.user.settings!.weekStartsOn];
      _selectedTimezone = state.user.settings!.timeZone.toString();
      _selectedReminderOffsetType = ReminderConstants
          .offsetTypes[state.user.settings!.defaultReminderOffsetType];
      _selectedReminderType =
          ReminderConstants.types[state.user.settings!.defaultReminderType];
      _selectedEventColor = state.user.settings!.eventsColor;
      _selectedGradeColor = state.user.settings!.gradeColor;
      _selectedMaterialColor = state.user.settings!.materialColor;
      if (_reminderOffsetController.text !=
          state.user.settings!.defaultReminderOffset.toString()) {
        _reminderOffsetController.text = state
            .user
            .settings!
            .defaultReminderOffset
            .toString();
      }
      _isSelectedColorByCategory = state.user.settings!.colorByCategory;

      isLoading = false;
    });
  }

  void _onSubmit() {
    setState(() {
      isSubmitting = true;
    });

    final timeZone = _selectedTimezone!;
    final defaultView =
        CalendarConstants.defaultViews.indexOf(_selectedDefaultView!);
    final weekStartsOn =
        CalendarConstants.dayNames.indexOf(_selectedWeekStartsOn!);
    String eventsColor = HeliumColors.colorToHex(_selectedEventColor);
    if (eventsColor.length == 9) {
      eventsColor = '#${eventsColor.substring(3)}';
    }
    eventsColor = eventsColor.toLowerCase();
    String materialColor = HeliumColors.colorToHex(_selectedMaterialColor);
    if (materialColor.length == 9) {
      materialColor = '#${materialColor.substring(3)}';
    }
    materialColor = materialColor.toLowerCase();
    String gradeColor = HeliumColors.colorToHex(_selectedGradeColor);
    if (gradeColor.length == 9) {
      gradeColor = '#${gradeColor.substring(3)}';
    }
    gradeColor = gradeColor.toLowerCase();
    final reminderType =
        ReminderConstants.types.indexOf(_selectedReminderType!);
    final reminderOffsetType =
        ReminderConstants.offsetTypes.indexOf(_selectedReminderOffsetType!);
    final reminderOffset = int.parse(_reminderOffsetController.text);
    final colorByCategory = _isSelectedColorByCategory;

    context.read<AuthBloc>().add(
      UpdateProfileEvent(
        request: UpdateSettingsRequestModel(
          timeZone: timeZone,
          defaultView: defaultView,
          weekStartsOn: weekStartsOn,
          colorByCategory: colorByCategory,
          eventsColor: eventsColor,
          materialColor: materialColor,
          gradeColor: gradeColor,
          defaultReminderType: reminderType,
          defaultReminderOffset: reminderOffset,
          defaultReminderOffsetType: reminderOffsetType,
        ),
      ),
    );
  }
}
