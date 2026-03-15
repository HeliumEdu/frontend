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
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_pager.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

class NotesDataGrid extends StatefulWidget {
  final List<NoteModel> notes;
  final Function(NoteModel) onNoteTap;
  final Function(BuildContext, NoteModel) onDelete;
  final UserSettingsModel? userSettings;
  final int rowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final bool isLoading;
  final bool hasAnyNotes;
  final String? emptyMessage;

  const NotesDataGrid({
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
      _dataSource.update(
        notes: widget.notes,
        context: context,
        userSettings: widget.userSettings,
        onEdit: widget.onNoteTap,
        onDelete: widget.onDelete,
      );
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
    final showModified = !Responsive.isMobile(context);
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
                  child: Stack(
                    children: [
                      SfDataGridTheme(
                        data: SfDataGridThemeData(
                          sortIconColor: context.colorScheme.primary,
                          headerColor: headerColor,
                        ),
                        child: SfDataGrid(
                          key: ValueKey('notes_grid_${showModified}_${showActions}_$isCompact'),
                          source: _dataSource,
                          controller: _controller,
                          columnWidthMode: ColumnWidthMode.fill,
                          headerRowHeight: 40,
                          rowHeight: 50,
                          gridLinesVisibility: GridLinesVisibility.none,
                          headerGridLinesVisibility: GridLinesVisibility.none,
                          selectionMode: SelectionMode.none,
                          horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
                          navigationMode: GridNavigationMode.row,
                          allowSorting: true,
                          sortingGestureType: SortingGestureType.tap,
                          rowsPerPage: widget.rowsPerPage == -1 ? null : widget.rowsPerPage,
                          allowSwiping: isTouchDevice,
                          swipeMaxOffset: 80,
                          onSwipeStart: (details) {
                            return details.swipeDirection ==
                                DataGridRowSwipeDirection.endToStart;
                          },
                          onSwipeEnd: (details) {
                            if (details.swipeDirection ==
                                DataGridRowSwipeDirection.endToStart) {
                              final rowIndex = details.rowIndex;
                              final note = _dataSource.getNoteAtRow(rowIndex);
                              if (note != null) {
                                widget.onDelete(context, note);
                              }
                            }
                            _dataSource.notifyListeners();
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
                            GridColumn(
                              columnName: 'linkedTo',
                              label: _buildHeaderCell('Linked To'),
                              width: isCompact ? 150 : 200,
                            ),
                            if (showModified)
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
                      if (!widget.isLoading && widget.notes.isEmpty)
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: !widget.hasAnyNotes
                              ? const EmptyCard(
                                  expanded: false,
                                  icon: Icons.library_books,
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
                                ),
                        ),
                    ],
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
                  itemsPerPageOptions: const [5, 10, 25, 50, 100, -1],
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppStyles.standardBodyText(context).copyWith(
            color: context.colorScheme.onSurface,
            fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14),
          ),
        ),
      ),
    );
  }

}

class NotesDataSource extends DataGridSource with SortableDataGridSource {
  List<NoteModel> notes;
  BuildContext context;
  UserSettingsModel? userSettings;
  Function(NoteModel) onEdit;
  Function(BuildContext, NoteModel) onDelete;
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
    _rebuildRows();
    sortedColumns.add(
      const SortColumnDetails(
        name: 'title',
        sortDirection: DataGridSortDirection.ascending,
      ),
    );
  }

  void _rebuildRows() {
    _notesById = {for (var note in notes) note.id: note};
    _allRows = notes.map((note) {
      return DataGridRow(cells: [
        // Store lowercase for case-insensitive sorting
        DataGridCell<String>(columnName: 'title', value: note.title.toLowerCase()),
        DataGridCell<String>(
          columnName: 'linkedTo',
          value: note.link?.linkedEntityTitle?.toLowerCase() ?? '',
        ),
        DataGridCell<DateTime>(columnName: 'modified', value: note.updatedAt),
        DataGridCell<int>(columnName: 'actions', value: note.id),
        // Store additional data for row styling and display
        DataGridCell<Color?>(
          columnName: '_color',
          value: note.link?.linkedEntityColor,
        ),
        DataGridCell<Color?>(
          columnName: '_colorAlt',
          value: note.link?.linkedEntityColorAlt,
        ),
        DataGridCell<String>(
          columnName: '_entityType',
          value: note.link?.linkedEntityType ?? '',
        ),
        // Store original title for display
        DataGridCell<String>(
          columnName: '_originalTitle',
          value: note.title,
        ),
        DataGridCell<String>(
          columnName: '_originalLinkedTo',
          value: note.link?.linkedEntityTitle ?? '',
        ),
      ]);
    }).toList();
    _dataGridRows = _allRows;

    // Apply current sort order
    sortDataGridRows(_dataGridRows);
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

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    sortDataGridRows(rows);
  }

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

    final linkedEntityColorAlt = row.getCells()
        .firstWhere((c) => c.columnName == '_colorAlt', orElse: () =>
            const DataGridCell<Color?>(columnName: '_colorAlt', value: null))
        .value as Color?;

    final entityType = row.getCells()
        .firstWhere((c) => c.columnName == '_entityType', orElse: () =>
            const DataGridCell<String>(columnName: '_entityType', value: ''))
        .value as String;

    // Determine row color based on entity type and colorByCategory preference
    Color? rowColor;
    if (entityType == 'homework') {
      rowColor = (userSettings?.colorByCategory ?? false) && linkedEntityColorAlt != null
          ? linkedEntityColorAlt
          : linkedEntityColor;
    } else if (entityType == 'event') {
      rowColor = userSettings?.eventsColor;
    } else if (entityType == 'resource') {
      rowColor = userSettings?.resourceColor;
    }

    // Filter out internal cells and hidden columns for display
    final displayCells = row.getCells()
        .where((c) => !c.columnName.startsWith('_'))
        .where((c) => !Responsive.isMobile(context) || c.columnName != 'modified')
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: _buildCell(row, cell, rowColor, entityType, linkedEntityColor),
        ),
      )).toList(),
    );
  }

  Widget _buildCell(DataGridRow row, DataGridCell cell, Color? rowColor, String entityType, Color? linkedEntityColor) {
    final isTouchDevice = Responsive.isTouchDevice(context);
    final isCompact = MediaQuery.of(context).size.width < 800;
    final isSelectable = !isTouchDevice && !isCompact;

    if (cell.columnName == 'title') {
      // Get original title for display (cell.value is lowercase for sorting)
      final originalTitle = row.getCells()
          .firstWhere((c) => c.columnName == '_originalTitle',
              orElse: () => DataGridCell<String>(columnName: '_originalTitle', value: cell.value as String))
          .value as String;
      final title = originalTitle;
      final displayTitle = title.isEmpty ? 'Untitled' : title;
      final titleStyle = AppStyles.smallSecondaryText(context).copyWith(
        fontStyle: title.isEmpty ? FontStyle.italic : FontStyle.normal,
        color: title.isEmpty
            ? context.colorScheme.onSurface.withValues(alpha: 0.5)
            : null,
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
      // Get original linkedTo for display (cell.value is lowercase for sorting)
      final originalLinkedTo = row.getCells()
          .firstWhere((c) => c.columnName == '_originalLinkedTo',
              orElse: () => DataGridCell<String>(columnName: '_originalLinkedTo', value: cell.value as String))
          .value as String;
      final linkedTo = originalLinkedTo;
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

      Widget badge;
      if (entityType == 'resource' && userSettings != null) {
        badge = ResourceTitleLabel(title: linkedTo, userSettings: userSettings!, compact: true);
      } else if (entityType == 'event') {
        badge = CourseTitleLabel(
          title: linkedTo,
          color: userSettings?.eventsColor ?? context.colorScheme.tertiary,
          icon: AppConstants.eventIcon,
          showIconTab: true,
          compact: true,
        );
      } else {
        badge = CourseTitleLabel(
          title: linkedTo,
          color: linkedEntityColor ?? context.colorScheme.primary,
          icon: AppConstants.assignmentIcon,
          showIconTab: true,
          compact: true,
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.centerLeft,
        child: badge,
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
