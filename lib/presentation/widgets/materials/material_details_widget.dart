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
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/request/material_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart'
    as material_state;
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/controllers/materials/material_form_controller.dart';
import 'package:heliumapp/presentation/dialogs/select_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialDetailsWidget extends StatefulWidget {
  final int materialGroupId;
  final int? materialId;
  final bool isEdit;

  const MaterialDetailsWidget({
    super.key,
    required this.materialGroupId,
    this.materialId,
    required this.isEdit,
  });

  @override
  State<MaterialDetailsWidget> createState() => MaterialDetailsWidgetState();
}

class MaterialDetailsWidgetState extends State<MaterialDetailsWidget> {
  final MaterialFormController _formController = MaterialFormController();

  // State
  List<CourseModel> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _formController.urlFocusNode.addListener(_onUrlFocusChange);

    context.read<MaterialBloc>().add(
      FetchMaterialScreenDataEvent(
        origin: EventOrigin.subScreen,
        materialGroupId: widget.materialGroupId,
        materialId: widget.materialId,
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
    return BlocListener<MaterialBloc, material_state.MaterialState>(
      listener: (context, state) {
        if (state is material_state.MaterialScreenDataFetched) {
          _populateInitialStateData(state);
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
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
                  LabelAndTextFormField(
                    label: 'Title',
                    autofocus: kIsWeb || !widget.isEdit,
                    controller: _formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: _formController.getFieldKey('title'),
                    onFieldSubmitted: (value) => onSubmit(),
                  ),
                  const SizedBox(height: 14),
                  Text('Classes', style: AppStyles.formLabel(context)),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      color: context.colorScheme.surface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_formController.selectedCourses.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: _formController.selectedCourses.map((id) {
                              final course = _courses.firstWhere(
                                (c) => c.id == id,
                              );
                              return CourseTitleLabel(
                                title: course.title,
                                color: course.color,
                                onDelete: () {
                                  setState(() {
                                    _formController.selectedCourses.remove(id);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AbsorbPointer(
                            absorbing: _courses.isEmpty,
                            child: Opacity(
                              opacity: _courses.isEmpty ? 0.5 : 1,
                              child: TextButton.icon(
                                onPressed: () => showSelectDialog<CourseModel>(
                                  parentContext: context,
                                  items: _courses,
                                  initialSelected: _formController
                                      .selectedCourses
                                      .toSet(),
                                  onConfirm: (selected) {
                                    setState(() {
                                      _formController.selectedCourses = selected
                                          .toList();
                                    });
                                  },
                                ),
                                icon: Icon(
                                  Icons.add,
                                  color: context.colorScheme.primary,
                                ),
                                label: Text(
                                  'Select classes',
                                  style: AppStyles.formLabel(context).copyWith(
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropDown(
                    label: 'Status',
                    initialValue: MaterialConstants.statusItems.firstWhere(
                      (mc) => mc.id == _formController.selectedStatus,
                    ),
                    items: MaterialConstants.statusItems,
                    onChanged: (value) {
                      setState(() {
                        _formController.selectedStatus = value!.id;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropDown(
                    label: 'Condition',
                    initialValue: MaterialConstants.conditionItems.firstWhere(
                      (mc) => mc.id == _formController.selectedCondition,
                    ),
                    items: MaterialConstants.conditionItems,
                    onChanged: (value) {
                      setState(() {
                        _formController.selectedCondition = value!.id;
                      });
                    },
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
                      tooltip: "Launch resource's website",
                      color: context.semanticColors.success,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Price',
                    controller: _formController.priceController,
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

  void _populateInitialStateData(
    material_state.MaterialScreenDataFetched state,
  ) {
    setState(() {
      _courses = state.courses;
      Sort.byTitle(_courses);

      if (widget.isEdit) {
        _formController.titleController.text = state.material!.title;
        _formController.urlController.text = state.material!.website;
        _formController.priceController.text = state.material!.price ?? '';
        _formController.initialNotes = state.material!.details ?? '';

        _formController.selectedStatus = state.material!.status;
        _formController.selectedCondition = state.material!.condition;
        _formController.selectedCourses = List<int>.from(
          state.material!.courses,
        );
      }

      _isLoading = false;
    });
  }

  Future<void> onSubmit() async {
    if (_formController.validateAndScrollToError()) {
      final request = MaterialRequestModel(
        title: _formController.titleController.text.trim(),
        status: _formController.selectedStatus,
        condition: _formController.selectedCondition,
        website: _formController.urlController.text.trim().isEmpty
            ? ''
            : _formController.urlController.text.trim(),
        price: _formController.priceController.text.trim().isEmpty
            ? ''
            : _formController.priceController.text.trim(),
        details: widget.isEdit ? _formController.initialNotes : '',
        courses: _formController.selectedCourses,
        materialGroup: widget.materialGroupId,
      );

      if (!mounted) return;
      if (widget.isEdit && widget.materialId != null) {
        context.read<MaterialBloc>().add(
          UpdateMaterialEvent(
            origin: EventOrigin.subScreen,
            materialGroupId: widget.materialGroupId,
            materialId: widget.materialId!,
            request: request,
          ),
        );
      } else {
        context.read<MaterialBloc>().add(
          CreateMaterialEvent(
            origin: EventOrigin.subScreen,
            materialGroupId: widget.materialGroupId,
            request: request,
          ),
        );
      }
    } else {
      SnackBarHelper.show(
        context,
        'Fix the highlighted fields, then try again.',
        isError: true,
      );
    }
  }
}
