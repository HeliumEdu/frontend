// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';

class TodosTableController extends ChangeNotifier {
  String _sortColumn = 'dueDate';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  bool _hasInitializedNavigation = false;

  /// Whether the initial goToToday navigation has occurred.
  bool get hasInitializedNavigation => _hasInitializedNavigation;

  String get sortColumn => _sortColumn;
  set sortColumn(String value) {
    if (_sortColumn != value) {
      _sortColumn = value;
      notifyListeners();
    }
  }

  bool get sortAscending => _sortAscending;
  set sortAscending(bool value) {
    if (_sortAscending != value) {
      _sortAscending = value;
      notifyListeners();
    }
  }

  int get currentPage => _currentPage;
  set currentPage(int value) {
    if (_currentPage != value) {
      _currentPage = value;
      notifyListeners();
    }
  }

  int get itemsPerPage => _itemsPerPage;
  set itemsPerPage(int value) {
    if (_itemsPerPage != value) {
      _itemsPerPage = value;
      notifyListeners();
    }
  }

  void goToToday(List<HomeworkModel> homeworks) {
    _hasInitializedNavigation = true;

    // Reset sort to due date ascending
    _sortColumn = 'dueDate';
    _sortAscending = true;

    // Sort by due date ascending
    final sorted = List<HomeworkModel>.from(homeworks);
    sorted.sort((a, b) => a.start.compareTo(b.start));

    if (sorted.isEmpty) {
      _currentPage = 1;
      notifyListeners();
      return;
    }

    // Find the first homework due today or later
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int targetIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      final dueDate = DateTime.parse(sorted[i].start);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (dueDateOnly.isAtSameMomentAs(today) || dueDateOnly.isAfter(today)) {
        targetIndex = i;
        break;
      }
    }

    // Calculate effective items per page
    final effectiveItemsPerPage =
        _itemsPerPage == -1 ? sorted.length : _itemsPerPage;

    // If no future items found, show the last page (most recent past items)
    if (targetIndex == -1) {
      _currentPage = (sorted.length / effectiveItemsPerPage).ceil();
    } else {
      // Calculate which page contains this item
      _currentPage = (targetIndex / effectiveItemsPerPage).floor() + 1;
    }

    notifyListeners();
  }
}
