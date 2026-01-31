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
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/course_add_stepper.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class CourseAddCategoryScreen extends StatelessWidget {
  final DioClient _dioClient = DioClient();
  final int courseGroupId;
  final int courseId;
  final bool isEdit;

  CourseAddCategoryScreen({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    this.isEdit = false,
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
      child: CourseAddCategoryProvidedScreen(
        courseGroupId: courseGroupId,
        courseId: courseId,
        isEdit: isEdit,
      ),
    );
  }
}

class CourseAddCategoryProvidedScreen extends StatefulWidget {
  final int courseGroupId;
  final int courseId;
  final bool isEdit;

  const CourseAddCategoryProvidedScreen({
    super.key,
    required this.courseGroupId,
    required this.courseId,
    required this.isEdit,
  });

  @override
  State<CourseAddCategoryProvidedScreen> createState() =>
      _CourseAddCategoryScreenState();
}

class _CourseAddCategoryScreenState
    extends BasePageScreenState<CourseAddCategoryProvidedScreen> {
  @override
  String get screenTitle => widget.isEdit ? 'Edit Class' : 'Add Class';

  @override
  ScreenType get screenType => ScreenType.subPage;

  // State
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
    }
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoriesFetched) {
            setState(() {
              _categories = state.categories;
              Sort.byTitle(_categories);

              isLoading = false;
            });
          } else if (state is CategoryCreated) {
            showSnackBar(context, 'Category saved');

            setState(() {
              _categories.add(state.category);
              Sort.byTitle(_categories);
            });
          } else if (state is CategoryUpdated) {
            showSnackBar(context, 'Category saved');

            setState(() {
              _categories[_categories.indexWhere(
                    (c) => c.id == state.category.id,
                  )] =
                  state.category;
              Sort.byTitle(_categories);
            });
          } else if (state is CategoryDeleted) {
            showSnackBar(context, 'Category deleted');

            setState(() {
              _categories.removeWhere((c) => c.id == state.id);
            });
          }
        },
      ),
    ];
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    return CourseStepper(
      selectedIndex: 2,
      courseGroupId: widget.courseGroupId,
      courseId: widget.courseId,
      isEdit: widget.isEdit,
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories', style: context.sectionHeading),
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

          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return buildLoading();
              }

              if (state is CategoriesError &&
                  state.origin == EventOrigin.screen) {
                return buildReload(state.message!, () {
                  context.read<CategoryBloc>().add(
                    FetchCategoriesEvent(
                      origin: EventOrigin.screen,
                      courseId: widget.courseId,
                    ),
                  );
                });
              }

              if (_categories.isEmpty) {
                return buildEmptyPage(
                  icon: Icons.category_outlined,
                  message: 'Click "+" to add a category',
                );
              }

              return _buildCategoriesList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return Card(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Weight: ${Format.percentForDisplay(category.weight.toString(), true)}',
                        style: context.iTextStyle.copyWith(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TODO: show count of "homeworks" tied to category in list
            const SizedBox(width: 8),
            HeliumIconButton(
              onPressed: () {
                showCategoryDialog(
                  parentContext: context,
                  courseGroupId: widget.courseGroupId,
                  courseId: widget.courseId,
                  isEdit: true,
                  category: category,
                );
              },
              icon: Icons.edit_outlined,
            ),
            const SizedBox(width: 8),
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
    );
  }
}
