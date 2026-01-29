// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/material_request_model.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_bloc.dart';
import 'package:heliumapp/presentation/bloc/material/material_event.dart';
import 'package:heliumapp/presentation/bloc/material/material_state.dart'
    as material_state;
import 'package:heliumapp/presentation/dialogs/select_dialog.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/forms/materials/material_form_controller.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class MaterialAddProvidedScreen extends StatefulWidget {
  final int materialGroupId;
  final int? materialId;
  final bool isEdit;

  const MaterialAddProvidedScreen({
    super.key,
    required this.materialGroupId,
    this.materialId,
    this.isEdit = false,
  });

  @override
  State<MaterialAddProvidedScreen> createState() => _MaterialAddScreenState();
}

class _MaterialAddScreenState
    extends BasePageScreenState<MaterialAddProvidedScreen> {
  @override
  String get screenTitle => widget.isEdit ? 'Edit Material' : 'Add Material';

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function get saveAction => _handleSubmit;

  final MaterialFormController _formController = MaterialFormController();

  // State
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();

    context.read<MaterialBloc>().add(
      FetchMaterialScreenDataEvent(
        origin: EventOrigin.screen,
        materialGroupId: widget.materialGroupId,
        materialId: widget.materialId,
      ),
    );
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<MaterialBloc, material_state.MaterialState>(
        listener: (context, state) {
          if (state is material_state.MaterialsError) {
            showSnackBar(context, state.message!, isError: true);
          } else if (state is material_state.MaterialScreenDataFetched) {
            _populateInitialStateData(state);
          } else if (state is material_state.MaterialCreated ||
              state is material_state.MaterialUpdated) {
            showSnackBar(context, 'Material saved');

            context.pop();
          }

          if (state is! material_state.MaterialsLoading) {
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
        child: Form(
          key: _formController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelAndTextFormField(
                label: 'Title',
                autofocus: true,
                controller: _formController.titleController,
                validator: BasicFormController.validateRequiredField,
                fieldKey: _formController.getFieldKey('title'),
                onFieldSubmitted: (value) => _handleSubmit(),
              ),
              const SizedBox(height: 14),
              Text('Classes', style: context.formLabel),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  color: context.colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_formController.selectedCourses.isEmpty)
                      Text(
                        (_courses.isEmpty && _courses.isEmpty)
                            ? 'No classes available'
                            : '',
                        style: context.formText,
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: _formController.selectedCourses.map((id) {
                          return Chip(
                            backgroundColor: _courses
                                .where((c) => c.id == id)
                                .first
                                .color,
                            deleteIconColor: context.colorScheme.surface,
                            label: Text(
                              _courses.firstWhere((c) => c.id == id).title,
                              style: context.formText.copyWith(
                                color: context.colorScheme.surface,
                              ),
                            ),
                            onDeleted: () {
                              setState(() {
                                _formController.selectedCourses.remove(id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 6),
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
                              initialSelected: _formController.selectedCourses
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
                              style: context.formLabel.copyWith(
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
              // TODO: add HeliumIconButton to take user to website (if specified)
              LabelAndTextFormField(
                label: 'Website',
                controller: _formController.urlController,
                validator: BasicFormController.validateUrl,
                fieldKey: _formController.getFieldKey('url'),
              ),
              const SizedBox(height: 14),
              LabelAndTextFormField(
                label: 'Price',
                controller: _formController.priceController,
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 9),

              // TODO: migrate to quill: https://pub.dev/packages/flutter_quill
              Text('Notes', style: context.formLabel),
              const SizedBox(height: 9),
              Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  border: Border.all(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  child: HtmlEditor(
                    controller: _formController.detailsController,
                    htmlToolbarOptions: const HtmlToolbarOptions(
                      toolbarType: ToolbarType.nativeGrid,
                      defaultToolbarButtons: [
                        FontButtons(
                          superscript: false,
                          subscript: false,
                          clearAll: false,
                        ),
                        ListButtons(listStyles: false),
                        ParagraphButtons(
                          alignLeft: false,
                          alignCenter: false,
                          alignRight: false,
                          alignJustify: false,
                          textDirection: false,
                          lineHeight: false,
                          caseConverter: false,
                        ),
                      ],
                    ),
                    htmlEditorOptions: HtmlEditorOptions(
                      hint: '',
                      initialText: _formController.initialNotes,
                      autoAdjustHeight: true,
                      darkMode: context.isDarkMode,
                    ),
                    otherOptions: const OtherOptions(
                      height: 300,
                      decoration: BoxDecoration(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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

      isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    // Clean URL field before validation
    _formController.urlController.text = BasicFormController.cleanUrl(
      _formController.urlController.text.trim(),
    );

    if (_formController.validateAndScrollToError()) {
      setState(() {
        isSubmitting = true;
      });

      final notes = await _formController.detailsController.getText();

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
        details: notes.trim().isEmpty ? '' : notes,
        courses: _formController.selectedCourses,
        materialGroup: widget.materialGroupId,
      );

      if (mounted) {
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
      }
    } else {
      showSnackBar(
        context,
        'Fix the highlighted fields, then try again.',
        isError: true,
      );
    }
  }
}
