// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/calendar_item_data_source.dart';
import 'package:heliumapp/presentation/views/calendar/todos_table_controller.dart';
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/empty_card.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.widgets');

class TodosTable extends StatefulWidget {
  final CalendarItemDataSource dataSource;
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
  State<TodosTable> createState() => TodosTableState();
}

// TODO: consider migrating to https://pub.dev/packages/syncfusion_flutter_datagrid, gives us ability for adjustable column widths easily

class TodosTableState extends State<TodosTable> {
  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50, 100, -1];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _expandDataWindowForAllCourses();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      // Navigate to today only on first initialization
      if (!widget.controller.hasInitializedNavigation) {
        widget.controller.goToToday(widget.dataSource.filteredHomeworks);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = widget.dataSource;
    final controller = widget.controller;

    // Show loading until TodosTable's data window expansion is complete
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort homework based on selected column
    final sortedHomeworks = _sortHomeworks(dataSource.filteredHomeworks);

    // Calculate pagination
    final totalItems = sortedHomeworks.length;
    final isShowingAll = controller.itemsPerPage == -1;
    final effectiveItemsPerPage = isShowingAll
        ? totalItems
        : controller.itemsPerPage;
    final totalPages = isShowingAll
        ? 1
        : (totalItems / effectiveItemsPerPage).ceil();

    // Reset to page 1 if current page is beyond valid range (e.g., after filtering)
    var effectiveCurrentPage = controller.currentPage;
    if (effectiveCurrentPage > totalPages && totalPages > 0) {
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
    final paginatedHomeworks = sortedHomeworks.sublist(
      startIndex.clamp(0, totalItems),
      endIndex,
    );

    if (totalItems == 0) {
      // Distinguish between "no assignments at all" vs "filters hiding everything"
      final hasAssignments = dataSource.allHomeworks.isNotEmpty;
      return EmptyCard(
        icon: Icons.assignment_outlined,
        message: hasAssignments
            ? 'No assignments match the applied filters'
            : 'No assignments found',
        expanded: false,
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: context.colorScheme.surface),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: paginatedHomeworks.length,
                  itemBuilder: (context, index) {
                    return _buildTodoRow(paginatedHomeworks[index]);
                  },
                ),
              ),
              _buildTableFooter(
                startIndex: startIndex,
                endIndex: endIndex,
                totalItems: totalItems,
                isShowingAll: isShowingAll,
                totalPages: totalPages,
                currentPage: effectiveCurrentPage,
              ),
            ],
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
      final startDate = DateTime.parse(course.startDate);

      final endDate = DateTime.parse(
        course.endDate,
      ).add(const Duration(days: 1));

      if (from == null || startDate.isBefore(from)) {
        from = startDate;
      }
      if (to == null || endDate.isAfter(to)) {
        to = endDate;
      }
    }

    // TODO: within the data source, we should have a separate from/to window for homework only, since this page only renders homework; would load quicker; (separate so we know in calendar-based views, the from/to for non-homework items still needs to be expanded on date change)

    // Trigger data source to expand its window
    if (from != null && to != null) {
      _log.info('Date window for ${courses.length} courses: $from to $to');
      await dataSource.handleLoadMore(from, to);
    }
  }

  // Order to hide columns, based on screen size:
  // 1. Priority
  // 2. Resources
  // 3. Category
  // 4. Grade
  // 5. Actions
  // 6. Class

  bool _shouldShowPriorityColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1150;
  }

  bool _shouldShowResourcesColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1000;
  }

  bool _shouldShowCategoryColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  bool _shouldShowGradeColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 850;
  }

  bool _isCompactActionsMode(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  bool _shouldShowClassColumn(BuildContext context) {
    return MediaQuery.of(context).size.width >= 625;
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: _buildSortableHeader('', 'completed', isCheckbox: true),
          ),
          Expanded(flex: 3, child: _buildSortableHeader('Title', 'title')),
          SizedBox(
            width: 155,
            child: _buildSortableHeader('Due Date', 'dueDate'),
          ),
          if (_shouldShowClassColumn(context))
            Expanded(flex: 2, child: _buildSortableHeader('Class', 'class')),
          if (_shouldShowCategoryColumn(context))
            Expanded(
              flex: 2,
              child: _buildSortableHeader('Category', 'category'),
            ),
          if (_shouldShowResourcesColumn(context))
            Expanded(flex: 1, child: _buildSortableHeader('', 'resources')),
          if (_shouldShowPriorityColumn(context))
            Expanded(
              flex: 2,
              child: _buildSortableHeader('Priority', 'priority'),
            ),
          if (_shouldShowGradeColumn(context))
            SizedBox(width: 95, child: _buildSortableHeader('Grade', 'grade')),
          SizedBox(
            width: _isCompactActionsMode(context) ? 48 : 170,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter({
    required int startIndex,
    required int endIndex,
    required int totalItems,
    required bool isShowingAll,
    required int totalPages,
    required int currentPage,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 8,
        top: Responsive.isMobile(context) ? 4 : 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItemsCountText(startIndex, endIndex, totalItems),
              if (!isShowingAll && totalPages > 1)
                _buildPagination(totalPages, currentPage),
            ],
          ),
          const SizedBox(height: 4),
          _buildItemsPerPageDropdown(),
        ],
      ),
    );
  }

  Widget _buildItemsPerPageDropdown() {
    final controller = widget.controller;
    final dropDownItems = _itemsPerPageOptions.map((value) {
      return DropDownItem<String>(
        id: value,
        value: value == -1 ? 'All' : value.toString(),
      );
    }).toList();

    final currentItem = dropDownItems.firstWhere(
      (item) => item.id == controller.itemsPerPage,
    );

    return Row(
      children: [
        Text(
          'Show',
          style: context.calendarData.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: DropDown<String>(
            initialValue: currentItem,
            items: dropDownItems,
            onChanged: (newItem) {
              if (newItem != null) {
                controller.itemsPerPage = newItem.id;
                controller.currentPage = 1;
              }
            },
            style: context.calendarData.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCountText(int startIndex, int endIndex, int totalItems) {
    return Text(
      '${!Responsive.isMobile(context) ? 'Showing ' : ''}${startIndex + 1} to $endIndex of $totalItems',
      style: context.calendarData.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildPagination(int totalPages, int currentPage) {
    final controller = widget.controller;
    final isMobile = Responsive.isMobile(context);

    return Row(
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () {
                  controller.currentPage--;
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        // On mobile, show page indicator text; on desktop, show page numbers
        if (isMobile)
          Text(
            'Page $currentPage of $totalPages',
            style: context.calendarData.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          )
        else
          ..._buildPageNumbers(totalPages, currentPage),
        const SizedBox(width: 8),
        IconButton(
          onPressed: currentPage < totalPages
              ? () {
                  controller.currentPage++;
                }
              : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(int totalPages, int currentPage) {
    final List<Widget> pages = [];
    // Only used on non-mobile screens
    const int maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(_buildPageButton(i, currentPage));
      }
    } else {
      pages.add(_buildPageButton(1, currentPage));

      final int start = (currentPage - 1).clamp(2, totalPages - 3);
      final int end = (currentPage + 1).clamp(4, totalPages - 1);

      if (start > 2) {
        pages.add(_buildEllipsis());
      }

      for (int i = start; i <= end; i++) {
        pages.add(_buildPageButton(i, currentPage));
      }

      if (end < totalPages - 1) {
        pages.add(_buildEllipsis());
      }

      pages.add(_buildPageButton(totalPages, currentPage));
    }

    return pages;
  }

  Widget _buildPageButton(int pageNumber, int currentPage) {
    final controller = widget.controller;
    final isActive = currentPage == pageNumber;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OutlinedButton(
        onPressed: isActive
            ? null
            : () {
                controller.currentPage = pageNumber;
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? context.colorScheme.primary : null,
          disabledBackgroundColor: isActive
              ? context.colorScheme.primary
              : null,
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          pageNumber.toString(),
          style: context.calendarData.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w300,
            color: isActive ? context.colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '...',
          style: context.calendarData.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSortableHeader(
    String label,
    String column, {
    bool isCheckbox = false,
  }) {
    final controller = widget.controller;
    final isActive = controller.sortColumn == column;

    return GestureDetector(
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
        mainAxisAlignment: isCheckbox
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (isCheckbox)
            Icon(
              Icons.check_box_outline_blank,
              size: 16,
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            )
          else
            Text(
              label,
              style: context.calendarHeader.copyWith(
                color: context.colorScheme.onSurface,
              ),
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
        case 'completed':
          final isCompletedA = dataSource.isHomeworkCompleted(a);
          final isCompletedB = dataSource.isHomeworkCompleted(b);
          comparison = isCompletedA == isCompletedB
              ? 0
              : isCompletedA
              ? 1
              : -1;
          break;
        case 'title':
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 'dueDate':
          comparison = a.start.compareTo(b.start);
          break;
        case 'class':
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
        case 'category':
          final catA = categoriesMap.containsKey(a.category.id)
              ? categoriesMap[a.category.id]!.title
              : '';
          final catB = categoriesMap.containsKey(b.category.id)
              ? categoriesMap[b.category.id]!.title
              : '';
          comparison = catA.toLowerCase().compareTo(catB.toLowerCase());
          break;
        case 'resources':
          comparison = a.materials.length.compareTo(b.materials.length);
          break;
        case 'priority':
          comparison = (a.priority).compareTo(b.priority);
          break;
        case 'grade':
          final gradeA = a.currentGrade ?? '';
          final gradeB = b.currentGrade ?? '';
          comparison = gradeA.compareTo(gradeB);
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
    final isCompact = _isCompactActionsMode(context);
    final actionButtons = _buildActionButtons(homework, course, isCompact);

    return Material(
      child: Ink(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: InkWell(
          onTap: Responsive.isMobile(context)
              ? () => widget.onTap(homework)
              : () {},
          mouseCursor: Responsive.isMobile(context)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
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
                if (_shouldShowClassColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildClassColumn(course),
                ],
                if (_shouldShowCategoryColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildCategoryColumn(category),
                ],
                if (_shouldShowResourcesColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildResourcesColumn(homework, userSettings),
                ],
                if (_shouldShowPriorityColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildPriorityColumn(homework),
                ],
                if (_shouldShowGradeColumn(context)) ...[
                  const SizedBox(width: 4),
                  _buildGradeColumn(homework, userSettings),
                ],
                const SizedBox(width: 4),
                _buildActionsColumn(actionButtons, isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxColumn(
    bool isCompleted,
    HomeworkModel homework,
    CategoryModel category,
    dynamic course,
    UserSettingsModel userSettings,
  ) {
    return SizedBox(
      width: 40,
      child: Checkbox(
        value: isCompleted,
        onChanged: (value) {
          Feedback.forTap(context);
          widget.onToggleCompleted(homework, value!);
        },
        activeColor: userSettings.colorByCategory
            ? category.color
            : course.color,
        side: BorderSide(
          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
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
            child: Text(
              homework.title,
              style: context.calendarData.copyWith(
                color: context.colorScheme.onSurface,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return SizedBox(
      width: 155,
      child: Text(
        HeliumDateTime.formatDateAndTimeForTodosDisplay(
          HeliumDateTime.parse(homework.start, userSettings.timeZone),
        ),
        style: context.calendarData.copyWith(
          color: context.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // TODO: the CourseTitleLabel should shrink-to-fix its text rather than expanding to fill the entire row
  Widget _buildClassColumn(dynamic course) {
    return Expanded(
      flex: 2,
      child: CourseTitleLabel(title: course.title, color: course.color),
    );
  }

  // TODO: the CategoryTitleLabel should shrink-to-fix its text rather than expanding to fill the entire row
  Widget _buildCategoryColumn(CategoryModel category) {
    return Expanded(
      flex: 2,
      child: CategoryTitleLabel(title: category.title, color: category.color),
    );
  }

  // TODO: implement where if the user clicks on this, a menu appears with the full resource names
  Widget _buildResourcesColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    return Expanded(
      flex: 1,
      child: homework.materials.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 14,
                  color: userSettings.materialColor,
                ),
                const SizedBox(width: 4),
                Text(
                  homework.materials.length.toString(),
                  style: context.calendarData.copyWith(
                    color: userSettings.materialColor,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 11,
                      tablet: 12,
                      desktop: 13,
                    ),
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
    return SizedBox(
      width: 95,
      child: homework.currentGrade != null && homework.currentGrade!.isNotEmpty
          ? GradeLabel(
              grade: Format.gradeForDisplay(homework.currentGrade),
              userSettings: userSettings,
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
            icon: Icons.link_outlined,
            color: context.colorScheme.onSurface,
          ),
        );
      }

      if (PlannerHelper.shouldShowEditButtonForCalendarItem(
        context,
        homework,
      )) {
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
