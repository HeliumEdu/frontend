// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/calendar_item_data_source.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

// FIXME: clean this view up further, including making mobile friendly
// FIXME: add HeliumIconButton for edit/delete
// FIXME: (if class has website), add HeliumIconButton for website
// FIXME: (if class teacher has email), add HeliumIconButton for email
// FIXME: better place for pagination, obscured by "+" hover button

class TodosView extends StatefulWidget {
  final CalendarItemDataSource dataSource;
  final Function(HomeworkModel) onTap;
  final Function(HomeworkModel, bool) onToggleCompleted;

  const TodosView({
    super.key,
    required this.dataSource,
    required this.onTap,
    required this.onToggleCompleted,
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

  final List<int> _itemsPerPageOptions = [5, 10, 25, 50, 100, -1]; // -1 represents "All"

  @override
  void initState() {
    super.initState();
    _expandDataWindowForAllCourses();
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
    final totalPages = isShowingAll ? 1 : (totalItems / effectiveItemsPerPage).ceil();
    final startIndex = isShowingAll ? 0 : (_currentPage - 1) * effectiveItemsPerPage;
    final endIndex = isShowingAll ? totalItems : (startIndex + effectiveItemsPerPage).clamp(0, totalItems);
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
          // Table header
          Container(
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
                  child: _buildSortableHeader('', 'completed', isCheckbox: true),
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
                Expanded(
                  flex: 1,
                  child: _buildSortableHeader('Grade', 'grade'),
                ),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: paginatedHomeworks.length,
              itemBuilder: (context, index) {
                return _buildTodoRow(paginatedHomeworks[index]);
              },
            ),
          ),
          // Pagination footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Items per page dropdown and count
                Row(
                  children: [
                    Text(
                      'Show',
                      style: context.eTextStyle.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<int>(
                        value: _itemsPerPage,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: _itemsPerPageOptions.map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              value == -1 ? 'All' : value.toString(),
                              style: context.eTextStyle.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _itemsPerPage = newValue;
                              _currentPage = 1; // Reset to first page
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Showing ${startIndex + 1} to $endIndex of $totalItems',
                      style: context.eTextStyle.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                // Right side: Page navigation (only show if not showing all)
                if (!isShowingAll && totalPages > 1)
                  Row(
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
                  ),
              ],
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Text(
          '...',
          style: context.eTextStyle.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSortableHeader(String label, String column, {bool isCheckbox = false}) {
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
        mainAxisAlignment: isCheckbox ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (isCheckbox)
            Icon(
              Icons.check_box_outline_blank,
              size: 16,
              color: isActive
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.6),
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

    final categoryName = categoriesMap.containsKey(homework.category.id)
        ? categoriesMap[homework.category.id]!.title
        : '';
    final categoryColor = categoriesMap.containsKey(homework.category.id)
        ? categoriesMap[homework.category.id]!.color
        : null;

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
              // Checkbox
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    Feedback.forTap(context);
                    widget.onToggleCompleted(homework, value!);
                  },
                  activeColor: course.color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              // Title with course color indicator
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: course.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ),
              // Due Date
              Expanded(
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
              ),
              // Class
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.title,
                    style: context.eTextStyle.copyWith(
                      color: course.color,
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 11,
                        tablet: 12,
                        desktop: 13,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Category
              Expanded(
                flex: 2,
                child: categoryName.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor!.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          categoryName,
                          style: context.eTextStyle.copyWith(
                            color: categoryColor,
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 11,
                              tablet: 12,
                              desktop: 13,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Materials
              Expanded(
                flex: 1,
                child: homework.materials.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attachment,
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
              ),
              // Priority
              Expanded(
                flex: 2,
                child: _buildPriorityIndicator(homework.priority),
              ),
              // Grade
              Expanded(
                flex: 1,
                child:
                    // TODO: refactor to GradeWidget and use anywhere we display grade
                    homework.currentGrade != null &&
                        homework.currentGrade!.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: userSettings.gradeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          Format.gradeForDisplay(homework.currentGrade, true),
                          style: context.eTextStyle.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 11,
                              tablet: 12,
                              desktop: 13,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    // Priority is 1-100, displayed in increments of 10 (10 levels)
    final clampedPriority = priority.clamp(1, 100);
    final priorityLevel = ((clampedPriority - 1) / 10).floor();
    final priorityColor = HeliumColors.getColorForPriority(clampedPriority.toDouble());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        10,
        (index) => Container(
          width: 12,
          height: 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index <= priorityLevel
                ? priorityColor
                : context.colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
