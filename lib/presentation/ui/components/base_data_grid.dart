// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

final _log = Logger('presentation.components');

/// Mixin that provides standard sorting behavior for SfDataGrid data sources.
///
/// Sorting rules applied uniformly across all columns:
/// - Null values are treated as maximum; last when ascending, first when descending.
/// - Empty strings are treated as maximum; last when ascending, first when descending.
/// - All other values sort via [Comparable.compareTo].
///
/// Cell values should be stored as sortable types (lowercase strings for
/// case-insensitive text sorting, numeric values for grades, etc.).
mixin SortableDataGridSource on DataGridSource {
  /// Sorts [rows] in place based on the current [sortedColumns] state.
  ///
  /// Call this after rebuilding rows to maintain sort order, and it is called
  /// automatically from [performSorting] for user-initiated sorts.
  void sortDataGridRows(List<DataGridRow> rows) {
    if (sortedColumns.isEmpty) return;

    final sortColumn = sortedColumns.first;
    final ascending =
        sortColumn.sortDirection == DataGridSortDirection.ascending;

    rows.sort((a, b) {
      final cellA = a.getCells().firstWhere(
            (c) => c.columnName == sortColumn.name,
            orElse: () => const DataGridCell<String>(columnName: '', value: ''),
          );
      final cellB = b.getCells().firstWhere(
            (c) => c.columnName == sortColumn.name,
            orElse: () => const DataGridCell<String>(columnName: '', value: ''),
          );

      final valueA = cellA.value;
      final valueB = cellB.value;

      // Null and empty strings are treated as maximum: last ascending, first descending
      if (valueA == null && valueB == null) return 0;
      if (valueA == null) return ascending ? 1 : -1;
      if (valueB == null) return ascending ? -1 : 1;

      if (valueA is String && valueB is String) {
        if (valueA.isEmpty && valueB.isEmpty) return 0;
        if (valueA.isEmpty) return ascending ? 1 : -1;
        if (valueB.isEmpty) return ascending ? -1 : 1;
      }

      int comparison = 0;
      if (valueA is Comparable && valueB is Comparable) {
        comparison = valueA.compareTo(valueB);
      }

      return ascending ? comparison : -comparison;
    });
  }
}

/// Base state class for data grid screens. Manages shared lifecycle
/// responsibilities: PrintableArea capture listener, printable area scope
/// registration, and grid controller disposal.
abstract class BaseDataGridState<T extends StatefulWidget> extends State<T> {
  final DataGridController gridController = DataGridController();
  final GlobalKey gridKey = GlobalKey();
  PrintableAreaScope? printableAreaScope;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    PrintableArea.capturing.addListener(_onCapturingChanged);
    // Defer scope lookup until after initState so the inherited widget tree
    // is fully built and PrintableAreaScope.findIn can locate the ancestor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      printableAreaScope = PrintableAreaScope.findIn(context);
      printableAreaScope?.registerHintsProvider(_pdfPageBreakHintsProvider);
    });
  }

  @override
  @mustCallSuper
  void dispose() {
    printableAreaScope?.unregisterHintsProvider(_pdfPageBreakHintsProvider);
    PrintableArea.capturing.removeListener(_onCapturingChanged);
    gridController.dispose();
    super.dispose();
  }

  void _onCapturingChanged() => setState(() {});

  List<double> _pdfPageBreakHintsProvider(RenderBox captureBox) =>
      dataGridPdfPageBreakHints(captureBox, gridKey);
}

/// Base DataGridSource providing shared pagination state and the
/// [updatePagination], [rows], and [performSorting] implementations.
/// Subclasses must assign [dataGridRows] in their rebuild methods.
abstract class BaseDataGridSource extends DataGridSource
    with SortableDataGridSource {
  @protected
  List<DataGridRow> dataGridRows = [];

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  List<DataGridRow> get rows {
    if (_itemsPerPage == -1) return dataGridRows;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, dataGridRows.length);
    if (startIndex >= dataGridRows.length) return [];
    return dataGridRows.sublist(startIndex, endIndex);
  }

  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    _log.fine('performSorting: totalRows=${dataGridRows.length}, currentPage=$_currentPage, itemsPerPage=$_itemsPerPage, sortedColumns=${sortedColumns.map((c) => '${c.name}:${c.sortDirection.name}').join(',')}');
    sortDataGridRows(dataGridRows);
    // Syncfusion captures `rows` (_effectiveRows) from our `rows` getter BEFORE
    // calling performSorting, so it holds a pre-sort snapshot. We must repopulate
    // it from the now-sorted dataGridRows so the grid renders the correct order.
    if (_itemsPerPage == -1) {
      rows
        ..clear()
        ..addAll(dataGridRows);
    } else {
      final startIndex = (_currentPage - 1) * _itemsPerPage;
      final endIndex =
          (startIndex + _itemsPerPage).clamp(0, dataGridRows.length);
      rows
        ..clear()
        ..addAll(
          startIndex < dataGridRows.length
              ? dataGridRows.sublist(startIndex, endIndex)
              : [],
        );
    }
  }

  int get totalRows => dataGridRows.length;

  void updatePagination({required int currentPage, required int itemsPerPage}) {
    _currentPage = currentPage;
    _itemsPerPage = itemsPerPage;
    notifyListeners();
  }
}
