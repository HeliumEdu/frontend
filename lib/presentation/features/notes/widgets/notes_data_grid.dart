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
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_pager.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class NotesDataGrid extends StatefulWidget {
  final List<NoteModel> notes;
  final Function(NoteModel) onNoteTap;
  final Function(BuildContext, NoteModel) onDelete;
  final UserSettingsModel? userSettings;
  final int rowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final bool isLoading;

  const NotesDataGrid({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onDelete,
    this.userSettings,
    this.rowsPerPage = 10,
    this.onRowsPerPageChanged,
    this.isLoading = false,
  });

  @override
  State<NotesDataGrid> createState() => _NotesDataGridState();
}

class _NotesDataGridState extends State<NotesDataGrid> {
  final DataGridController _controller = DataGridController();
  final DataPagerController _pagerController = DataPagerController();
  int _currentPage = 1;
  late NotesDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _buildDataSource();
  }

  @override
  void didUpdateWidget(NotesDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes ||
        oldWidget.userSettings != widget.userSettings ||
        oldWidget.onNoteTap != widget.onNoteTap ||
        oldWidget.onDelete != widget.onDelete) {
      _dataSource = _buildDataSource();
    }
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

  @override
  Widget build(BuildContext context) {
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = MediaQuery.of(context).size.width < 800;
    final showLinkedTo = Responsive.isDesktop(context);
    final showActions = !isTouchDevice;

    final isShowingAll = widget.rowsPerPage == -1;
    final totalItems = widget.notes.length;
    final totalPages = isShowingAll
        ? 1
        : (totalItems / widget.rowsPerPage).ceil().clamp(1, 999999);

    var effectiveCurrentPage = _currentPage;
    if (effectiveCurrentPage > totalPages && totalPages > 0) {
      effectiveCurrentPage = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPage != 1) setState(() { _currentPage = 1; });
      });
    }

    final startIndex = isShowingAll
        ? 0
        : (effectiveCurrentPage - 1) * widget.rowsPerPage;
    final endIndex = isShowingAll
        ? totalItems
        : (startIndex + widget.rowsPerPage).clamp(0, totalItems);

    final headerColor = context.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.5);

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
              children: [
                Expanded(
                  child: SfDataGridTheme(
                    data: SfDataGridThemeData(
                      sortIconColor: context.colorScheme.primary,
                      headerColor: headerColor,
                      gridLineColor: context.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    child: SfDataGrid(
                      key: ValueKey('notes_grid_${showLinkedTo}_${showActions}_${isCompact}'),
                      source: _dataSource,
                      controller: _controller,
                      columnWidthMode: ColumnWidthMode.fill,
                      headerRowHeight: 40,
                      rowHeight: 56,
                      gridLinesVisibility: GridLinesVisibility.horizontal,
                      headerGridLinesVisibility: GridLinesVisibility.none,
                      selectionMode: SelectionMode.none,
                      horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
                      navigationMode: GridNavigationMode.row,
                      allowSorting: true,
                      sortingGestureType: SortingGestureType.tap,
                      rowsPerPage: widget.rowsPerPage == -1 ? null : widget.rowsPerPage,
                      allowSwiping: isTouchDevice,
                      swipeMaxOffset: 80,
                      onSwipeEnd: (details) {
                        if (details.swipeDirection ==
                            DataGridRowSwipeDirection.endToStart) {
                          final rowIndex = details.rowIndex;
                          final note = _dataSource.getNoteAtRow(rowIndex);
                          if (note != null) {
                            widget.onDelete(context, note);
                          }
                        }
                      },
                      endSwipeActionsBuilder: (context, row, rowIndex) {
                        return Container(
                          color: context.colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: Icon(
                            Icons.delete_outline,
                            color: context.colorScheme.onError,
                          ),
                        );
                      },
                      onCellTap: (details) {
                        if (details.rowColumnIndex.rowIndex > 0) {
                          final rowIndex = details.rowColumnIndex.rowIndex - 1;
                          final note = _dataSource.getNoteAtRow(rowIndex);
                          if (note != null && (isTouchDevice || isCompact)) {
                            widget.onNoteTap(note);
                          }
                        }
                      },
                      columns: [
                        GridColumn(
                          columnName: 'title',
                          label: _buildHeaderCell('Title'),
                          minimumWidth: 170,
                        ),
                        if (showLinkedTo)
                          GridColumn(
                            columnName: 'linkedTo',
                            label: _buildHeaderCell('Linked To'),
                            width: 200,
                          ),
                        GridColumn(
                          columnName: 'modified',
                          label: _buildHeaderCell('Modified'),
                          width: 118,
                        ),
                        if (showActions)
                          GridColumn(
                            columnName: 'actions',
                            label: const SizedBox.shrink(),
                            width: isCompact ? 51 : 93,
                            allowSorting: false,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 0,
                  child: SfDataPager(
                    delegate: _dataSource,
                    controller: _pagerController,
                    pageCount: isShowingAll ? 1 : totalPages.toDouble(),
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
                    setState(() { _currentPage = page; });
                    _pagerController.selectedPageIndex = page - 1;
                  },
                  itemsPerPage: widget.rowsPerPage,
                  itemsPerPageOptions: const [5, 10, 25, 50, 100],
                  onItemsPerPageChanged: widget.onRowsPerPageChanged != null
                      ? (value) {
                          widget.onRowsPerPageChanged!(value);
                          setState(() { _currentPage = 1; });
                          _pagerController.selectedPageIndex = 0;
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

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppStyles.standardBodyText(context).copyWith(
          color: context.colorScheme.onSurface,
          fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14),
        ),
      ),
    );
  }

}

class NotesDataSource extends DataGridSource {
  final List<NoteModel> notes;
  final BuildContext context;
  final UserSettingsModel? userSettings;
  final Function(NoteModel) onEdit;
  final Function(BuildContext, NoteModel) onDelete;
  List<DataGridRow> _dataGridRows = [];
  late List<DataGridRow> _allRows;
  late Map<int, NoteModel> _notesById;

  NotesDataSource({
    required this.notes,
    required this.context,
    required this.onEdit,
    required this.onDelete,
    this.userSettings,
  }) {
    _notesById = {for (var note in notes) note.id: note};
    _allRows = notes.map((note) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'title', value: note.title),
        DataGridCell<String>(
          columnName: 'linkedTo',
          value: note.link?.linkedEntityTitle ?? '',
        ),
        DataGridCell<DateTime>(columnName: 'modified', value: note.updatedAt),
        DataGridCell<int>(columnName: 'actions', value: note.id),
        // Store additional data for row styling
        DataGridCell<Color?>(
          columnName: '_color',
          value: note.link?.linkedEntityColor,
        ),
        DataGridCell<String>(
          columnName: '_entityType',
          value: note.link?.linkedEntityType ?? '',
        ),
      ]);
    }).toList();
    _dataGridRows = _allRows;
    // Set initial sort by title
    sortedColumns.add(
      const SortColumnDetails(
        name: 'title',
        sortDirection: DataGridSortDirection.ascending,
      ),
    );
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  NoteModel? getNoteAtRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _dataGridRows.length) return null;
    final row = _dataGridRows[rowIndex];
    final noteId = row.getCells()
        .firstWhere((c) => c.columnName == 'actions')
        .value as int;
    return _notesById[noteId];
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final linkedEntityColor = row.getCells()
        .firstWhere((c) => c.columnName == '_color', orElse: () =>
            const DataGridCell<Color?>(columnName: '_color', value: null))
        .value as Color?;

    final entityType = row.getCells()
        .firstWhere((c) => c.columnName == '_entityType', orElse: () =>
            const DataGridCell<String>(columnName: '_entityType', value: ''))
        .value as String;

    // Determine row color based on entity type
    Color? rowColor;
    if (entityType == 'homework') {
      rowColor = linkedEntityColor;
    } else if (entityType == 'event') {
      rowColor = userSettings?.eventsColor;
    } else if (entityType == 'material') {
      rowColor = userSettings?.resourceColor;
    }

    // Filter out internal cells and hidden columns for display
    final displayCells = row.getCells()
        .where((c) => !c.columnName.startsWith('_'))
        .where((c) => Responsive.isDesktop(context) || c.columnName != 'linkedTo')
        .where((c) => !Responsive.isTouchDevice(context) || c.columnName != 'actions')
        .toList();

    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = MediaQuery.of(context).size.width < 800;
    final rowCursor = (isTouchDevice || isCompact)
        ? SystemMouseCursors.click
        : MouseCursor.defer;

    return DataGridRowAdapter(
      color: rowColor != null
          ? BadgeColors.background(context, rowColor)
          : null,
      cells: displayCells.map((cell) => MouseRegion(
        cursor: rowCursor,
        child: _buildCell(cell, rowColor, entityType),
      )).toList(),
    );
  }

  Widget _buildCell(DataGridCell cell, Color? rowColor, String entityType) {
    final isMobile = Responsive.isMobile(context);
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = MediaQuery.of(context).size.width < 800;
    final isSelectable = !isTouchDevice && !isCompact;

    if (cell.columnName == 'title') {
      final title = cell.value as String;
      final displayTitle = title.isEmpty ? 'Untitled' : title;
      final titleStyle = AppStyles.standardBodyText(context).copyWith(
        fontStyle: title.isEmpty ? FontStyle.italic : FontStyle.normal,
        color: title.isEmpty
            ? context.colorScheme.onSurface.withValues(alpha: 0.5)
            : null,
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: isSelectable
            ? SelectableText(
                displayTitle,
                style: titleStyle,
                maxLines: 1,
              )
            : Text(
                displayTitle,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      );
    }

    if (cell.columnName == 'linkedTo') {
      final linkedTo = cell.value as String;
      if (linkedTo.isEmpty) {
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

      final icon = _getEntityIcon(entityType);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: rowColor ?? context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                linkedTo,
                style: AppStyles.standardBodyTextLight(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (cell.columnName == 'modified') {
      final date = cell.value as DateTime;
      final localDate = userSettings != null
          ? HeliumDateTime.toLocal(date, userSettings!.timeZone)
          : date;
      final formattedDate = HeliumDateTime.formatDate(localDate);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          formattedDate,
          style: AppStyles.standardBodyTextLight(context).copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isMobile ? 12 : 14,
          ),
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

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'homework':
        return AppConstants.assignmentIcon;
      case 'event':
        return AppConstants.eventIcon;
      case 'material':
        return Icons.book;
      default:
        return Icons.link_off;
    }
  }
}
