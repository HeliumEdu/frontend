// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/presentation/bloc/category/category_bloc.dart';
import 'package:heliumapp/presentation/bloc/category/category_event.dart';
import 'package:heliumapp/presentation/bloc/category/category_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/dialogs/color_picker_dialog.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';
import 'package:heliumapp/presentation/forms/courses/category_form_controller.dart';
import 'package:heliumapp/presentation/widgets/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class _CategoryProvidedWidget extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final CategoryModel? category;

  const _CategoryProvidedWidget({
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    this.category,
  });

  @override
  State<_CategoryProvidedWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends BaseDialogState<_CategoryProvidedWidget> {
  final CategoryFormController _formController = CategoryFormController();

  @override
  String get dialogTitle => 'Category';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _formController.titleController.text = widget.category!.title;
      if (widget.category!.weight == 0) {
        _formController.weightController.text = '';
      } else {
        _formController.weightController.text = widget.category!.weight
            .toStringAsFixed(0);
      }
      _formController.selectedColor = widget.category!.color;
    } else {
      _formController.titleController.clear();
      _formController.weightController.clear();
      _formController.selectedColor = HeliumColors.getRandomColor();
    }
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoriesError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is CategoryCreated || state is CategoryUpdated) {
            Navigator.pop(context);
          }

          if (state is! CategoriesLoading) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelAndTextFormField(
          label: 'Title',
          autofocus: true,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
        ),
        const SizedBox(height: 14),
        LabelAndTextFormField(
          label: 'Weight (%)',
          controller: _formController.weightController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
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
                        Navigator.pop(context);
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
                      color: context.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void handleSubmit() {
    super.handleSubmit();

    if (_formController.formKey.currentState!.validate()) {
      String weightValue = '0';
      if (_formController.weightController.text.trim().isNotEmpty) {
        weightValue = _formController.weightController.text.trim();
      }

      final request = CategoryRequestModel(
        title: _formController.titleController.text.trim(),
        weight: weightValue,
        color: HeliumColors.colorToHex(_formController.selectedColor),
      );

      if (widget.isEdit) {
        context.read<CategoryBloc>().add(
          UpdateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: widget.courseGroupId,
            courseId: widget.courseId,
            categoryId: widget.category!.id,
            request: request,
          ),
        );
      } else {
        context.read<CategoryBloc>().add(
          CreateCategoryEvent(
            origin: EventOrigin.dialog,
            courseGroupId: widget.courseGroupId,
            courseId: widget.courseId,
            request: request,
          ),
        );
      }
    }
  }
}

Future<void> showCategoryDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required int courseGroupId,
  required int courseId,
  required bool isEdit,
  CategoryModel? category,
}) {
  final categoryBloc = parentContext.read<CategoryBloc>();

  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return BlocProvider<CategoryBloc>.value(
        value: categoryBloc,
        child: _CategoryProvidedWidget(
          courseGroupId: courseGroupId,
          courseId: courseId,
          isEdit: isEdit,
          category: category,
        ),
      );
    },
  );
}
