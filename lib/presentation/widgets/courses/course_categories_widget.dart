// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/category/category_bloc.dart';
import 'package:heliumapp/presentation/bloc/category/category_event.dart'
    show FetchCategoriesEvent, DeleteCategoryEvent;
import 'package:heliumapp/presentation/bloc/category/category_state.dart';
import 'package:heliumapp/presentation/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/dialogs/category_dialog.dart';
import 'package:heliumapp/presentation/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart'
    show SnackBarHelper;
import 'package:heliumapp/presentation/views/core/multi_step_container.dart';
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/error_card.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/mobile_gesture_detector.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Course categories widget for the third step of course add/edit flow.
class CourseCategoriesWidget extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;

  CourseCategoriesWidget({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CategoryBloc(
            categoryRepository: CategoryRepositoryImpl(
              remoteDataSource: CategoryRemoteDataSourceImpl(
                dioClient: _dioClient,
              ),
            ),
          ),
        ),
      ],
      child: _CourseCategoriesContent(
        courseGroupId: courseGroupId,
        courseId: courseId,
        isEdit: isEdit,
        isNew: isNew,
        userSettings: userSettings,
      ),
    );
  }
}

class _CourseCategoriesContent extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;
  final bool isNew;
  final UserSettingsModel? userSettings;

  const _CourseCategoriesContent({
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
    required this.isNew,
    this.userSettings,
  });

  @override
  State<_CourseCategoriesContent> createState() =>
      _CourseCategoriesContentState();
}

class _CourseCategoriesContentState extends State<_CourseCategoriesContent> {
  // State
  bool isLoading = true;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      context.read<CategoryBloc>().add(
        FetchCategoriesEvent(
          origin: EventOrigin.screen,
          courseId: widget.courseId,
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoriesFetched) {
          setState(() {
            _categories = state.categories;
            Sort.byTitle(_categories);
            isLoading = false;
          });
        } else if (state is CategoryCreated) {
          SnackBarHelper.show(context, 'Category saved');
          setState(() {
            _categories.add(state.category);
            Sort.byTitle(_categories);
          });
        } else if (state is CategoryUpdated) {
          // No snackbar on updates

          setState(() {
            _categories[_categories.indexWhere(
                  (c) => c.id == state.category.id,
                )] =
                state.category;
            Sort.byTitle(_categories);
          });
        } else if (state is CategoryDeleted) {
          SnackBarHelper.show(context, 'Category deleted');
          setState(() {
            _categories.removeWhere((c) => c.id == state.id);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Categories', style: AppStyles.featureText(context)),
            HeliumIconButton(
              onPressed: () {
                showCategoryDialog(
                  parentContext: context,
                  courseGroupId: widget.courseGroupId,
                  courseId: widget.courseId,
                  isEdit: false,
                );
              },
              icon: Icons.add,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Center(child: LoadingIndicator(expanded: false));
              }

              if (state is CategoriesError && state.origin == EventOrigin.screen) {
                return ErrorCard(
                  message: state.message!,
                  onReload: () {
                    context.read<CategoryBloc>().add(
                      FetchCategoriesEvent(
                        origin: EventOrigin.screen,
                        courseId: widget.courseId,
                      ),
                    );
                  },
                );
              }

              if (_categories.isEmpty) {
                return const EmptyCard(
                  icon: Icons.category_outlined,
                  message: 'Click "+" to add a category',
                );
              }

              return _buildCategoriesList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return MobileGestureDetector(
      onTap: () => _onEdit(category),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryTitleLabel(
                      title: category.title,
                      color: category.color,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SelectableText(
                          'Weight: ${GradeHelper.percentForDisplay(category.weight.toString(), true)}',
                          style: AppStyles.standardBodyTextLight(context)
                              .copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                        if (category.numHomework != null) ...[
                          const SizedBox(width: 16),
                          SelectableText(
                            'Assignments: ${category.numHomework}',
                            style: AppStyles.standardBodyTextLight(context)
                                .copyWith(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (PlannerHelper.shouldShowEditButton(context)) ...[
                HeliumIconButton(
                  onPressed: () => _onEdit(category),
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(width: 8),
              ],
              HeliumIconButton(
                onPressed: () {
                  showConfirmDeleteDialog(
                    parentContext: context,
                    item: category,
                    additionalWarning:
                        'Any assignments associated with this category will be moved to "Uncategorized".',
                    onDelete: (c) {
                      context.read<CategoryBloc>().add(
                        DeleteCategoryEvent(
                          origin: EventOrigin.screen,
                          courseGroupId: widget.courseGroupId,
                          courseId: widget.courseId,
                          categoryId: c.id,
                          isLastCategory: _categories.length == 1,
                        ),
                      );
                    },
                  );
                },
                icon: Icons.delete_outline,
                color: context.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(CategoryModel category) {
    showCategoryDialog(
      parentContext: context,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      isEdit: true,
      category: category,
    );
  }
}
