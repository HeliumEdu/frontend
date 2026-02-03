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
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_bloc.dart';
import 'package:heliumapp/presentation/bloc/course/course_event.dart';
import 'package:heliumapp/presentation/bloc/course/course_state.dart';
import 'package:heliumapp/presentation/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/controllers/courses/course_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/course_add_stepper.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart' show HeliumColors;
import 'package:heliumapp/utils/conversion_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.views');

class CourseAddProvidedScreen extends StatefulWidget {
  final int courseGroupId;
  final int? courseId;
  final bool isEdit;

  const CourseAddProvidedScreen({
    super.key,
    required this.courseGroupId,
    this.courseId,
    this.isEdit = false,
  });

  @override
  State<CourseAddProvidedScreen> createState() => _CourseAddScreenState();
}

class _CourseAddScreenState
    extends BasePageScreenState<CourseAddProvidedScreen> {
  @override
  String get screenTitle => widget.isEdit ? 'Edit Class' : 'Add Class';

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function get saveAction => _onSubmit;

  final CourseFormController _formController = CourseFormController();

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
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CoursesError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is CourseScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is CourseCreated || state is CourseUpdated) {
            state as CourseEntityState;

            showSnackBar(context, 'Class saved');

            if (state.advanceNavOnSuccess) {
              context.pushReplacement(
                AppRoutes.courseAddScheduleScreen,
                extra: CourseAddArgs(
                  courseBloc: context.read<CourseBloc>(),
                  courseGroupId: state.course.courseGroup,
                  courseId: state.course.id,
                  isEdit: true,
                ),
              );
            }
          }

          if (state is! CoursesLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return CourseStepper(
      selectedIndex: 0,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      isEdit: widget.isEdit,
      onStep: () => _onSubmit(advanceNavOnSuccess: false),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Form(
          key: _formController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelAndTextFormField(
                label: 'Title',
                autofocus: !widget.isEdit || !Responsive.isMobile(context),
                controller: _formController.titleController,
                validator: BasicFormController.validateRequiredField,
                fieldKey: _formController.getFieldKey('title'),
                onFieldSubmitted: (value) =>
                    _onSubmit(advanceNavOnSuccess: !widget.isEdit),
              ),
              const SizedBox(height: 14),
              Text('From', style: context.formLabel),
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
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    color: context.colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        HeliumDateTime.formatDateForDisplay(
                          _formController.startDate!,
                        ),
                        style: context.formText,
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
              const SizedBox(height: 14),
              Text('To', style: context.formLabel),
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
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    color: context.colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        HeliumDateTime.formatDateForDisplay(
                          _formController.endDate!,
                        ),
                        style: context.formText,
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
              const SizedBox(height: 14),

              if (!_formController.isOnline) ...[
                LabelAndTextFormField(
                  label: 'Room',
                  controller: _formController.roomController,
                ),
                const SizedBox(height: 14),
              ],

              LabelAndTextFormField(
                label: 'Website',
                controller: _formController.urlController,
                validator: BasicFormController.validateUrl,
                fieldKey: _formController.getFieldKey('url'),
                focusNode: _formController.urlFocusNode,
                trailingIconButton: HeliumIconButton(
                  onPressed: () {
                    launchUrl(Uri.parse(_formController.urlController.text));
                  },
                  icon: Icons.link_outlined,
                  color: context.semanticColors.success,
                ),
              ),
              const SizedBox(height: 14),
              LabelAndTextFormField(
                label: 'Teacher',
                controller: _formController.teacherNameController,
              ),
              const SizedBox(height: 14),
              LabelAndTextFormField(
                label: 'Teacher Email',
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
                  color: context.semanticColors.info,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      label: 'Credits',
                      controller: _formController.creditsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _formController.creditsController.text = '0';
                        } else {
                          _formController.creditsController.text = value;
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
                            _formController.creditsController.text =
                                (HeliumConversion.toDouble(
                                          _formController
                                              .creditsController
                                              .text,
                                        )! +
                                        .5)
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
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _formController.creditsController.text =
                                (HeliumConversion.toDouble(
                                          _formController
                                              .creditsController
                                              .text,
                                        )! -
                                        .5)
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
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('Online', style: context.formLabel),
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
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Text('Color', style: context.formLabel),
                  const SizedBox(width: 12),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Feedback.forTap(context);
                        showColorPickerDialog(
                          parentContext: context,
                          initialColor: _formController.selectedColor,
                          onSelected: (color) {
                            setState(() {
                              _formController.selectedColor = color;
                              context.pop();
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

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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

        _formController.startDate = DateTime.parse(state.course!.startDate);
        _formController.endDate = DateTime.parse(state.course!.endDate);

        _formController.isOnline = state.course!.isOnline;

        // Parse color
        try {
          _formController.selectedColor = state.course!.color;
        } catch (e) {
          _log.info('Error parsing color: $e');
        }
      } else {
        _formController.startDate = DateTime.parse(state.courseGroup.startDate);
        _formController.endDate = DateTime.parse(state.courseGroup.endDate);
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

  bool _onSubmit({bool advanceNavOnSuccess = true}) {
    if (_formController.validateAndScrollToError()) {
      if (_formController.endDate!.isBefore(_formController.startDate!)) {
        showSnackBar(
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
        // TODO: only submit if actual changes are made
        context.read<CourseBloc>().add(
          UpdateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: widget.courseGroupId,
            courseId: widget.courseId!,
            request: request,
            advanceNavOnSuccess: false,
          ),
        );
      } else {
        context.read<CourseBloc>().add(
          CreateCourseEvent(
            origin: EventOrigin.subScreen,
            courseGroupId: widget.courseGroupId,
            request: request,
            advanceNavOnSuccess: advanceNavOnSuccess,
          ),
        );
      }

      return true;
    } else {
      showSnackBar(
        context,
        'Fix the highlighted fields, then try again.',
        isError: true,
      );

      return false;
    }
  }
}
