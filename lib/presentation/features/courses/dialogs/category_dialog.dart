import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/request/category_request_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/dialogs/conflict_resolving_dialog.dart';
import 'package:heliumapp/presentation/ui/components/color_selector.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/courses/controllers/category_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

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

class _CategoryWidgetState extends BaseDialogState<_CategoryProvidedWidget>
    with ConflictResolvingDialog<_CategoryProvidedWidget, CategoryModel> {
  final CategoryFormController _formController = CategoryFormController();

  @override
  String get dialogTitle => AppLocalizations.of(context).categoryDialogTitle;

  @override
  BasicFormController get formController => _formController;

  bool get _isUncategorized => widget.category?.isUncategorized ?? false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _populateScreenData(widget.category!);
      isLoading = true;
      context.read<CategoryBloc>().add(
        FetchCategoriesEvent(
          origin: EventOrigin.dialog,
          courseId: widget.courseId,
          forceRefresh: true,
          passive: true,
        ),
      );
    } else {
      _formController.markChanged(userInitiated: false);
      _formController.titleController.clear();
      _formController.weightController.clear();
      _formController.selectedColor = HeliumColors.getRandomColor();
    }
  }

  void _populateScreenData(CategoryModel category) {
    _formController.titleController.text = category.displayTitle;
    _formController.weightController.text = category.weight == 0
        ? ''
        : HeliumNumber.format(category.weight, trimZeros: true);
    _formController.selectedColor = category.color;
    trackVersion(category);
  }

  @override
  void applyLatest(CategoryModel latest) {
    _populateScreenData(latest);
    _formController.isChanged = false;
    _formController.isUserDirty = false;
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
              isLoading = false;
            });
          } else if (state is CategoriesFetched &&
              state.origin == EventOrigin.dialog &&
              isLoading) {
            final category = state.categories
                .firstWhereOrNull((c) => c.id == widget.category!.id);
            setState(() {
              if (category == null) errorMessage = AppLocalizations.of(context).categoryNotFoundMessage;
              _populateScreenData(category ?? widget.category!);
              isLoading = false;
            });
          } else if (state is CategoryConflict) {
            resolveDialogConflict(state.latest);
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
          label: AppLocalizations.of(context).categoryTitleLabel,
          autofocus: PlatformBehavior.autofocusesOnOpen || !widget.isEdit,
          controller: _formController.titleController,
          readOnly: _isUncategorized,
          validator: BasicFormController.validateRequiredField,
          onChanged: (_) => _formController.markChanged(),
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isUncategorized)
              SizedBox(
                width: 120,
                child: SpinnerField(
                  label: AppLocalizations.of(context).categoryWeightLabel,
                  controller: _formController.weightController,
                  minValue: 0,
                  maxValue: 100,
                  allowDecimal: true,
                  onChanged: (_) => _formController.markChanged(),
                ),
              )
            else if (_formController.weightController.text.isNotEmpty)
              SizedBox(
                width: 120,
                child: LabelAndTextFormField(
                  label: AppLocalizations.of(context).categoryWeightLabel,
                  controller: _formController.weightController,
                  readOnly: true,
                  suffixIcon: HeliumIconButton(
                    onPressed: _clearWeight,
                    icon: Icons.close,
                    label: AppLocalizations.of(context).categoryRemoveWeightLabel,
                    filled: false,
                  ),
                ),
              ),
            if (!_isUncategorized || _formController.weightController.text.isNotEmpty)
              SizedBox(width: Responsive.isNarrowMobile(context) ? 24 : 50),
            ColorSelector(
              label: AppLocalizations.of(context).commonColorLabel,
              selectedColor: _formController.selectedColor,
              onColorSelected: (color) {
                _formController.markChanged();
                setState(() {
                  _formController.selectedColor = color;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  void _clearWeight() {
    _formController.markChanged();
    setState(() => _formController.weightController.clear());
  }

  @override
  void handleSubmit() {
    if (!_formController.isChanged) {
      cancelAction();
      return;
    }
    super.handleSubmit();

    if (_formController.formKey.currentState!.validate()) {
      String weightValue = '0';
      if (_formController.weightController.text.trim().isNotEmpty) {
        weightValue = HeliumNumber.normalize(_formController.weightController.text);
      }

      final request = CategoryRequestModel(
        title: _isUncategorized ? CategoryModel.uncategorizedTitle : _formController.titleController.text.trim(),
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
            version: versionToSend,
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
