// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/course_form_controller.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart' show HeliumColors;
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.widgets');

class CourseDetails extends StatefulWidget {
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;
  final VoidCallback? onSubmitRequested;

  const CourseDetails({
    super.key,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
    this.onSubmitRequested,
  });

  @override
  State<CourseDetails> createState() => CourseDetailsState();
}

class CourseDetailsState extends State<CourseDetails> {
  final CourseFormController _formController = CourseFormController();

  // State
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _formController.urlFocusNode.addListener(_onUrlFocusChange);

    context.read<CourseBloc>().add(
      FetchCourseScreenDataEvent(
        origin: EventOrigin.subScreen,
        courseGroupId: widget.courseGroupId,
        courseId: widget.courseId,
      ),
    );
  }

  @override
  void dispose() {
    _formController.urlFocusNode.removeListener(_onUrlFocusChange);
    _formController.dispose();
    super.dispose();
  }

  void _onUrlFocusChange() {
    if (!_formController.urlFocusNode.hasFocus) {
      _formController.urlController.text = BasicFormController.cleanUrl(
        _formController.urlController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseScreenDataFetched) {
          _populateInitialStateData(state);
        }

        if (state is! CoursesLoading) {
          setState(() {
            isSubmitting = false;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading || widget.userSettings == null) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: AppStyles.featureText(context)),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Title',
                    autofocus: kIsWeb || !widget.isEdit,
                    controller: _formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: _formController.getFieldKey('title'),
                    onFieldSubmitted: (value) => (widget.onSubmitRequested ?? onSubmit).call(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From', style: AppStyles.formLabel(context)),
                            const SizedBox(height: 9),
                            GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: context.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                  color: context.colorScheme.surface,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      HeliumDateTime.formatDate(
                                        _formController.startDate!,
                                      ),
                                      style: AppStyles.formText(context),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: context.colorScheme.primary,
                                      size: Responsive.getIconSize(
                                        context,
                                        mobile: 18,
                                        tablet: 20,
                                        desktop: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To', style: AppStyles.formLabel(context)),
                            const SizedBox(height: 9),
                            GestureDetector(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: context.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                  color: context.colorScheme.surface,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      HeliumDateTime.formatDate(
                                        _formController.endDate!,
                                      ),
                                      style: AppStyles.formText(context),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: context.colorScheme.primary,
                                      size: Responsive.getIconSize(
                                        context,
                                        mobile: 18,
                                        tablet: 20,
                                        desktop: 22,
                                      ),
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
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Website',
                    controller: _formController.urlController,
                    validator: BasicFormController.validateUrl,
                    fieldKey: _formController.getFieldKey('url'),
                    focusNode: _formController.urlFocusNode,
                    trailingIconButton: HeliumIconButton(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(_formController.urlController.text),
                        );
                      },
                      icon: Icons.link_outlined,
                      tooltip: 'Launch class website',
                      color: context.semanticColors.success,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabelAndTextFormField(
                          label: 'Teacher',
                          controller: _formController.teacherNameController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabelAndTextFormField(
                          label: 'Email',
                          controller: _formController.teacherEmailController,
                          validator: BasicFormController.validateEmail,
                          fieldKey: _formController.getFieldKey('teacherEmail'),
                          trailingIconButton: HeliumIconButton(
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'mailto:${_formController.teacherEmailController.text}',
                                ),
                              );
                            },
                            icon: Icons.email_outlined,
                            tooltip: 'Email teacher',
                            color: context.semanticColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Online',
                              style: AppStyles.formLabel(context),
                            ),
                            value: _formController.isOnline,
                            onChanged: (value) {
                              setState(() {
                                _formController.isOnline = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!_formController.isOnline) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: LabelAndTextFormField(
                              label: 'Location',
                              controller: _formController.roomController,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 88,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 9),
                              Text(
                                'Color',
                                style: AppStyles.formLabel(context),
                              ),
                              const SizedBox(width: 9),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    Feedback.forTap(context);
                                    showColorPickerDialog(
                                      parentContext: context,
                                      initialColor:
                                          _formController.selectedColor,
                                      onSelected: (color) {
                                        setState(() {
                                          _formController.selectedColor = color;
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: 33,
                                    height: 33,
                                    decoration: BoxDecoration(
                                      color: _formController.selectedColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: context.colorScheme.outline
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SpinnerField(
                            label: 'Credits',
                            controller: _formController.creditsController,
                            step: 0.5,
                            allowDecimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _populateInitialStateData(CourseScreenDataFetched state) {
    setState(() {
      if (widget.isEdit) {
        _formController.titleController.text = state.course!.title;
        _formController.roomController.text = state.course!.room;
        _formController.urlController.text = state.course!.website;
        _formController.teacherNameController.text = state.course!.teacherName;
        _formController.teacherEmailController.text =
            state.course!.teacherEmail;
        _formController.creditsController.text = state.course!.credits
            .toString();

        _formController.startDate = state.course!.startDate;
        _formController.endDate = state.course!.endDate;

        _formController.isOnline = state.course!.isOnline;

        try {
          _formController.selectedColor = state.course!.color;
        } catch (e) {
          _log.info('Error parsing color', e);
        }
      } else {
        _formController.startDate = state.courseGroup.startDate;
        _formController.endDate = state.courseGroup.endDate;
      }

      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _formController.startDate
          : _formController.endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _formController.startDate = picked;
        } else {
          _formController.endDate = picked;
        }
      });
    }
  }

  /// Submit the form. Called by parent screen when header save is pressed.
  bool onSubmit() {
    if (isLoading || isSubmitting) return false;
    if (_formController.validateAndScrollToError()) {
      if (_formController.endDate!.isBefore(_formController.startDate!)) {
        SnackBarHelper.show(
          context,
          '"To" date must come after "From" date',
          isError: true,
        );
        return false;
      }

      setState(() {
        isSubmitting = true;
      });

      final request = CourseRequestModel(
        title: _formController.titleController.text.trim(),
        room: _formController.roomController.text.trim(),
        credits: _formController.creditsController.text.trim().isEmpty
            ? '0'
            : _formController.creditsController.text.trim(),
        color: HeliumColors.colorToHex(_formController.selectedColor),
        website: _formController.urlController.text.trim(),
        isOnline: _formController.isOnline,
        teacherName: _formController.teacherNameController.text.trim(),
        teacherEmail: _formController.teacherEmailController.text.trim(),
        startDate: HeliumDateTime.formatDateForApi(_formController.startDate!),
        endDate: HeliumDateTime.formatDateForApi(_formController.endDate!),
        courseGroup: widget.courseGroupId,
      );

      if (widget.isEdit && widget.courseId != null) {
        context.read<CourseBloc>().add(
          UpdateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: widget.courseGroupId,
            courseId: widget.courseId!,
            request: request,
          ),
        );
      } else {
        context.read<CourseBloc>().add(
          CreateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: widget.courseGroupId,
            request: request,
          ),
        );
      }

      return true;
    } else {
      SnackBarHelper.show(
        context,
        'Fix the highlighted fields, then try again.',
        isError: true,
      );
      return false;
    }
  }
}
