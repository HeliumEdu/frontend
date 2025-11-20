// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/auth_remote_data_source.dart';
import 'package:heliumedu/data/repositories/auth_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/preferenceBloc/preference_bloc.dart';
import 'package:heliumedu/presentation/bloc/preferenceBloc/preference_event.dart';
import 'package:heliumedu/presentation/bloc/preferenceBloc/preference_states.dart';
import 'package:heliumedu/presentation/widgets/custom_text_button.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_list.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';
import 'package:heliumedu/utils/custom_color_picker.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PreferenceBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
          ),
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

  @override
  void initState() {
    super.initState();
    _offsetController = TextEditingController(text: '0');
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
                              color: blackColor.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
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
                              color: blackColor.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            value: selectedTimezonePreference,
                            items: timezonesPreference.toSet().map((timeZone) {
                              return DropdownMenuItem(
                                value: timeZone,
                                child: Text(
                                  timeZone,
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
                              'Events color',
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
                          'Default Reminder Offset',
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
                                  color: blackColor.withOpacity(0.3),
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
                          'Default Reminder Offset Type',
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
                              color: blackColor.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down),
                            dropdownColor: whiteColor,
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text(
                              "Reminder Type",
                              style: AppTextStyle.eTextStyle.copyWith(
                                color: blackColor.withOpacity(0.5),
                              ),
                            ),
                            value: selectedReminderTypePreference,
                            items: reminderTimeUnits.map((course) {
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

                        SizedBox(height: 48.v),

                        BlocConsumer<PreferenceBloc, PreferenceState>(
                          listener: (context, state) {
                            if (state.submitSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: redColor,
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
                                  final idx = reminderTimeUnits.indexOf(
                                    selectedReminderTypePreference!,
                                  );
                                  return idx >= 0 ? idx : 0;
                                }();
                                final reminderPreferenceIndex = () {
                                  if (selectedReminderPreference == null) {
                                    return 0;
                                  }
                                  final idx = reminderPreferences.indexOf(
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
