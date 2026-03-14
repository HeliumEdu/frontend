// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/features/planner/controllers/todos_table_controller.dart';
import 'package:heliumapp/presentation/ui/components/category_title_label.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_pager.dart';
import 'package:heliumapp/presentation/ui/components/non_touch_selectable_text.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.widgets');

class TodosTable extends StatefulWidget {
  final PlannerItemDataSource dataSource;
  final TodosTableController controller;
  final Function(HomeworkModel) onTap;
  final Function(HomeworkModel, bool) onToggleCompleted;
  final Function(BuildContext, HomeworkModel) onDelete;

  const TodosTable({
    super.key,
    required this.dataSource,
    required this.controller,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  State<TodosTable> createState() => _TodosTableState();
}

class _TodosTableState extends State<TodosTable> {
  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50, 100, -1];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _initializeData();
  }

  @override
  void didUpdateWidget(TodosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle the race condition where TodosTable initializes before the planner
    // screen receives course data from the API. courses == null means the BLoC
    // response hasn't arrived yet; retry until it does.
    if (!_isInitialized) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    // courses == null means the planner BLoC hasn't loaded them yet; wait for
    // didUpdateWidget to retry. courses == [] means loaded with no courses, which
    // is valid and should proceed (showing empty state).
    if (widget.dataSource.courses == null) return;
    await _expandDataWindowForAllCourses();
    if (!mounted) return;
    setState(() {
      _isInitialized = true;
    });
    // Navigate to today only on first initialization
    if (!widget.controller.hasInitializedNavigation) {
      widget.controller.goToToday(widget.dataSource.filteredHomeworks);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = widget.dataSource;
    final controller = widget.controller;

    // Sort homework based on selected column
    final sortedHomeworks = _isInitialized
        ? _sortHomeworks(dataSource.filteredHomeworks)
        : <HomeworkModel>[];

    // Calculate pagination
    final totalItems = sortedHomeworks.length;
    final isShowingAll = controller.itemsPerPage == -1;
    final effectiveItemsPerPage = isShowingAll
        ? totalItems
        : controller.itemsPerPage;
    final totalPages = isShowingAll
        ? 1
        : totalItems > 0
        ? (totalItems / effectiveItemsPerPage).ceil()
        : 1;

    // Reset to page 1 if current page is beyond valid range (e.g., after filtering).
    // Only do this after initialization; while loading, sortedHomeworks is intentionally
    // empty and would otherwise incorrectly force page 1 on view re-entry.
    var effectiveCurrentPage = controller.currentPage;
    if (_isInitialized && effectiveCurrentPage > totalPages && totalPages > 0) {
      effectiveCurrentPage = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.currentPage != 1) {
          controller.currentPage = 1;
        }
      });
    }

    final startIndex = isShowingAll
        ? 0
        : (effectiveCurrentPage - 1) * effectiveItemsPerPage;
    final endIndex = isShowingAll
        ? totalItems
        : (startIndex + effectiveItemsPerPage).clamp(0, totalItems);
    final paginatedHomeworks = totalItems > 0
        ? sortedHomeworks.sublist(startIndex.clamp(0, totalItems), endIndex)
        : <HomeworkModel>[];

    // Build the table body content
    Widget tableBody;
    if (!_isInitialized) {
      // Loading state - show empty area (loading overlay will cover it)
      tableBody = const SizedBox.shrink();
    } else if (totalItems == 0) {
      // Empty state - show message inside table frame
      final hasAssignments = dataSource.allHomeworks.isNotEmpty;
      tableBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppConstants.assignmentIcon,
              size: 48,
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasAssignments
                  ? 'No assignments match the applied filters'
                  : 'No assignments found',
              style: AppStyles.standardBodyTextLight(context).copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    } else {
      // Normal state - show list
      tableBody = ListView.builder(
        itemCount: paginatedHomeworks.length,
        itemBuilder: (context, index) {
          return _buildTodoRow(paginatedHomeworks[index]);
        },
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: context.colorScheme.surface),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(child: tableBody),
              HeliumPager(
                startIndex: startIndex,
                endIndex: endIndex,
                totalItems: totalItems,
                isShowingAll: isShowingAll,
                totalPages: totalPages,
                currentPage: effectiveCurrentPage,
                onPageChanged: (page) {
                  controller.currentPage = page;
                },
                itemsPerPage: controller.itemsPerPage,
                itemsPerPageOptions: _itemsPerPageOptions,
                onItemsPerPageChanged: (value) {
                  controller.itemsPerPage = value;
                  controller.currentPage = 1;
                  widget.dataSource.todosItemsPerPage = value;
                },
              ),
            ],
          ),
        ),
        // Loading overlay
        if (!_isInitialized || widget.dataSource.isRefreshing)
          Positioned.fill(
            child: Container(
              color: context.colorScheme.surface.withValues(alpha: 0.7),
              child: const Center(child: LoadingIndicator(expanded: false)),
            ),
          ),
      ],
    );
  }

  Future<void> _expandDataWindowForAllCourses() async {
    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];

    if (courses.isEmpty) {
      _log.fine('No courses, skipping data window expansion');
      return;
    }

    // Find earliest start date and latest end date across all courses
    DateTime? from;
    DateTime? to;

    for (final course in courses) {
      final startDate = course.startDate;

      final endDate = course.endDate.add(const Duration(days: 1));

      if (from == null || startDate.isBefore(from)) {
        from = startDate;
      }
      if (to == null || endDate.isAfter(to)) {
        to = endDate;
      }
    }

    // Trigger data source to expand its window
    if (from != null && to != null) {
      _log.info('Date window for ${courses.length} courses: $from to $to');
      await dataSource.handleLoadMore(from, to);
    }
  }

  // Order to hide columns, based on screen size:
  // 1. Priority
  // 2. Attachments
  // 3. Resources
  // 4. Category
  // 5. Grade
  // 6. Actions
  // 7. Class

  bool _shouldShowAttachmentsColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1000;
  }

  bool _shouldShowResourcesColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 950;
  }

  bool _shouldHideActionsColumn(BuildContext context) {
    return Responsive.isTouchDevice(context);
  }

  bool _isCompactActionsMode(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  bool _shouldShowSortColumn(TodosSortColumn column) {
    if (column.minViewportWidth == null) return true;
    return MediaQuery.of(context).size.width >= column.minViewportWidth! ||
        (column.showOnTouchDevice && Responsive.isTouchDevice(context));
  }

  Widget _buildTableHeader() {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
      ),
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: TodosSortColumn.completed.widthForLayout(
              isMobile: isMobile,
            )!,
            child: _buildSortableHeader(TodosSortColumn.completed),
          ),
          Expanded(flex: 3, child: _buildSortableHeader(TodosSortColumn.title)),
          SizedBox(
            width: TodosSortColumn.dueDate.widthForLayout(isMobile: isMobile)!,
            child: _buildSortableHeader(TodosSortColumn.dueDate),
          ),
          if (_shouldShowSortColumn(TodosSortColumn.className))
            Expanded(
              flex: 2,
              child: _buildSortableHeader(TodosSortColumn.className),
            ),
          if (_shouldShowSortColumn(TodosSortColumn.category))
            Expanded(
              flex: 2,
              child: _buildSortableHeader(TodosSortColumn.category),
            ),
          if (_shouldShowSortColumn(TodosSortColumn.priority))
            Expanded(
              flex: 2,
              child: _buildSortableHeader(TodosSortColumn.priority),
            ),
          if (_shouldShowSortColumn(TodosSortColumn.grade))
            SizedBox(
              width: TodosSortColumn.grade.widthForLayout(isMobile: isMobile)!,
              child: _buildSortableHeader(TodosSortColumn.grade),
            ),
          if (_shouldShowResourcesColumn(context))
            const SizedBox(width: 30, child: SizedBox.shrink()),
          if (_shouldShowAttachmentsColumn(context))
            const SizedBox(width: 30, child: SizedBox.shrink()),
          if (!_shouldHideActionsColumn(context))
            SizedBox(
              width: _isCompactActionsMode(context) ? 48 : 170,
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(TodosSortColumn column) {
    final controller = widget.controller;
    final isActive = controller.sortColumn == column;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          if (controller.sortColumn == column) {
            controller.sortAscending = !controller.sortAscending;
          } else {
            controller.sortColumn = column;
            controller.sortAscending = true;
          }
        },
        child: Row(
          mainAxisAlignment: column.isCheckbox
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (column.isCheckbox)
              Icon(
                Icons.check_box_outline_blank,
                size: 16,
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              )
            else
              Text(
                column.label,
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(color: context.colorScheme.onSurface),
              ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                controller.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: context.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<HomeworkModel> _sortHomeworks(List<HomeworkModel> homeworks) {
    final controller = widget.controller;
    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];
    final categoriesMap = dataSource.categoriesMap ?? {};
    final sorted = List<HomeworkModel>.from(homeworks);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (controller.sortColumn) {
        case TodosSortColumn.completed:
          final isCompletedA = dataSource.isHomeworkCompleted(a);
          final isCompletedB = dataSource.isHomeworkCompleted(b);
          comparison = isCompletedA == isCompletedB
              ? 0
              : isCompletedA
              ? 1
              : -1;
          break;
        case TodosSortColumn.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case TodosSortColumn.dueDate:
          comparison = a.start.compareTo(b.start);
          break;
        case TodosSortColumn.className:
          final courseA = courses.firstWhere(
            (c) => c.id == a.course.id,
            orElse: () => courses.first,
          );
          final courseB = courses.firstWhere(
            (c) => c.id == b.course.id,
            orElse: () => courses.first,
          );
          comparison = courseA.title.toLowerCase().compareTo(
            courseB.title.toLowerCase(),
          );
          break;
        case TodosSortColumn.category:
          final catA = categoriesMap.containsKey(a.category.id)
              ? categoriesMap[a.category.id]!.title
              : '';
          final catB = categoriesMap.containsKey(b.category.id)
              ? categoriesMap[b.category.id]!.title
              : '';
          comparison = catA.toLowerCase().compareTo(catB.toLowerCase());
          break;
        case TodosSortColumn.priority:
          comparison = (a.priority).compareTo(b.priority);
          break;
        case TodosSortColumn.grade:
          final isCompletedA = dataSource.isHomeworkCompleted(a);
          final isCompletedB = dataSource.isHomeworkCompleted(b);

          // Incomplete items come first
          if (!isCompletedA && isCompletedB) {
            comparison = -1;
          } else if (isCompletedA && !isCompletedB) {
            comparison = 1;
          } else if (!isCompletedA && !isCompletedB) {
            // Both incomplete, equal
            comparison = 0;
          } else {
            // Both complete, sort by grade
            final parsedGradeA = GradeHelper.parseGrade(a.currentGrade);
            final parsedGradeB = GradeHelper.parseGrade(b.currentGrade);

            // Items without grade come before items with grade
            if (parsedGradeA == null && parsedGradeB != null) {
              comparison = -1;
            } else if (parsedGradeA != null && parsedGradeB == null) {
              comparison = 1;
            } else if (parsedGradeA == null && parsedGradeB == null) {
              // Both have no grade, equal
              comparison = 0;
            } else {
              // Both have grades, compare numerically
              comparison = parsedGradeA!.compareTo(parsedGradeB!);
            }
          }
          break;
      }

      return controller.sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  Widget _buildTodoRow(HomeworkModel homework) {
    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];
    final categoriesMap = dataSource.categoriesMap ?? {};
    final userSettings = dataSource.userSettings;

    final course = courses.firstWhere(
      (c) => c.id == homework.course.id,
      orElse: () => courses.first,
    );

    final bool isCompleted = dataSource.isHomeworkCompleted(homework);

    final category = categoriesMap[homework.category.id]!;
    final hideActions = _shouldHideActionsColumn(context);
    final isCompact = _isCompactActionsMode(context);
    final actionButtons = hideActions
        ? <Widget>[]
        : _buildActionButtons(homework, course, isCompact);

    final rowContent = Material(
      child: Ink(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: InkWell(
          onTap: (hideActions || isCompact)
              ? () => widget.onTap(homework)
              : () {},
          mouseCursor: (hideActions || isCompact)
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          splashColor: Responsive.isMobile(context) ? null : Colors.transparent,
          highlightColor: Responsive.isMobile(context)
              ? null
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                _buildCheckboxColumn(
                  isCompleted,
                  homework,
                  category,
                  course,
                  userSettings,
                ),
                const SizedBox(width: 4),
                _buildTitleColumn(homework, isCompleted),
                const SizedBox(width: 4),
                _buildDueDateColumn(homework, userSettings),
                if (_shouldShowSortColumn(TodosSortColumn.className)) ...[
                  const SizedBox(width: 4),
                  _buildClassColumn(course),
                ],
                if (_shouldShowSortColumn(TodosSortColumn.category)) ...[
                  const SizedBox(width: 4),
                  _buildCategoryColumn(category),
                ],
                if (_shouldShowSortColumn(TodosSortColumn.priority)) ...[
                  const SizedBox(width: 4),
                  _buildPriorityColumn(homework),
                ],
                if (_shouldShowSortColumn(TodosSortColumn.grade)) ...[
                  const SizedBox(width: 4),
                  _buildGradeColumn(homework, userSettings),
                ],
                if (_shouldShowResourcesColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildResourcesColumn(homework, userSettings),
                ],
                if (_shouldShowAttachmentsColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildAttachmentsColumn(homework, userSettings),
                ],
                if (!hideActions) ...[
                  const SizedBox(width: 4),
                  _buildActionsColumn(actionButtons, isCompact),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (hideActions && PlannerHelper.shouldShowDeleteButton(homework)) {
      return Dismissible(
        key: Key('todo_${homework.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: context.colorScheme.error,
          child: Icon(Icons.delete_outline, color: context.colorScheme.onError),
        ),
        confirmDismiss: (direction) async {
          widget.onDelete(context, homework);
          return false;
        },
        child: rowContent,
      );
    }

    return rowContent;
  }

  Widget _buildCheckboxColumn(
    bool isCompleted,
    HomeworkModel homework,
    CategoryModel category,
    dynamic course,
    UserSettingsModel userSettings,
  ) {
    final isMobile = Responsive.isMobile(context);

    return SizedBox(
      width: TodosSortColumn.completed.widthForLayout(isMobile: isMobile)!,
      child: Checkbox(
        value: isCompleted,
        onChanged: (value) {
          widget.onToggleCompleted(homework, value!);
        },
        activeColor: userSettings.colorByCategory
            ? category.color
            : course.color,
        side: BorderSide(
          color: userSettings.colorByCategory ? category.color : course.color,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildTitleColumn(HomeworkModel homework, bool isCompleted) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          Expanded(
            child: NonTouchSelectableText(
              homework.title,
              style: AppStyles.smallSecondaryText(context).copyWith(
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: context.colorScheme.onSurface,
                decorationThickness: 2.0,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    final isMobile = Responsive.isMobile(context);

    return SizedBox(
      width: TodosSortColumn.dueDate.widthForLayout(isMobile: isMobile)!,
      child: NonTouchSelectableText(
        homework.allDay
            ? HeliumDateTime.formatDateForTodos(HeliumDateTime.toLocal(homework.start, userSettings.timeZone))
            : HeliumDateTime.formatDateAndTimeForTodos(
                HeliumDateTime.toLocal(homework.start, userSettings.timeZone),
              ),
        style: AppStyles.smallSecondaryText(context),
        maxLines: 1,
      ),
    );
  }

  Widget _buildClassColumn(dynamic course) {
    return Expanded(
      flex: 2,
      child: CourseTitleLabel(
        title: course.title,
        color: course.color,
        compact: true,
      ),
    );
  }

  Widget _buildCategoryColumn(CategoryModel category) {
    return Expanded(
      flex: 2,
      child: CategoryTitleLabel(
        title: category.title,
        color: category.color,
        compact: true,
      ),
    );
  }

  Widget _buildResourcesColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    return SizedBox(
      width: 30,
      child: homework.resources.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 14,
                  color: userSettings.resourceColor.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  homework.resources.length.toString(),
                  style: AppStyles.smallSecondaryTextLight(context).copyWith(
                    color: userSettings.resourceColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAttachmentsColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    return SizedBox(
      width: 30,
      child: homework.attachments.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attachment,
                  size: 14,
                  color: context.semanticColors.success.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  homework.attachments.length.toString(),
                  style: AppStyles.smallSecondaryTextLight(context).copyWith(
                    color: context.semanticColors.success.withValues(alpha: 0.9),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPriorityColumn(HomeworkModel homework) {
    return Expanded(flex: 2, child: _buildPriorityIndicator(homework.priority));
  }

  Widget _buildGradeColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    final isMobile = Responsive.isMobile(context);

    return SizedBox(
      width: TodosSortColumn.grade.widthForLayout(isMobile: isMobile)!,
      child: homework.completed
          ? GradeLabel(
              grade: GradeHelper.gradeForDisplay(homework.currentGrade),
              userSettings: userSettings,
              compact: true,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildActionsColumn(List<Widget> actionButtons, bool isCompact) {
    return SizedBox(
      width: isCompact ? 48 : 170,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < actionButtons.length; i++) ...[
            actionButtons[i],
            if (i < actionButtons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    HomeworkModel homework,
    dynamic course,
    bool isCompact,
  ) {
    final buttons = <Widget>[];

    if (!isCompact) {
      if (course?.teacherEmail?.isNotEmpty ?? false) {
        buttons.add(
          HeliumIconButton(
            onPressed: () {
              launchUrl(Uri.parse('mailto:${course!.teacherEmail}'));
            },
            tooltip: 'Email teacher',
            icon: Icons.email_outlined,
            color: context.colorScheme.onSurface,
          ),
        );
      }

      if (course?.website?.isNotEmpty ?? false) {
        buttons.add(
          HeliumIconButton(
            onPressed: () {
              launchUrl(
                Uri.parse(course!.website),
                mode: LaunchMode.externalApplication,
              );
            },
            tooltip: 'Launch class website',
            icon: Icons.link_outlined,
            color: context.colorScheme.onSurface,
          ),
        );
      }

      if (PlannerHelper.shouldShowEditButtonForPlannerItem(context, homework)) {
        buttons.add(
          HeliumIconButton(
            onPressed: () => widget.onTap(homework),
            icon: Icons.edit_outlined,
            color: context.colorScheme.onSurface,
          ),
        );
      }
    }

    if (PlannerHelper.shouldShowDeleteButton(homework)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => widget.onDelete(context, homework),
          icon: Icons.delete_outline,
          color: context.colorScheme.onSurface,
        ),
      );
    }

    return buttons;
  }

  Widget _buildPriorityIndicator(int priority) {
    final clampedPriority = priority.clamp(1, 100);
    final priorityPercent = clampedPriority / 100;
    final priorityColor = HeliumColors.getColorForPriority(
      clampedPriority.toDouble(),
    );

    return Container(
      width: 100,
      height: 8,
      decoration: BoxDecoration(
        color: context.colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: priorityPercent,
        child: Container(
          decoration: BoxDecoration(
            color: priorityColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
