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
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/resources/controllers/resource_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/select_dialog.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/features/resources/constants/resource_constants.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetails extends StatefulWidget {
  final int resourceGroupId;
  final int? resourceId;
  final bool isEdit;
  final VoidCallback? onSubmitRequested;

  const ResourceDetails({
    super.key,
    required this.resourceGroupId,
    this.resourceId,
    required this.isEdit,
    this.onSubmitRequested,
  });

  @override
  State<ResourceDetails> createState() => ResourceDetailsState();
}

class ResourceDetailsState extends State<ResourceDetails> {
  final ResourceFormController _formController = ResourceFormController();

  // State
  List<CourseModel> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _formController.urlFocusNode.addListener(_onUrlFocusChange);

    context.read<ResourceBloc>().add(
      FetchResourceScreenDataEvent(
        origin: EventOrigin.subScreen,
        resourceGroupId: widget.resourceGroupId,
        resourceId: widget.resourceId,
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
    return BlocListener<ResourceBloc, ResourceState>(
      listener: (context, state) {
        if (state is ResourceScreenDataFetched) {
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
                    onFieldSubmitted: (value) => (widget.onSubmitRequested ?? onSubmit).call(),
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
                    initialValue: ResourceConstants.statusItems.firstWhere(
                      (mc) => mc.id == _formController.selectedStatus,
                    ),
                    items: ResourceConstants.statusItems,
                    onChanged: (value) {
                      setState(() {
                        _formController.selectedStatus = value!.id;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropDown(
                    label: 'Condition',
                    initialValue: ResourceConstants.conditionItems.firstWhere(
                      (mc) => mc.id == _formController.selectedCondition,
                    ),
                    items: ResourceConstants.conditionItems,
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

  void _populateInitialStateData(ResourceScreenDataFetched state) {
    setState(() {
      _courses = state.courses;
      Sort.byTitle(_courses);

      if (widget.isEdit) {
        _formController.titleController.text = state.resource!.title;
        _formController.urlController.text = state.resource!.website;
        _formController.priceController.text = state.resource!.price ?? '';
        _formController.initialNotes = state.resource!.details ?? '';

        _formController.selectedStatus = state.resource!.status;
        _formController.selectedCondition = state.resource!.condition;
        _formController.selectedCourses = List<int>.from(
          state.resource!.courses,
        );
      }

      _isLoading = false;
    });
  }

  Future<void> onSubmit() async {
    if (_formController.validateAndScrollToError()) {
      final request = ResourceRequestModel(
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
        resourceGroup: widget.resourceGroupId,
      );

      if (!mounted) return;
      if (widget.isEdit && widget.resourceId != null) {
        context.read<ResourceBloc>().add(
          UpdateResourceEvent(
            origin: EventOrigin.subScreen,
            resourceGroupId: widget.resourceGroupId,
            resourceId: widget.resourceId!,
            request: request,
          ),
        );
      } else {
        context.read<ResourceBloc>().add(
          CreateResourceEvent(
            origin: EventOrigin.subScreen,
            resourceGroupId: widget.resourceGroupId,
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
