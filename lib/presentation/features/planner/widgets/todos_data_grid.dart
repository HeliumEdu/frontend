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
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/ui/components/category_title_label.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/grade_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_pager.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('presentation.widgets');

/// Sort column definitions with responsive visibility breakpoints.
enum TodosSortColumn {
  completed(label: '', fixedWidth: 52, isCheckbox: true),
  title(label: 'Title', mobileWidth: 70, desktopWidth: 95),
  dueDate(label: 'Due Date', mobileWidth: 144, desktopWidth: 154),
  className(label: 'Class', minViewportWidth: 625, fixedWidth: 120),
  category(label: 'Category', minViewportWidth: 950, fixedWidth: 129),
  priority(label: 'Priority', minViewportWidth: 1150, fixedWidth: 116),
  grade(
    label: 'Grade',
    mobileWidth: 90,
    tabletWidth: 102,
    desktopWidth: 105,
    minViewportWidth: 850,
    showOnTouchDevice: true,
  ),
  resources(label: '', minViewportWidth: 1050, fixedWidth: 40),
  attachments(label: '', minViewportWidth: 1050, fixedWidth: 40);

  const TodosSortColumn({
    required this.label,
    this.fixedWidth,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.minViewportWidth,
    this.showOnTouchDevice = false,
    this.isCheckbox = false,
  });

  final String label;
  final double? fixedWidth;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? minViewportWidth;
  final bool showOnTouchDevice;
  final bool isCheckbox;

  double? widthForLayout({required bool isMobile, required bool isTablet}) {
    if (isMobile && mobileWidth != null) return mobileWidth;
    if (isTablet && tabletWidth != null) return tabletWidth;
    if (desktopWidth != null) return desktopWidth;
    return fixedWidth;
  }
}

class TodosDataGrid extends StatefulWidget {
  final PlannerItemDataSource dataSource;
  final Function(HomeworkModel) onTap;
  final Function(HomeworkModel, bool) onToggleCompleted;
  final Function(BuildContext, HomeworkModel) onDelete;

  const TodosDataGrid({
    super.key,
    required this.dataSource,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  State<TodosDataGrid> createState() => TodosDataGridState();
}

class TodosDataGridState extends State<TodosDataGrid> {
  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50, 100, -1];

  final DataGridController _gridController = DataGridController();

  late TodosDataSource _dataSource;
  bool _isInitialized = false;
  bool _hasInitializedNavigation = false;

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _itemsPerPage = widget.dataSource.todosItemsPerPage;
    widget.dataSource.changeNotifier.addListener(_onDataSourceChanged);
    _dataSource = _buildDataSource();
    _initializeData();
  }

  @override
  void didUpdateWidget(TodosDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized) {
      _initializeData();
    }
  }

  @override
  void dispose() {
    widget.dataSource.changeNotifier.removeListener(_onDataSourceChanged);
    _gridController.dispose();
    super.dispose();
  }

  void goToToday({bool isInitialLoad = false}) {
    final homeworks = widget.dataSource.filteredHomeworks;
    _log.info(
      "Jump to today's Todos page, calculating with ${homeworks.length} items and $_itemsPerPage items per page",
    );
    _hasInitializedNavigation = true;

    _dataSource.sortedColumns.clear();
    _dataSource.sortedColumns.add(
      const SortColumnDetails(
        name: 'dueDate',
        sortDirection: DataGridSortDirection.ascending,
      ),
    );

    final sorted = List<HomeworkModel>.from(homeworks);
    sorted.sort((a, b) => a.start.compareTo(b.start));

    if (sorted.isEmpty) {
      _currentPage = 1;
      _log.fine('No items, setting page to 1');
      _syncPagerAndRefresh(markInitialized: isInitialLoad);
      return;
    }

    final now = DateTime.now();
    final today = HeliumDateTime.dateOnly(now);

    int targetIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      final dueDateOnly = HeliumDateTime.dateOnly(sorted[i].start);
      if (dueDateOnly.isAtSameMomentAs(today) || dueDateOnly.isAfter(today)) {
        targetIndex = i;
        break;
      }
    }

    final effectiveItemsPerPage =
        _itemsPerPage == -1 ? sorted.length : _itemsPerPage;

    if (targetIndex == -1) {
      _currentPage = (sorted.length / effectiveItemsPerPage).ceil();
      _log.fine('No future items, showing last page: $_currentPage');
    } else {
      _currentPage = (targetIndex / effectiveItemsPerPage).floor() + 1;
      _log.fine(
        'Found item at index $targetIndex, navigating to page $_currentPage',
      );
    }

    _syncPagerAndRefresh(markInitialized: isInitialLoad);
  }

  @override
  Widget build(BuildContext context) {
    final homeworks = widget.dataSource.filteredHomeworks;

    final totalItems = homeworks.length;
    final isShowingAll = _itemsPerPage == -1;
    final effectiveItemsPerPage =
        isShowingAll ? totalItems : _itemsPerPage;
    final totalPages = isShowingAll
        ? 1
        : totalItems > 0
            ? (totalItems / effectiveItemsPerPage).ceil()
            : 1;

    var effectiveCurrentPage = _currentPage;
    if (_isInitialized && effectiveCurrentPage > totalPages && totalPages > 0) {
      effectiveCurrentPage = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPage != 1) {
          _currentPage = 1;
          _dataSource.updatePagination(
            currentPage: 1,
            itemsPerPage: _itemsPerPage,
          );
          setState(() {});
        }
      });
    }

    final startIndex =
        isShowingAll ? 0 : (effectiveCurrentPage - 1) * effectiveItemsPerPage;
    final endIndex = isShowingAll
        ? totalItems
        : (startIndex + effectiveItemsPerPage).clamp(0, totalItems);

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = _isCompactActionsMode();
    final showActions = !_shouldHideActionsColumn();

    final headerColor =
        context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final columns = _buildColumns(isMobile, isTablet, showActions, isCompact);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: context.colorScheme.surface),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SfDataGridTheme(
                      data: SfDataGridThemeData(
                        sortIconColor: context.colorScheme.primary,
                        headerColor: headerColor,
                      ),
                      child: SfDataGrid(
                        key: ValueKey(
                          'todos_grid_${columns.length}_$isCompact',
                        ),
                        source: _dataSource,
                        controller: _gridController,
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 40,
                        rowHeight: 50,
                        gridLinesVisibility: GridLinesVisibility.none,
                        headerGridLinesVisibility: GridLinesVisibility.none,
                        selectionMode: (isTouchDevice || isCompact)
                            ? SelectionMode.single
                            : SelectionMode.none,
                        horizontalScrollPhysics:
                            const NeverScrollableScrollPhysics(),
                        navigationMode: GridNavigationMode.row,
                        allowSorting: true,
                        allowMultiColumnSorting: !isTouchDevice,
                        showSortNumbers: !isTouchDevice,
                        sortingGestureType: SortingGestureType.tap,
                        allowSwiping: isTouchDevice,
                        swipeMaxOffset: 80,
                        onSwipeStart: (details) {
                          return details.swipeDirection ==
                              DataGridRowSwipeDirection.endToStart;
                        },
                        endSwipeActionsBuilder: (context, row, rowIndex) {
                          final homework = _dataSource.getHomeworkFromRow(row);
                          return GestureDetector(
                            onTap: () {
                              if (homework != null &&
                                  PlannerHelper.shouldShowDeleteButton(
                                    homework,
                                  )) {
                                widget.onDelete(context, homework);
                              }
                              _dataSource.notifyListeners();
                            },
                            child: Container(
                              color: context.colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: Icon(
                                Icons.delete_outline,
                                color: context.colorScheme.onError,
                              ),
                            ),
                          );
                        },
                        onSelectionChanged: (addedRows, removedRows) {
                          if (addedRows.isNotEmpty) {
                            final homework =
                                _dataSource.getHomeworkFromRow(addedRows.first);
                            if (homework != null) {
                              widget.onTap(homework);
                              _gridController.selectedRow = null;
                            }
                          }
                        },
                        columns: columns,
                      ),
                    ),
                    if (_isInitialized && totalItems == 0)
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildEmptyState(),
                      ),
                  ],
                ),
              ),
              HeliumPager(
                startIndex: startIndex,
                endIndex: endIndex,
                totalItems: totalItems,
                isShowingAll: isShowingAll,
                totalPages: totalPages,
                currentPage: effectiveCurrentPage,
                onPageChanged: (page) {
                  _currentPage = page;
                  _dataSource.updatePagination(
                    currentPage: page,
                    itemsPerPage: _itemsPerPage,
                  );
                  setState(() {});
                },
                itemsPerPage: _itemsPerPage,
                itemsPerPageOptions: _itemsPerPageOptions,
                onItemsPerPageChanged: (value) {
                  _itemsPerPage = value;
                  _currentPage = 1;
                  widget.dataSource.todosItemsPerPage = value;
                  _dataSource.updatePagination(
                    currentPage: 1,
                    itemsPerPage: value,
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        ),
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

  List<GridColumn> _buildColumns(
    bool isMobile,
    bool isTablet,
    bool showActions,
    bool isCompact,
  ) {
    final columns = <GridColumn>[];

    columns.add(GridColumn(
      columnName: 'completed',
      label: _buildHeaderCell(TodosSortColumn.completed),
      width: TodosSortColumn.completed.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
    ));

    columns.add(GridColumn(
      columnName: 'title',
      label: _buildHeaderCell(TodosSortColumn.title),
      minimumWidth: TodosSortColumn.title.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
    ));

    columns.add(GridColumn(
      columnName: 'dueDate',
      label: _buildHeaderCell(TodosSortColumn.dueDate),
      width: TodosSortColumn.dueDate.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
    ));

    if (_shouldShowColumn(TodosSortColumn.className)) {
      columns.add(GridColumn(
        columnName: 'className',
        label: _buildHeaderCell(TodosSortColumn.className),
        minimumWidth: TodosSortColumn.className.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    if (_shouldShowColumn(TodosSortColumn.category)) {
      columns.add(GridColumn(
        columnName: 'category',
        label: _buildHeaderCell(TodosSortColumn.category),
        minimumWidth: TodosSortColumn.category.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    if (_shouldShowColumn(TodosSortColumn.priority)) {
      columns.add(GridColumn(
        columnName: 'priority',
        label: _buildHeaderCell(TodosSortColumn.priority),
        width: TodosSortColumn.priority.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    if (_shouldShowColumn(TodosSortColumn.grade)) {
      columns.add(GridColumn(
        columnName: 'grade',
        label: _buildHeaderCell(TodosSortColumn.grade),
        width: TodosSortColumn.grade.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    if (_shouldShowColumn(TodosSortColumn.resources)) {
      columns.add(GridColumn(
        columnName: 'resources',
        label: const SizedBox.shrink(),
        width: TodosSortColumn.resources.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
        allowSorting: false,
      ));
    }

    if (_shouldShowColumn(TodosSortColumn.attachments)) {
      columns.add(GridColumn(
        columnName: 'attachments',
        label: const SizedBox.shrink(),
        width: TodosSortColumn.attachments.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
        allowSorting: false,
      ));
    }

    if (showActions) {
      columns.add(GridColumn(
        columnName: 'actions',
        label: const SizedBox.shrink(),
        width: isCompact ? 42 : 178,
        allowSorting: false,
      ));
    }

    return columns;
  }

  Widget _buildHeaderCell(TodosSortColumn column) {
    if (column.isCheckbox) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Center(
          child: Icon(
            Icons.check_box_outline_blank,
            size: 16,
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          column.label,
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasAssignments = widget.dataSource.allHomeworks.isNotEmpty;

    if (!hasAssignments) {
      return const EmptyCard(
        expanded: false,
        icon: Icons.assignment_outlined,
        title: "You haven't added any assignments yet",
        message: 'Click "+" to get started',
      );
    }

    return Center(
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
            'No assignments match the applied filters or search',
            style: AppStyles.standardBodyTextLight(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _onDataSourceChanged() {
    if (!mounted) return;

    _dataSource.update(
      homeworks: widget.dataSource.filteredHomeworks,
      context: context,
      dataSource: widget.dataSource,
      onTap: widget.onTap,
      onToggleCompleted: widget.onToggleCompleted,
      onDelete: widget.onDelete,
    );

    _dataSource.updatePagination(
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  TodosDataSource _buildDataSource() {
    return TodosDataSource(
      homeworks: [],
      context: context,
      dataSource: widget.dataSource,
      onTap: widget.onTap,
      onToggleCompleted: widget.onToggleCompleted,
      onDelete: widget.onDelete,
    );
  }

  Future<void> _initializeData() async {
    if (widget.dataSource.courses == null) return;
    await _expandDataWindowForAllCourses();
    if (!mounted) return;
    if (!_hasInitializedNavigation) {
      goToToday(isInitialLoad: true);
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _expandDataWindowForAllCourses() async {
    final dataSource = widget.dataSource;
    final courses = dataSource.courses ?? [];

    if (courses.isEmpty) {
      _log.fine('No courses, skipping data window expansion');
      return;
    }

    DateTime? from;
    DateTime? to;

    for (final course in courses) {
      final startDate = course.startDate;
      final endDate = course.endDate.add(const Duration(days: 1));

      if (from == null || startDate.isBefore(from)) from = startDate;
      if (to == null || endDate.isAfter(to)) to = endDate;
    }

    if (from != null && to != null) {
      _log.info('Date window for ${courses.length} courses: $from to $to');
      await dataSource.handleLoadMore(from, to);
    }
  }

  void _syncPagerAndRefresh({bool markInitialized = false}) {
    _dataSource.update(
      homeworks: widget.dataSource.filteredHomeworks,
      context: context,
      dataSource: widget.dataSource,
      onTap: widget.onTap,
      onToggleCompleted: widget.onToggleCompleted,
      onDelete: widget.onDelete,
    );
    _dataSource.updatePagination(
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
    );

    setState(() {
      if (markInitialized) {
        _isInitialized = true;
      }
    });
  }

  bool _shouldShowColumn(TodosSortColumn column) {
    if (column.minViewportWidth == null) return true;
    return MediaQuery.of(context).size.width >= column.minViewportWidth! ||
        (column.showOnTouchDevice && Responsive.isTouchDevice(context));
  }

  bool _shouldHideActionsColumn() => Responsive.isTouchDevice(context);

  bool _isCompactActionsMode() => Responsive.isCompact(context);
}

/// DataGridSource that wraps PlannerItemDataSource for SfDataGrid.
/// References the same underlying data - no duplication.
class TodosDataSource extends DataGridSource with SortableDataGridSource {
  List<HomeworkModel> _homeworks;
  BuildContext _context;
  PlannerItemDataSource _dataSource;
  Function(HomeworkModel) _onTap;
  Function(HomeworkModel, bool) _onToggleCompleted;
  Function(BuildContext, HomeworkModel) _onDelete;

  List<DataGridRow> _dataGridRows = [];
  Map<int, HomeworkModel> _homeworksById = {};

  int _currentPage = 1;
  int _itemsPerPage = 10;

  TodosDataSource({
    required List<HomeworkModel> homeworks,
    required BuildContext context,
    required PlannerItemDataSource dataSource,
    required Function(HomeworkModel) onTap,
    required Function(HomeworkModel, bool) onToggleCompleted,
    required Function(BuildContext, HomeworkModel) onDelete,
  })  : _homeworks = homeworks,
        _context = context,
        _dataSource = dataSource,
        _onTap = onTap,
        _onToggleCompleted = onToggleCompleted,
        _onDelete = onDelete {
    _rebuildRows();
    sortedColumns.add(
      const SortColumnDetails(
        name: 'dueDate',
        sortDirection: DataGridSortDirection.ascending,
      ),
    );
  }

  void update({
    required List<HomeworkModel> homeworks,
    required BuildContext context,
    required PlannerItemDataSource dataSource,
    required Function(HomeworkModel) onTap,
    required Function(HomeworkModel, bool) onToggleCompleted,
    required Function(BuildContext, HomeworkModel) onDelete,
  }) {
    _homeworks = homeworks;
    _context = context;
    _dataSource = dataSource;
    _onTap = onTap;
    _onToggleCompleted = onToggleCompleted;
    _onDelete = onDelete;
    _rebuildRows();
    notifyListeners();
  }

  void _rebuildRows() {
    _homeworksById = {for (var hw in _homeworks) hw.id: hw};
    final courses = _dataSource.courses ?? [];
    final categoriesMap = _dataSource.categoriesMap ?? {};

    _dataGridRows = _homeworks.map((homework) {
      final course = courses.firstWhere(
        (c) => c.id == homework.course.id,
        orElse: () => courses.isNotEmpty ? courses.first : _fallbackCourse(),
      );
      final category = categoriesMap[homework.category.id];

      final isCompleted = _dataSource.isHomeworkCompleted(homework);

      final parsedGrade = GradeHelper.parseGrade(homework.currentGrade);
      final double gradeSortValue;
      if (!isCompleted) {
        gradeSortValue = -2.0;
      } else if (parsedGrade == null) {
        gradeSortValue = -1.0;
      } else {
        gradeSortValue = parsedGrade / 100.0;
      }

      final courseTitle = course.title.toLowerCase();
      final categoryTitle = category?.title.toLowerCase() ?? '';

      return DataGridRow(cells: [
        DataGridCell<int>(columnName: 'completed', value: isCompleted ? 1 : 0),
        DataGridCell<String>(columnName: 'title', value: homework.title.toLowerCase()),
        DataGridCell<DateTime>(columnName: 'dueDate', value: homework.start),
        DataGridCell<String>(columnName: 'className', value: courseTitle),
        DataGridCell<String>(columnName: 'category', value: categoryTitle),
        DataGridCell<int>(columnName: 'priority', value: homework.priority),
        DataGridCell<double>(columnName: 'grade', value: gradeSortValue),
        DataGridCell<int>(columnName: 'resources', value: homework.resources.length),
        DataGridCell<int>(columnName: 'attachments', value: homework.attachments.length),
        DataGridCell<int>(columnName: 'actions', value: homework.id),
        DataGridCell<int>(columnName: '_homeworkId', value: homework.id),
        DataGridCell<int>(columnName: '_courseId', value: course.id),
        DataGridCell<Color>(columnName: '_courseColor', value: course.color),
        DataGridCell<int?>(columnName: '_categoryId', value: category?.id),
        DataGridCell<Color?>(columnName: '_categoryColor', value: category?.color),
      ]);
    }).toList();

    sortDataGridRows(_dataGridRows);
  }

  CourseModel _fallbackCourse() {
    return CourseModel(
      id: 0,
      title: 'Unknown',
      color: FallbackConstants.fallbackColor,
      room: '',
      website: '',
      isOnline: false,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      teacherName: '',
      teacherEmail: '',
      credits: 0,
      courseGroup: 0,
      currentGrade: null,
      schedules: const [],
    );
  }

  int get totalRows => _dataGridRows.length;

  void updatePagination({required int currentPage, required int itemsPerPage}) {
    _currentPage = currentPage;
    _itemsPerPage = itemsPerPage;
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows {
    if (_itemsPerPage == -1) return _dataGridRows;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _dataGridRows.length);
    if (startIndex >= _dataGridRows.length) return [];
    return _dataGridRows.sublist(startIndex, endIndex);
  }

  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    sortDataGridRows(_dataGridRows);
  }

  HomeworkModel? getHomeworkFromRow(DataGridRow row) {
    final homeworkId = row
        .getCells()
        .firstWhere((c) => c.columnName == '_homeworkId')
        .value as int;
    return _homeworksById[homeworkId];
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final homeworkId = row
        .getCells()
        .firstWhere((c) => c.columnName == '_homeworkId')
        .value as int;
    final homework = _homeworksById[homeworkId];
    if (homework == null) return null;

    final courseColor = row
        .getCells()
        .firstWhere((c) => c.columnName == '_courseColor')
        .value as Color;
    final categoryColor = row
        .getCells()
        .firstWhere((c) => c.columnName == '_categoryColor',
            orElse: () => const DataGridCell<Color?>(
                columnName: '_categoryColor', value: null))
        .value as Color?;

    final userSettings = _dataSource.userSettings;
    final isCompleted = _dataSource.isHomeworkCompleted(homework);

    final rowColor = userSettings.colorByCategory && categoryColor != null
        ? categoryColor
        : courseColor;

    final isTouchDevice = Responsive.isTouchDevice(_context);
    final isCompact = Responsive.isCompact(_context);
    final rowCursor =
        (isTouchDevice || isCompact) ? SystemMouseCursors.click : MouseCursor.defer;

    final displayCells = _getDisplayCells(row);

    return DataGridRowAdapter(
      color: BadgeColors.background(_context, rowColor),
      cells: displayCells.map((cell) {
        return MouseRegion(
          cursor: rowCursor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _context.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: _buildCell(cell, homework, isCompleted),
          ),
        );
      }).toList(),
    );
  }

  List<DataGridCell> _getDisplayCells(DataGridRow row) {
    final width = MediaQuery.of(_context).size.width;
    final isTouchDevice = Responsive.isTouchDevice(_context);

    return row.getCells().where((cell) {
      if (cell.columnName.startsWith('_')) return false;

      switch (cell.columnName) {
        case 'className':
          return width >= TodosSortColumn.className.minViewportWidth!;
        case 'category':
          return width >= TodosSortColumn.category.minViewportWidth!;
        case 'priority':
          return width >= TodosSortColumn.priority.minViewportWidth!;
        case 'grade':
          return width >= TodosSortColumn.grade.minViewportWidth! || isTouchDevice;
        case 'resources':
          return width >= TodosSortColumn.resources.minViewportWidth!;
        case 'attachments':
          return width >= TodosSortColumn.attachments.minViewportWidth!;
        case 'actions':
          return !isTouchDevice;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildCell(
    DataGridCell cell,
    HomeworkModel homework,
    bool isCompleted,
  ) {
    final userSettings = _dataSource.userSettings;
    final courses = _dataSource.courses ?? [];
    final categoriesMap = _dataSource.categoriesMap ?? {};
    final isTouchDevice = Responsive.isTouchDevice(_context);
    final isCompact = Responsive.isCompact(_context);
    final isSelectable = !isTouchDevice && !isCompact;

    switch (cell.columnName) {
      case 'completed':
        return _buildCheckboxCell(homework, isCompleted);

      case 'title':
        return _buildTitleCell(homework.title, isCompleted, isSelectable);

      case 'dueDate':
        return _buildDueDateCell(homework, userSettings, isSelectable);

      case 'className':
        final course = courses.firstWhere(
          (c) => c.id == homework.course.id,
          orElse: () => courses.isNotEmpty ? courses.first : _fallbackCourse(),
        );
        return _buildClassCell(course);

      case 'category':
        final category = categoriesMap[homework.category.id];
        return _buildCategoryCell(category);

      case 'priority':
        return _buildPriorityCell(homework.priority);

      case 'grade':
        return _buildGradeCell(homework, userSettings, isCompleted);

      case 'resources':
        return _buildResourcesCell(homework, userSettings);

      case 'attachments':
        return _buildAttachmentsCell(homework);

      case 'actions':
        final course = courses.firstWhere(
          (c) => c.id == homework.course.id,
          orElse: () => courses.isNotEmpty ? courses.first : _fallbackCourse(),
        );
        return _buildActionsCell(homework, course, isCompact);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCheckboxCell(HomeworkModel homework, bool isCompleted) {
    final userSettings = _dataSource.userSettings;
    final categoriesMap = _dataSource.categoriesMap ?? {};
    final courses = _dataSource.courses ?? [];

    final category = categoriesMap[homework.category.id];
    final course = courses.firstWhere(
      (c) => c.id == homework.course.id,
      orElse: () => courses.isNotEmpty ? courses.first : _fallbackCourse(),
    );

    final checkColor = userSettings.colorByCategory && category != null
        ? category.color
        : course.color;

    return Center(
      child: Checkbox(
        value: isCompleted,
        onChanged: (value) {
          _onToggleCompleted(homework, value!);
        },
        activeColor: checkColor,
        side: BorderSide(color: checkColor, width: 2),
      ),
    );
  }

  Widget _buildTitleCell(String title, bool isCompleted, bool isSelectable) {
    final titleStyle = AppStyles.smallSecondaryText(_context).copyWith(
      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: _context.colorScheme.onSurface,
      decorationThickness: 2.0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: isSelectable
          ? SelectableText(title, style: titleStyle, maxLines: 1)
          : Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildDueDateCell(
    HomeworkModel homework,
    UserSettingsModel userSettings,
    bool isSelectable,
  ) {
    final dateText = homework.allDay
        ? HeliumDateTime.formatDateForTodos(
            HeliumDateTime.toLocal(homework.start, userSettings.timeZone),
          )
        : HeliumDateTime.formatDateAndTimeForTodos(
            HeliumDateTime.toLocal(homework.start, userSettings.timeZone),
          );
    final dateStyle = AppStyles.smallSecondaryText(_context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: isSelectable
          ? SelectableText(dateText, style: dateStyle, maxLines: 1)
          : Text(
              dateText,
              style: dateStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildClassCell(CourseModel course) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: Alignment.centerLeft,
      child: CourseTitleLabel(
        title: course.title,
        color: course.color,
        compact: true,
      ),
    );
  }

  Widget _buildCategoryCell(CategoryModel? category) {
    if (category == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: Alignment.centerLeft,
      child: CategoryTitleLabel(
        title: category.title,
        color: category.color,
        compact: true,
      ),
    );
  }

  Widget _buildPriorityCell(int priority) {
    final clampedPriority = priority.clamp(1, 100);
    final priorityPercent = clampedPriority / 100;
    final priorityColor = HeliumColors.getColorForPriority(
      clampedPriority.toDouble(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 100,
        height: 8,
        decoration: BoxDecoration(
          color: _context.colorScheme.outline.withValues(alpha: 0.2),
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
      ),
    );
  }

  Widget _buildGradeCell(HomeworkModel homework, UserSettingsModel userSettings, bool isCompleted) {
    if (!isCompleted) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: GradeLabel(
        grade: GradeHelper.gradeForDisplay(homework.currentGrade),
        userSettings: userSettings,
        compact: true,
      ),
    );
  }

  Widget _buildResourcesCell(
    HomeworkModel homework,
    UserSettingsModel userSettings,
  ) {
    if (homework.resources.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Row(
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
            style: AppStyles.smallSecondaryTextLight(_context).copyWith(
              color: userSettings.resourceColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCell(HomeworkModel homework) {
    if (homework.attachments.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attachment,
            size: 14,
            color: _context.semanticColors.success.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            homework.attachments.length.toString(),
            style: AppStyles.smallSecondaryTextLight(_context).copyWith(
              color: _context.semanticColors.success.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCell(
    HomeworkModel homework,
    CourseModel course,
    bool isCompact,
  ) {
    final buttons = <Widget>[];

    if (!isCompact) {
      if (course.teacherEmail.isNotEmpty) {
        buttons.add(
          HeliumIconButton(
            onPressed: () {
              launchUrl(Uri.parse('mailto:${course.teacherEmail}'));
            },
            tooltip: 'Email teacher',
            icon: Icons.email_outlined,
            color: _context.colorScheme.onSurface,
          ),
        );
      }

      if (course.website.isNotEmpty) {
        buttons.add(
          HeliumIconButton(
            onPressed: () {
              launchUrl(
                Uri.parse(course.website),
                mode: LaunchMode.externalApplication,
              );
            },
            tooltip: 'Launch class website',
            icon: Icons.launch_outlined,
            color: _context.colorScheme.onSurface,
          ),
        );
      }

      if (PlannerHelper.shouldShowEditButtonForPlannerItem(_context, homework)) {
        buttons.add(
          HeliumIconButton(
            onPressed: () => _onTap(homework),
            icon: Icons.edit_outlined,
            color: _context.colorScheme.onSurface,
          ),
        );
      }
    }

    if (PlannerHelper.shouldShowDeleteButton(homework)) {
      buttons.add(
        HeliumIconButton(
          onPressed: () => _onDelete(_context, homework),
          icon: Icons.delete_outlined,
          color: _context.colorScheme.onSurface,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
