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
import 'package:heliumapp/presentation/widgets/category_title_label.dart';
import 'package:heliumapp/presentation/widgets/course_title_label.dart';
import 'package:heliumapp/presentation/widgets/drop_down.dart';
import 'package:heliumapp/presentation/widgets/grade_label.dart';
import 'package:heliumapp/presentation/widgets/helium_icon_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

// FIXME: once priority-based hiding of columns based on screen width is done, evaluate what else needs to be for view to be fully mobile-friendly
// FIXME: listen for CalendarDataSourceAction, show loading animation until that event fires completion

class TodosView extends StatefulWidget {
  final CalendarItemDataSource dataSource;
  final Function(HomeworkModel) onTap;
  final Function(HomeworkModel, bool) onToggleCompleted;
  final Function(HomeworkModel)? onDelete;

  const TodosView({
    super.key,
    required this.dataSource,
    required this.onTap,
    required this.onToggleCompleted,
    this.onDelete,
  });

  @override
  State<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends State<TodosView> {
  String _sortColumn = 'dueDate';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  bool _isExpandingDataWindow = false;

  final List<int> _itemsPerPageOptions = [
    5,
    10,
    25,
    50,
    100,
    -1,
  ]; // -1 represents "All"

  @override
  void initState() {
    super.initState();
    _expandDataWindowForAllCourses();

    // FIXME: when page loads, start by ordering by due date (which maps to homework.start), earliest to latest. once all items and pages are loaded, "jump" to the page that has shows events for "today" (or the nearest next calendar item)
  }

  /// Expands the data source window to load ALL homework for visible courses
  Future<void> _expandDataWindowForAllCourses() async {
    if (_isExpandingDataWindow) return;
    _isExpandingDataWindow = true;

    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];

    if (courses.isEmpty) {
      _isExpandingDataWindow = false;
      return;
    }

    // Find earliest start date and latest end date across all courses
    DateTime? earliestStart;
    DateTime? latestEnd;

    for (final course in courses) {
      final startDate = DateTime.parse(course.startDate);
      final endDate = DateTime.parse(course.endDate);

      if (earliestStart == null || startDate.isBefore(earliestStart)) {
        earliestStart = startDate;
      }
      if (latestEnd == null || endDate.isAfter(latestEnd)) {
        latestEnd = endDate;
      }
    }

    // Expand data window to cover all courses
    if (earliestStart != null && latestEnd != null) {
      await dataSource.handleLoadMore(earliestStart, latestEnd);
    }

    _isExpandingDataWindow = false;
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = widget.dataSource;

    // Sort homework based on selected column
    final sortedHomeworks = _sortHomeworks(dataSource.filteredHomeworks);

    // Calculate pagination
    final totalItems = sortedHomeworks.length;
    final isShowingAll = _itemsPerPage == -1;
    final effectiveItemsPerPage = isShowingAll ? totalItems : _itemsPerPage;
    final totalPages = isShowingAll
        ? 1
        : (totalItems / effectiveItemsPerPage).ceil();
    final startIndex = isShowingAll
        ? 0
        : (_currentPage - 1) * effectiveItemsPerPage;
    final endIndex = isShowingAll
        ? totalItems
        : (startIndex + effectiveItemsPerPage).clamp(0, totalItems);
    final paginatedHomeworks = sortedHomeworks.sublist(
      startIndex.clamp(0, totalItems),
      endIndex,
    );

    if (totalItems == 0) {
      final onSurface = context.colorScheme.onSurface;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No assignments found',
              style: context.bTextStyle.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Change filters or click "+" to add one',
              style: context.eTextStyle.copyWith(
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: _buildSortableHeader(
              '',
              'completed',
              isCheckbox: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildSortableHeader('Title', 'title'),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Due Date', 'dueDate'),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Class', 'class'),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Category', 'category'),
          ),
          Expanded(
            flex: 1,
            child: _buildSortableHeader('Materials', 'materials'),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader('Priority', 'priority'),
          ),
          SizedBox(
            width: 95,
            child: _buildSortableHeader('Grade', 'grade'),
          ),
          const SizedBox(
            width: 170,
            child: SizedBox.shrink(), // Actions column - no header label
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Top row: Count and pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItemsCountText(startIndex, endIndex, totalItems),
              if (!isShowingAll && totalPages > 1)
                _buildPagination(totalPages),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: Items per page dropdown
          _buildItemsPerPageDropdown(),
        ],
      ),
    );
  }

  Widget _buildItemsPerPageDropdown() {
    final dropDownItems = _itemsPerPageOptions.map((value) {
      return DropDownItem<String>(
        id: value,
        value: value == -1 ? 'All' : value.toString(),
      );
    }).toList();

    final currentItem = dropDownItems.firstWhere(
      (item) => item.id == _itemsPerPage,
    );

    return Row(
      children: [
        Text(
          'Show',
          style: context.eTextStyle.copyWith(
            color: context.colorScheme.onSurface.withValues(
              alpha: 0.7,
            ),
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
                setState(() {
                  _itemsPerPage = newItem.id;
                  _currentPage = 1; // Reset to first page
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCountText(int startIndex, int endIndex, int totalItems) {
    return Text(
      'Showing ${startIndex + 1} to $endIndex of $totalItems',
      style: context.eTextStyle.copyWith(
        color: context.colorScheme.onSurface.withValues(
          alpha: 0.7,
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      children: [
        // Previous button
        IconButton(
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        // Page numbers
        ..._buildPageNumbers(totalPages),
        const SizedBox(width: 8),
        // Next button
        IconButton(
          onPressed: _currentPage < totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
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

  List<Widget> _buildPageNumbers(int totalPages) {
    final List<Widget> pages = [];
    const int maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is 5 or fewer
      for (int i = 1; i <= totalPages; i++) {
        pages.add(_buildPageButton(i));
      }
    } else {
      // Show first page
      pages.add(_buildPageButton(1));

      // Calculate range around current page
      final int start = (_currentPage - 1).clamp(2, totalPages - 3);
      final int end = (_currentPage + 1).clamp(4, totalPages - 1);

      // Add ellipsis before if needed
      if (start > 2) {
        pages.add(_buildEllipsis());
      }

      // Add pages around current page
      for (int i = start; i <= end; i++) {
        pages.add(_buildPageButton(i));
      }

      // Add ellipsis after if needed
      if (end < totalPages - 1) {
        pages.add(_buildEllipsis());
      }

      // Show last page
      pages.add(_buildPageButton(totalPages));
    }

    return pages;
  }

  Widget _buildPageButton(int pageNumber) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          setState(() {
            _currentPage = pageNumber;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _currentPage == pageNumber
                ? context.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _currentPage == pageNumber
                  ? context.colorScheme.primary
                  : context.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            pageNumber.toString(),
            style: context.eTextStyle.copyWith(
              color: _currentPage == pageNumber
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
              fontWeight: _currentPage == pageNumber
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
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
          style: context.eTextStyle.copyWith(
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
    final isActive = _sortColumn == column;

    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        setState(() {
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = true;
          }
        });
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
              style: context.bTextStyle.copyWith(
                color: context.colorScheme.onSurface,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: context.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  List<HomeworkModel> _sortHomeworks(List<HomeworkModel> homeworks) {
    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];
    final categoriesMap = dataSource.categoriesMap ?? {};
    final sorted = List<HomeworkModel>.from(homeworks);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (_sortColumn) {
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
        case 'materials':
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

      return _sortAscending ? comparison : -comparison;
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
    final actionButtons = _buildActionButtons(homework, course);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          widget.onTap(homework);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildCheckboxColumn(isCompleted, homework, category, course, userSettings),
              const SizedBox(width: 2),
              _buildTitleColumn(homework, isCompleted),
              const SizedBox(width: 2),
              _buildDueDateColumn(homework, userSettings),
              const SizedBox(width: 2),
              _buildClassColumn(course),
              const SizedBox(width: 2),
              _buildCategoryColumn(category),
              const SizedBox(width: 2),
              _buildMaterialsColumn(homework, userSettings),
              const SizedBox(width: 2),
              _buildPriorityColumn(homework),
              const SizedBox(width: 2),
              _buildGradeColumn(homework, userSettings),
              const SizedBox(width: 2),
              _buildActionsColumn(actionButtons),
            ],
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
              style: context.eTextStyle.copyWith(
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
    return Expanded(
      flex: 2,
      child: Text(
        HeliumDateTime.formatDateAndTimeForDisplay(
          HeliumDateTime.parse(homework.start, userSettings.timeZone),
        ),
        style: context.eTextStyle.copyWith(
          color: context.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // FIXME: if screen is not wide enough to view, hide this 4th
  Widget _buildClassColumn(dynamic course) {
    return Expanded(
      flex: 2,
      child: CourseTitleLabel(
        title: course.title,
        color: course.color,
      ),
    );
  }

  // FIXME: the container within the category label should shrink-to-fix the text within it (but using Flexible here messes with table row width, so find another solution
  // FIXME: if screen is not wide enough to view, hide this 2nd
  Widget _buildCategoryColumn(CategoryModel category) {
    return Expanded(
      flex: 2,
      child: CategoryTitleLabel(
        title: category.title,
        color: category.color,
      ),
    );
  }

  // FIXME: if more than 150 pixels available, render these as MaterialLabelTitle, and allow to wrap within the column; otherwise continue to rollup number of materials in to an icon count (like it is currently done now)
  Widget _buildMaterialsColumn(
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
                  style: context.eTextStyle.copyWith(
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

  // FIXME: if screen is not wide enough to view, hide this 1st
  Widget _buildPriorityColumn(HomeworkModel homework) {
    return Expanded(
      flex: 2,
      child: _buildPriorityIndicator(homework.priority),
    );
  }

  // FIXME: if screen is not wide enough to view, hide this 3rd
  Widget _buildGradeColumn(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    return SizedBox(
      width: 95,
      child:
          homework.currentGrade != null && homework.currentGrade!.isNotEmpty
              ? GradeLabel(
                  grade: Format.gradeForDisplay(homework.currentGrade),
                  userSettings: userSettings,
                )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildActionsColumn(List<Widget> actionButtons) {
    return SizedBox(
      width: 170,
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

  List<Widget> _buildActionButtons(HomeworkModel homework, dynamic course) {
    final buttons = <Widget>[];

    // Email button (if course has teacher email)
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

    // Website button (if course has website)
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

    // Edit button (if editable)
    if (PlannerHelper.shouldShowEditAndDeleteButtons(homework)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => widget.onTap(homework),
          icon: Icons.edit_outlined,
          color: context.colorScheme.onSurface,
        ),
      );
    }

    // Delete button (if deletable)
    if (PlannerHelper.shouldShowEditAndDeleteButtons(homework)) {
      buttons.add(
        HeliumIconButton(
          onPressed: widget.onDelete != null
              ? () => widget.onDelete!(homework)
              : () {},
          icon: Icons.delete_outline,
          color: context.colorScheme.onSurface,
        ),
      );
    }

    return buttons;
  }

  Widget _buildPriorityIndicator(int priority) {
    // Priority is 1-100, displayed as a filled progress bar
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
