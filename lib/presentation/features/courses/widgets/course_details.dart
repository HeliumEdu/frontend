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
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/request/course_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/course_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/color_selector.dart';
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
import 'package:heliumapp/utils/url_helpers.dart';

final _log = Logger('presentation.widgets');

class CourseDetails extends StatefulWidget {
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;
  final VoidCallback? onSubmitRequested;
  final VoidCallback? onActionStarted;

  const CourseDetails({
    super.key,
    required this.courseGroupId,
    this.courseId,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
    this.onSubmitRequested,
    this.onActionStarted,
  });

  @override
  State<CourseDetails> createState() => CourseDetailsState();
}

class CourseDetailsState extends State<CourseDetails> {
  final CourseFormController formController = CourseFormController();

  bool isLoading = true;
  bool _isSubmitting = false;
  CourseGroupModel? _courseGroup;

  @override
  void initState() {
    super.initState();

    if (!widget.isEdit) formController.markChanged();

    formController.urlFocusNode.addListener(_onUrlFocusChange);

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
    formController.urlFocusNode.removeListener(_onUrlFocusChange);
    formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseScreenDataFetched) {
          _populateInitialStateData(state);
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
              key: formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: AppStyles.featureText(context)),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Title',
                    autofocus: kIsWeb || !widget.isEdit,
                    controller: formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: formController.getFieldKey('title'),
                    onChanged: (_) => formController.markChanged(),
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
                                        formController.startDate!,
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
                                        formController.endDate!,
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
                    controller: formController.urlController,
                    validator: BasicFormController.validateUrl,
                    fieldKey: formController.getFieldKey('url'),
                    focusNode: formController.urlFocusNode,
                    onChanged: (_) => formController.markChanged(),
                    trailingIconButton: HeliumIconButton(
                      onPressed: () {
                        UrlHelpers.launchWebUrl(
                          formController.urlController.text,
                        );
                      },
                      icon: Icons.launch_outlined,
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
                          controller: formController.teacherNameController,
                          onChanged: (_) => formController.markChanged(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabelAndTextFormField(
                          label: 'Email',
                          controller: formController.teacherEmailController,
                          onChanged: (_) => formController.markChanged(),
                          validator: BasicFormController.validateEmail,
                          fieldKey: formController.getFieldKey('teacherEmail'),
                          trailingIconButton: HeliumIconButton(
                            onPressed: () {
                              UrlHelpers.launchMailUrl(formController.teacherEmailController.text);
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
                            value: formController.isOnline,
                            onChanged: (value) {
                              formController.markChanged();
                              setState(() {
                                formController.isOnline = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!formController.isOnline) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: LabelAndTextFormField(
                              label: 'Location',
                              controller: formController.roomController,
                              onChanged: (_) => formController.markChanged(),
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
                              ColorSelector(
                                label: 'Color',
                                selectedColor: formController.selectedColor,
                                onColorSelected: (color) {
                                  formController.markChanged();
                                  setState(() {
                                    formController.selectedColor = color;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 120,
                              child: SpinnerField(
                                label: 'Credits',
                                controller: formController.creditsController,
                                step: 0.5,
                                allowDecimal: true,
                                onChanged: (_) => formController.markChanged(),
                              ),
                            ),
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

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  /// Submit the form. Called by parent screen when header save is pressed.
  bool onSubmit() {
    if (isLoading || _isSubmitting) return false;
    if (formController.validateAndScrollToError()) {
      // Notify parent that action is starting (validation passed)
      setState(() => _isSubmitting = true);
      widget.onActionStarted?.call();

      final request = CourseRequestModel(
        title: formController.titleController.text.trim(),
        room: formController.roomController.text.trim(),
        credits: formController.creditsController.text.trim().isEmpty
            ? '0'
            : formController.creditsController.text.trim(),
        color: HeliumColors.colorToHex(formController.selectedColor),
        website: formController.urlController.text.trim(),
        isOnline: formController.isOnline,
        teacherName: formController.teacherNameController.text.trim(),
        teacherEmail: formController.teacherEmailController.text.trim(),
        startDate: HeliumDateTime.formatDateForApi(formController.startDate!),
        endDate: HeliumDateTime.formatDateForApi(formController.endDate!),
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
        type: SnackType.error,
      );
      return false;
    }
  }

  void _onUrlFocusChange() {
    if (!formController.urlFocusNode.hasFocus) {
      formController.urlController.text = BasicFormController.cleanUrl(
        formController.urlController.text.trim(),
      );
    }
  }

  void _populateInitialStateData(CourseScreenDataFetched state) {
    setState(() {
      _courseGroup = state.courseGroup;

      if (widget.isEdit) {
        formController.titleController.text = state.course!.title;
        formController.roomController.text = state.course!.room;
        formController.urlController.text = state.course!.website?.toString() ?? '';
        formController.teacherNameController.text = state.course!.teacherName;
        formController.teacherEmailController.text =
            state.course!.teacherEmail;
        final credits = state.course!.credits;
        formController.creditsController.text = credits == 0
            ? ''
            : credits == credits.roundToDouble()
                ? credits.toStringAsFixed(0)
                : credits.toString();

        formController.startDate = state.course!.startDate;
        formController.endDate = state.course!.endDate;

        formController.isOnline = state.course!.isOnline;

        try {
          formController.selectedColor = state.course!.color;
        } catch (e) {
          _log.info('Error parsing color', e);
        }
      } else {
        formController.startDate = state.courseGroup.startDate;
        formController.endDate = state.courseGroup.endDate;
      }

      isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final firstDate = _courseGroup?.startDate ?? DateTime.now().subtract(const Duration(days: 365 * 10));
    final lastDate = _courseGroup?.endDate ?? DateTime.now().add(const Duration(days: 365 * 10));
    final rawInitial = isStartDate ? formController.startDate : formController.endDate;
    final initialDate = rawInitial == null ? firstDate
        : (rawInitial.isBefore(firstDate) ? firstDate
        : (rawInitial.isAfter(lastDate) ? lastDate : rawInitial));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      confirmText: 'Select',
    );

    if (picked != null) {
      formController.markChanged();
      setState(() {
        if (isStartDate) {
          formController.startDate = picked;
          formController.endDate = DateRangeEnforcer.adjustEndDate(
            picked,
            formController.endDate!,
          );
        } else {
          formController.endDate = picked;
          formController.startDate = DateRangeEnforcer.adjustStartDate(
            formController.startDate!,
            picked,
          );
        }
      });
    }
  }

}
