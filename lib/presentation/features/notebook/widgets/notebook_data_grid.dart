// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/ui/components/generic_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_pager.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/components/base_data_grid.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Column definitions with responsive visibility breakpoints.
enum NotebookColumn {
  title(label: 'Title'),
  due(label: 'Due', minViewportWidth: 900, mobileWidth: 144, desktopWidth: 154),
  linkedTo(label: 'Linked To', mobileWidth: 130, tabletWidth: 150, desktopWidth: 200),
  modified(label: 'Modified', minViewportWidth: 950, fixedWidth: 136);

  const NotebookColumn({
    required this.label,
    this.fixedWidth,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.minViewportWidth,
  });

  final String label;
  final double? fixedWidth;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? minViewportWidth;

  double? widthForLayout({required bool isMobile, required bool isTablet}) {
    if (isMobile && mobileWidth != null) return mobileWidth;
    if (isTablet && tabletWidth != null) return tabletWidth;
    if (desktopWidth != null) return desktopWidth;
    return fixedWidth;
  }
}

class NotebookDataGrid extends StatefulWidget {
  final List<NoteModel> notes;
  final Function(NoteModel) onNoteTap;
  final Function(BuildContext, NoteModel) onDelete;
  final UserSettingsModel? userSettings;
  final int rowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final bool isLoading;
  final bool hasAnyNotes;
  final String? emptyMessage;

  const NotebookDataGrid({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onDelete,
    this.userSettings,
    this.rowsPerPage = 10,
    this.onRowsPerPageChanged,
    this.isLoading = false,
    this.hasAnyNotes = false,
    this.emptyMessage,
  });

  @override
  State<NotebookDataGrid> createState() => _NotebookDataGridState();
}

class _NotebookDataGridState extends BaseDataGridState<NotebookDataGrid> {
  int _currentPage = 1;
  late NotesDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _buildDataSource();
    _dataSource.updatePagination(
      currentPage: _currentPage,
      itemsPerPage: widget.rowsPerPage,
    );
  }

  @override
  void didUpdateWidget(NotebookDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes ||
        oldWidget.userSettings != widget.userSettings ||
        oldWidget.onNoteTap != widget.onNoteTap ||
        oldWidget.onDelete != widget.onDelete) {
      _dataSource.update(
        notes: widget.notes,
        context: context,
        userSettings: widget.userSettings,
        onEdit: widget.onNoteTap,
        onDelete: widget.onDelete,
      );
      // Use post-frame callback to ensure UI fully updates after data source change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    if (oldWidget.rowsPerPage != widget.rowsPerPage) {
      _dataSource.updatePagination(
        currentPage: _currentPage,
        itemsPerPage: widget.rowsPerPage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = Responsive.isCompact(context);
    final isCapturing = PrintableArea.capturing.value;
    final showActions = !isTouchDevice && !isCapturing;
    final columns = _buildColumns(isMobile, isTablet, showActions, isCompact);

    final isShowingAll = widget.rowsPerPage == -1;
    final totalItems = widget.notes.length;
    final totalPages = isShowingAll
        ? 1
        : (totalItems / widget.rowsPerPage).ceil().clamp(1, double.maxFinite.toInt());

    var effectiveCurrentPage = _currentPage;
    if (effectiveCurrentPage > totalPages && totalPages > 0) {
      effectiveCurrentPage = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPage != 1) {
          _currentPage = 1;
          _dataSource.updatePagination(
            currentPage: 1,
            itemsPerPage: widget.rowsPerPage,
          );
          setState(() {});
        }
      });
    }

    final startIndex = isShowingAll
        ? 0
        : (effectiveCurrentPage - 1) * widget.rowsPerPage;
    final endIndex = isShowingAll
        ? totalItems
        : (startIndex + widget.rowsPerPage).clamp(0, totalItems);

    final headerColor = context.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.5,
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Column(
              mainAxisSize: isCapturing ? MainAxisSize.min : MainAxisSize.max,
              children: [
                _buildGridSection(
                  context,
                  headerColor,
                  columns,
                  isCompact,
                  isTouchDevice,
                  isCapturing,
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
                      itemsPerPage: widget.rowsPerPage,
                    );
                    setState(() {});
                  },
                  itemsPerPage: widget.rowsPerPage,
                  itemsPerPageOptions: const [5, 10, 25, 50, 100, -1],
                  onItemsPerPageChanged: widget.onRowsPerPageChanged != null
                      ? (value) {
                          widget.onRowsPerPageChanged!(value);
                          _currentPage = 1;
                          _dataSource.updatePagination(
                            currentPage: 1,
                            itemsPerPage: value,
                          );
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.colorScheme.surface.withValues(alpha: 0.7),
              ),
              child: const Center(child: LoadingIndicator(expanded: false)),
            ),
          ),
      ],
    );
  }

  Widget _buildGridSection(
    BuildContext context,
    Color headerColor,
    List<GridColumn> columns,
    bool isCompact,
    bool isTouchDevice,
    bool isCapturing,
  ) {
    final grid = Container(
      key: gridKey,
      child: SfDataGridTheme(
        data: SfDataGridThemeData(
          sortIconColor: context.colorScheme.primary,
          headerColor: headerColor,
        ),
        child: SfDataGrid(
          key: ValueKey(
            'notes_grid_${columns.length}_${isCompact}_$isCapturing',
          ),
          source: _dataSource,
          controller: gridController,
          columnWidthMode: ColumnWidthMode.fill,
          headerRowHeight: 40,
          rowHeight: 50,
          shrinkWrapRows: isCapturing,
          gridLinesVisibility: GridLinesVisibility.none,
          headerGridLinesVisibility: GridLinesVisibility.none,
          selectionMode: (isTouchDevice || isCompact)
              ? SelectionMode.single
              : SelectionMode.none,
          horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
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
            final note = _dataSource.getNoteFromRow(row);
            return GestureDetector(
              onTap: () {
                if (note != null) {
                  widget.onDelete(context, note);
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
              final note = _dataSource.getNoteFromRow(addedRows.first);
              if (note != null) {
                widget.onNoteTap(note);
                gridController.selectedRow = null;
              }
            }
          },
          columns: columns,
        ),
      ),
    );

    final emptyState = !widget.isLoading && widget.notes.isEmpty
        ? !widget.hasAnyNotes
            ? const EmptyCard(
                expanded: false,
                icon: Icons.library_books,
                title: "You haven't added any notes yet",
                message: 'Click "+" to get started',
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 48,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.emptyMessage ?? 'No notes found',
                      style: AppStyles.standardBodyTextLight(context).copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
        : null;

    if (isCapturing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          grid,
          if (emptyState != null) SizedBox(height: 200, child: emptyState),
        ],
      );
    }

    return Expanded(
      child: Stack(
        children: [
          grid,
          if (emptyState != null)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              bottom: 0,
              child: emptyState,
            ),
        ],
      ),
    );
  }

  bool _shouldShowColumn(NotebookColumn column) {
    if (column.minViewportWidth == null) return true;
    return MediaQuery.of(context).size.width >= column.minViewportWidth!;
  }

  List<GridColumn> _buildColumns(
    bool isMobile,
    bool isTablet,
    bool showActions,
    bool isCompact,
  ) {
    final columns = <GridColumn>[];

    columns.add(GridColumn(
      columnName: 'title',
      label: _buildHeaderCell(NotebookColumn.title),
      minimumWidth: 170,
    ));

    if (_shouldShowColumn(NotebookColumn.due)) {
      columns.add(GridColumn(
        columnName: 'due',
        label: _buildHeaderCell(NotebookColumn.due),
        width: NotebookColumn.due.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    columns.add(GridColumn(
      columnName: 'linkedTo',
      label: _buildHeaderCell(NotebookColumn.linkedTo),
      width: NotebookColumn.linkedTo.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
    ));

    if (_shouldShowColumn(NotebookColumn.modified)) {
      columns.add(GridColumn(
        columnName: 'modified',
        label: _buildHeaderCell(NotebookColumn.modified),
        width: NotebookColumn.modified.widthForLayout(isMobile: isMobile, isTablet: isTablet)!,
      ));
    }

    if (showActions) {
      columns.add(GridColumn(
        columnName: 'actions',
        label: const SizedBox.shrink(),
        width: isCompact ? 51 : 93,
        allowSorting: false,
      ));
    }

    return columns;
  }

  NotesDataSource _buildDataSource() {
    return NotesDataSource(
      notes: widget.notes,
      context: context,
      userSettings: widget.userSettings,
      onEdit: widget.onNoteTap,
      onDelete: widget.onDelete,
    );
  }

  Widget _buildHeaderCell(NotebookColumn column) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          column.label,
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onSurface,
            fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14),
          ),
        ),
      ),
    );
  }
}

class NotesDataSource extends BaseDataGridSource {
  List<NoteModel> notes;
  BuildContext context;
  UserSettingsModel? userSettings;
  Function(NoteModel) onEdit;
  Function(BuildContext, NoteModel) onDelete;
  late List<DataGridRow> _allRows;
  late Map<int, NoteModel> _notesById;

  NotesDataSource({
    required this.notes,
    required this.context,
    required this.onEdit,
    required this.onDelete,
    this.userSettings,
  }) {
    sortedColumns.add(
      const SortColumnDetails(
        name: 'title',
        sortDirection: DataGridSortDirection.ascending,
      ),
    );
    _rebuildRows();
  }

  void _rebuildRows() {
    _notesById = {for (var note in notes) note.id: note};
    _allRows = notes.map((note) {
      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'title',
            value: note.title.toLowerCase(),
          ),
          DataGridCell<DateTime?>(columnName: 'due', value: note.linkedEntityDue),
          DataGridCell<String>(
            columnName: 'linkedTo',
            value: note.linkedEntityTitle?.toLowerCase() ?? '',
          ),
          DataGridCell<DateTime>(columnName: 'modified', value: note.updatedAt),
          DataGridCell<int>(columnName: 'actions', value: note.id),
          DataGridCell<Color?>(
            columnName: '_courseColor',
            value: note.courseColor,
          ),
          DataGridCell<Color?>(
            columnName: '_categoryColor',
            value: note.categoryColor,
          ),
          DataGridCell<String>(
            columnName: '_entityType',
            value: note.linkedEntityType,
          ),
          DataGridCell<String>(columnName: '_originalTitle', value: note.title),
          DataGridCell<String>(
            columnName: '_originalLinkedTo',
            value: note.linkedEntityTitle ?? '',
          ),
          DataGridCell<bool?>(
            columnName: '_linkedEntityCompleted',
            value: note.linkedEntityCompleted,
          ),
        ],
      );
    }).toList();
    dataGridRows = _allRows;
    sortDataGridRows(dataGridRows);
  }

  void update({
    required List<NoteModel> notes,
    required BuildContext context,
    required Function(NoteModel) onEdit,
    required Function(BuildContext, NoteModel) onDelete,
    UserSettingsModel? userSettings,
  }) {
    this.notes = notes;
    this.context = context;
    this.userSettings = userSettings;
    this.onEdit = onEdit;
    this.onDelete = onDelete;
    _rebuildRows();
    notifyListeners();
  }

  NoteModel? getNoteFromRow(DataGridRow row) {
    final noteId =
        row.getCells().firstWhere((c) => c.columnName == 'actions').value
            as int;
    return _notesById[noteId];
  }

  List<DataGridCell> _getDisplayCells(DataGridRow row) {
    final width = MediaQuery.of(context).size.width;
    final isTouchDevice = Responsive.isTouchDevice(context);

    return row.getCells().where((cell) {
      if (cell.columnName.startsWith('_')) return false;

      switch (cell.columnName) {
        case 'due':
          return width >= NotebookColumn.due.minViewportWidth!;
        case 'modified':
          return width >= NotebookColumn.modified.minViewportWidth!;
        case 'actions':
          return !isTouchDevice && !PrintableArea.capturing.value;
        default:
          return true;
      }
    }).toList();
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final courseColor =
        row
                .getCells()
                .firstWhere(
                  (c) => c.columnName == '_courseColor',
                  orElse: () => const DataGridCell<Color?>(
                    columnName: '_courseColor',
                    value: null,
                  ),
                )
                .value
            as Color?;

    final categoryColor =
        row
                .getCells()
                .firstWhere(
                  (c) => c.columnName == '_categoryColor',
                  orElse: () => const DataGridCell<Color?>(
                    columnName: '_categoryColor',
                    value: null,
                  ),
                )
                .value
            as Color?;

    final entityType =
        row
                .getCells()
                .firstWhere(
                  (c) => c.columnName == '_entityType',
                  orElse: () => const DataGridCell<String>(
                    columnName: '_entityType',
                    value: '',
                  ),
                )
                .value
            as String;

    Color? rowColor;
    if (entityType == 'homework') {
      // Use category color if colorByCategory is enabled, otherwise course color
      rowColor = (userSettings?.colorByCategory ?? false) && categoryColor != null
          ? categoryColor
          : courseColor;
    } else if (entityType == 'event') {
      rowColor = userSettings?.eventsColor;
    } else if (entityType == 'resource') {
      rowColor = userSettings?.resourceColor;
    }

    final linkedEntityCompleted =
        row
                .getCells()
                .firstWhere(
                  (c) => c.columnName == '_linkedEntityCompleted',
                  orElse: () => const DataGridCell<bool?>(
                    columnName: '_linkedEntityCompleted',
                    value: null,
                  ),
                )
                .value
            as bool?;

    final displayCells = _getDisplayCells(row);

    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = Responsive.isCompact(context);
    final rowCursor = (isTouchDevice || isCompact)
        ? SystemMouseCursors.click
        : MouseCursor.defer;

    return DataGridRowAdapter(
      color: rowColor != null
          ? BadgeColors.background(context, rowColor)
          : null,
      cells: displayCells
          .map(
            (cell) => MouseRegion(
              cursor: rowCursor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: _buildCell(
                  row,
                  cell,
                  rowColor,
                  entityType,
                  courseColor,
                  categoryColor,
                  linkedEntityCompleted,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCell(
    DataGridRow row,
    DataGridCell cell,
    Color? rowColor,
    String entityType,
    Color? courseColor,
    Color? categoryColor,
    bool? linkedEntityCompleted,
  ) {
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = Responsive.isCompact(context);
    final isSelectable = !isTouchDevice && !isCompact;

    if (cell.columnName == 'title') {
      final originalTitle =
          row
                  .getCells()
                  .firstWhere(
                    (c) => c.columnName == '_originalTitle',
                    orElse: () => DataGridCell<String>(
                      columnName: '_originalTitle',
                      value: cell.value as String,
                    ),
                  )
                  .value
              as String;
      if (originalTitle.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            '—',
            style: AppStyles.standardBodyTextLight(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        );
      }
      final titleStyle = AppStyles.smallSecondaryText(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: isSelectable
            ? SelectableText(originalTitle, style: titleStyle, maxLines: 1)
            : Text(
                originalTitle,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      );
    }

    if (cell.columnName == 'linkedTo') {
      final originalLinkedTo =
          row
                  .getCells()
                  .firstWhere(
                    (c) => c.columnName == '_originalLinkedTo',
                    orElse: () => DataGridCell<String>(
                      columnName: '_originalLinkedTo',
                      value: cell.value as String,
                    ),
                  )
                  .value
              as String;
      if (originalLinkedTo.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            '—',
            style: AppStyles.standardBodyTextLight(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        );
      }

      final strikethrough = linkedEntityCompleted == true
          ? TextDecoration.lineThrough
          : null;

      Widget badge;
      if (entityType == 'resource' && userSettings != null) {
        badge = ResourceTitleLabel(
          title: originalLinkedTo,
          userSettings: userSettings!,
          compact: true,
          textDecoration: strikethrough,
        );
      } else if (entityType == 'event') {
        badge = GenericLabel(
          label: originalLinkedTo,
          color: userSettings?.eventsColor ?? context.colorScheme.tertiary,
          icon: AppConstants.eventIcon,
          compact: true,
          textDecoration: strikethrough,
        );
      } else {
        // Homework badge - respect colorByCategory setting
        final badgeColor = (userSettings?.colorByCategory ?? false) && categoryColor != null
            ? categoryColor
            : courseColor;
        badge = GenericLabel(
          label: originalLinkedTo,
          color: badgeColor ?? context.colorScheme.primary,
          icon: AppConstants.assignmentIcon,
          compact: true,
          textDecoration: strikethrough,
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.centerLeft,
        child: badge,
      );
    }

    if (cell.columnName == 'due') {
      final due = cell.value as DateTime?;

      if (due == null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            '—',
            style: AppStyles.standardBodyTextLight(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        );
      }

      final localDate = userSettings != null
          ? HeliumDateTime.toLocal(due, userSettings!.timeZone)
          : due;
      final isAllDay =
          localDate.hour == 0 && localDate.minute == 0 && localDate.second == 0;
      final formattedDate = isAllDay
          ? HeliumDateTime.formatDateForTodos(localDate)
          : HeliumDateTime.formatDateAndTimeForTodos(localDate);
      final dateStyle = AppStyles.smallSecondaryText(context);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: isSelectable
            ? SelectableText(formattedDate, style: dateStyle, maxLines: 1)
            : Text(
                formattedDate,
                style: dateStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      );
    }

    if (cell.columnName == 'modified') {
      final date = cell.value as DateTime;
      final localDate = userSettings != null
          ? HeliumDateTime.toLocal(date, userSettings!.timeZone)
          : date;
      final formattedDate = HeliumDateTime.formatDate(localDate);
      final dateStyle = AppStyles.smallSecondaryText(context);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: isSelectable
            ? SelectableText(formattedDate, style: dateStyle, maxLines: 1)
            : Text(
                formattedDate,
                style: dateStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      );
    }

    if (cell.columnName == 'actions') {
      final noteId = cell.value as int;
      final note = _notesById[noteId];
      if (note != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCompact) ...[
                HeliumIconButton(
                  onPressed: () => onEdit(note),
                  icon: Icons.edit_outlined,
                  color: context.colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              HeliumIconButton(
                onPressed: () => onDelete(context, note),
                icon: Icons.delete_outline,
                color: context.colorScheme.onSurface,
              ),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(cell.value?.toString() ?? ''),
    );
  }
}
