// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/presentation/bloc/settings/preferences_bloc.dart';
import 'package:heliumapp/presentation/bloc/settings/preferences_event.dart';
import 'package:heliumapp/presentation/bloc/settings/preferences_states.dart';
import 'package:heliumapp/presentation/widgets/helium_color_picker.dart';
import 'package:heliumapp/presentation/widgets/helium_text_button.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_enums.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PreferencesBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
          ),
        ),
      ],
      child: PreferenceView(),
    );
  }
}

class PreferenceView extends StatefulWidget {
  const PreferenceView({super.key});

  @override
  State<PreferenceView> createState() => _PreferenceViewState();
}

Color selectedEventColor = const Color(0xffe74674);
Color selectedMaterialColor = const Color(0xffdc7d50);
Color selectedGradeColor = const Color(0xff9d629d);
String? selectedDefaultView;
String? selectedTimezone;
String? selectedReminderOffsetUnit;

class _PreferenceViewState extends State<PreferenceView> {
  late TextEditingController _offsetController;

  @override
  void initState() {
    super.initState();
    _offsetController = TextEditingController(text: '0');
    // Fetch current preferences on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PreferencesBloc>().add(FetchPreferencesEvent());
      }
    });
  }

  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }

  void _showEventColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        contentPadding: EdgeInsets.zero,
        content: HeliumColorPickerWidget(
          initialColor: selectedEventColor,
          onColorSelected: (color) {
            setState(() {
              selectedEventColor = color;
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  void _showGradeColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        contentPadding: EdgeInsets.zero,
        content: HeliumColorPickerWidget(
          initialColor: selectedGradeColor,
          onColorSelected: (color) {
            setState(() {
              selectedGradeColor = color;
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  void _showMaterialColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        contentPadding: EdgeInsets.zero,
        content: HeliumColorPickerWidget(
          initialColor: selectedMaterialColor,
          onColorSelected: (color) {
            setState(() {
              selectedMaterialColor = color;
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PreferencesBloc, PreferencesState>(
          listener: (context, state) {
            setState(() {
              if (state.defaultView != null) {
                selectedDefaultView = state.defaultView;
              }
              selectedTimezone = state.timeZone;
              if (!timeZones.contains(selectedTimezone)) {
                // Fallback to UTC if default isn't present
                selectedTimezone = 'Etc/UTC';
              }
              if (state.reminderOffsetUnit != null) {
                selectedReminderOffsetUnit = state.reminderOffsetUnit;
              }
              selectedEventColor = state.eventsColor;
              if (_offsetController.text != state.reminderOffset.toString()) {
                _offsetController.text = state.reminderOffset.toString();
              }
            });
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
                      'Preferences',
                      style: AppStyle.bTextStyle.copyWith(
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
                          'Default view',
                          style: AppStyle.cTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.8),
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
                              color: blackColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            value: selectedDefaultView,
                            items: mobileViews.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppStyle.eTextStyle.copyWith(
                                    color: blackColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDefaultView = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 22.h),
                        Text(
                          'Time zone',
                          style: AppStyle.cTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.8),
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
                              color: blackColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            value: selectedTimezone,
                            items: timeZones.map((timeZone) {
                              return DropdownMenuItem(
                                value: timeZone,
                                child: Text(
                                  timeZone,
                                  style: AppStyle.eTextStyle.copyWith(
                                    color: blackColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTimezone = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 22.v),
                        Row(
                          children: [
                            Text(
                              'Color for Events',
                              style: AppStyle.cTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.8),
                              ),
                            ),
                            SizedBox(width: 12.h),
                            GestureDetector(
                              onTap: _showEventColorPicker,
                              child: Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  color: selectedEventColor,
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
                        SizedBox(height: 22.h),

                        Row(
                          children: [
                            Text(
                              'Color for grades badges',
                              style: AppStyle.cTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.8),
                              ),
                            ),
                            SizedBox(width: 12.h),
                            GestureDetector(
                              onTap: _showGradeColorPicker,
                              child: Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  color: selectedGradeColor,
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
                        SizedBox(height: 22.h),

                        Row(
                          children: [
                            Text(
                              'Color for material badges',
                              style: AppStyle.cTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.8),
                              ),
                            ),
                            SizedBox(width: 12.h),
                            GestureDetector(
                              onTap: _showMaterialColorPicker,
                              child: Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  color: selectedMaterialColor,
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
                        SizedBox(height: 22.h),

                        // BLoC Implementation for Offset Field
                        Text(
                          'Default reminder offset',
                          style: AppStyle.cTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 9.v),
                        BlocConsumer<PreferencesBloc, PreferencesState>(
                          listener: (context, state) {
                            // Update text controller when state changes
                            if (_offsetController.text !=
                                state.reminderOffset.toString()) {
                              _offsetController.text = state.reminderOffset
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
                                  color: blackColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _offsetController,
                                      keyboardType: TextInputType.number,
                                      style: AppStyle.eTextStyle.copyWith(
                                        color: blackColor.withValues(
                                          alpha: 0.6,
                                        ),
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
                                          context.read<PreferencesBloc>().add(
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
                                          context.read<PreferencesBloc>().add(
                                            IncrementOffsetEvent(),
                                          );
                                        },
                                        child: Icon(
                                          Icons.arrow_drop_up,
                                          size: 20,
                                          color: blackColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          context.read<PreferencesBloc>().add(
                                            DecrementOffsetEvent(),
                                          );
                                        },
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          size: 20,
                                          color: blackColor.withValues(
                                            alpha: 0.6,
                                          ),
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
                          'Default reminder offset type',
                          style: AppStyle.cTextStyle.copyWith(
                            color: blackColor.withValues(alpha: 0.8),
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
                              color: blackColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              '',
                              style: AppStyle.eTextStyle.copyWith(
                                color: blackColor.withValues(alpha: 0.5),
                              ),
                            ),
                            value: selectedReminderOffsetUnit,
                            items: reminderOffsetUnits.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  course,
                                  style: AppStyle.eTextStyle.copyWith(
                                    color: blackColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReminderOffsetUnit = value!;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: 48.v),

                        BlocConsumer<PreferencesBloc, PreferencesState>(
                          listener: (context, state) {
                            if (state.submitSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: greenColor,
                                  content: Text(
                                    'Preferences updated successfully',
                                  ),
                                ),
                              );
                            } else if (state.submitError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: redColor,
                                  content: Text(state.submitError!),
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            final isSubmitting = state.isSubmitting;
                            return HeliumTextButton(
                              buttonText: 'Save',
                              isLoading: isSubmitting,
                              onPressed: () {
                                final tz = selectedTimezone ?? 'Etc/UTC';
                                final viewIndex = selectedDefaultView == null
                                    ? 0
                                    : mobileViews.indexOf(selectedDefaultView!);
                                // Normalize to #rrggbb (strip alpha and ensure #)
                                String eventColorHex =
                                    '#${selectedEventColor.value.toRadixString(16).substring(2)}';
                                if (eventColorHex.length == 9) {
                                  eventColorHex =
                                      '#${eventColorHex.substring(3)}';
                                }
                                eventColorHex = eventColorHex.toLowerCase();
                                String materialsColorHex =
                                    '#${selectedMaterialColor.value.toRadixString(16).substring(2)}';
                                if (materialsColorHex.length == 9) {
                                  materialsColorHex =
                                      '#${materialsColorHex.substring(3)}';
                                }
                                materialsColorHex = materialsColorHex
                                    .toLowerCase();
                                String gradesColorHex =
                                    '#${selectedGradeColor.value.toRadixString(16).substring(2)}';
                                if (gradesColorHex.length == 9) {
                                  gradesColorHex =
                                      '#${gradesColorHex.substring(3)}';
                                }
                                gradesColorHex = gradesColorHex.toLowerCase();
                                final reminderTypeIndex = () {
                                  if (selectedReminderOffsetUnit == null) {
                                    return 0;
                                  }
                                  final idx = reminderOffsetUnits.indexOf(
                                    selectedReminderOffsetUnit!,
                                  );
                                  return idx >= 0 ? idx : 0;
                                }();
                                final offsetVal =
                                    int.tryParse(_offsetController.text) ?? 0;

                                context.read<PreferencesBloc>().add(
                                  SubmitPreferencesEvent(
                                    timeZone: tz,
                                    defaultView: viewIndex,
                                    eventsColor: eventColorHex,
                                    gradesColor: eventColorHex,
                                    materialsColor: eventColorHex,
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
