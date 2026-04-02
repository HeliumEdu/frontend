// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:meta/meta.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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

  int get totalRows => dataGridRows.length;

  void updatePagination({required int currentPage, required int itemsPerPage}) {
    _currentPage = currentPage;
    _itemsPerPage = itemsPerPage;
    notifyListeners();
  }

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
    sortDataGridRows(dataGridRows);
  }
}
