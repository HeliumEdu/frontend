// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Lightweight representation of a calendar item for filtering/sorting in isolate.
/// Contains only the fields needed for filtering and sorting operations.
class FilterableItem {
  final int id;
  final int index;
  final PlannerItemType type;
  final String title;
  final String comments;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final bool completed;
  final bool graded;
  final int? courseId;
  final int? categoryId;
  final String? ownerId;

  const FilterableItem({
    required this.id,
    required this.index,
    required this.type,
    required this.title,
    required this.comments,
    required this.start,
    required this.end,
    required this.allDay,
    this.completed = false,
    this.graded = false,
    this.courseId,
    this.categoryId,
    this.ownerId,
  });
}

/// Parameters for filtering planner items.
class FilterParams {
  final List<String> filterTypes;
  final List<String> filterCategories;
  final Set<int> selectedCourseIds;
  final Set<String> filterStatuses;
  final String searchQuery;
  final Map<int, String> categoryIdToTitle;
  final Map<int, bool> completedOverrides;

  const FilterParams({
    required this.filterTypes,
    required this.filterCategories,
    required this.selectedCourseIds,
    required this.filterStatuses,
    required this.searchQuery,
    required this.categoryIdToTitle,
    required this.completedOverrides,
  });
}

/// Input data for the compute function.
class FilterComputeInput {
  final List<FilterableItem> items;
  final FilterParams params;

  const FilterComputeInput({required this.items, required this.params});
}

/// Top-level function that runs filtering and sorting in a background isolate.
/// Returns the indices of items that pass the filter, in sorted order.
List<int> computeFilteredItems(FilterComputeInput input) {
  final items = input.items;
  final params = input.params;
  final includeAllTypes = params.filterTypes.isEmpty;

  final List<FilterableItem> filtered = [];

  for (final item in items) {
    if (!_shouldIncludeByType(item, params.filterTypes, includeAllTypes)) {
      continue;
    }

    if (!_passesFilters(item, params)) {
      continue;
    }

    filtered.add(item);
  }

  // Sort using shared comparison logic from sort_helpers.dart
  _sortByStartThenTitle(filtered);

  // Return indices in sorted order
  return filtered.map((item) => item.index).toList();
}

bool _shouldIncludeByType(
  FilterableItem item,
  List<String> filterTypes,
  bool includeAllTypes,
) {
  if (includeAllTypes) return true;

  switch (item.type) {
    case PlannerItemType.homework:
      return filterTypes.contains('Assignments');
    case PlannerItemType.event:
      return filterTypes.contains('Events');
    case PlannerItemType.courseSchedule:
      return filterTypes.contains('Class Schedules');
    case PlannerItemType.external:
      return filterTypes.contains('External Calendars');
  }
}

bool _passesFilters(FilterableItem item, FilterParams params) {
  // Course filter (applies to homework and course schedule)
  if (params.selectedCourseIds.isNotEmpty) {
    if (item.type == PlannerItemType.homework && item.courseId != null) {
      if (!params.selectedCourseIds.contains(item.courseId)) {
        return false;
      }
    } else if (item.type == PlannerItemType.courseSchedule &&
        item.ownerId != null) {
      // ownerId is now just the course ID (e.g., "42")
      final courseId = int.tryParse(item.ownerId!);
      if (courseId != null && !params.selectedCourseIds.contains(courseId)) {
        return false;
      }
    }
  }

  // Category filter (applies to homework only)
  if (params.filterCategories.isNotEmpty &&
      item.type == PlannerItemType.homework) {
    final categoryTitle = params.categoryIdToTitle[item.categoryId];
    if (categoryTitle == null || categoryTitle.trim().isEmpty) {
      return false;
    }
    if (!params.filterCategories.contains(categoryTitle)) {
      return false;
    }
  }

  // Status filter (applies to homework only)
  if (params.filterStatuses.isNotEmpty &&
      item.type == PlannerItemType.homework) {
    // Check for completed override first
    final isCompleted = params.completedOverrides[item.id] ?? item.completed;

    // If there's an active override, always include (for optimistic UI)
    if (params.completedOverrides.containsKey(item.id)) {
      // Keep visible during toggle
    } else {
      bool matches = false;

      if (params.filterStatuses.contains('Complete')) {
        matches = matches || isCompleted;
      }
      if (params.filterStatuses.contains('Incomplete')) {
        matches = matches || !isCompleted;
      }
      if (params.filterStatuses.contains('Overdue')) {
        final isOverdue = !isCompleted && item.start.isBefore(DateTime.now());
        matches = matches || isOverdue;
      }
      if (params.filterStatuses.contains('Graded')) {
        matches = matches || item.graded;
      }
      if (params.filterStatuses.contains('Ungraded')) {
        matches = matches || !item.graded;
      }

      if (!matches) return false;
    }
  }

  // Search filter (applies to all types)
  if (params.searchQuery.isNotEmpty) {
    final query = params.searchQuery.toLowerCase();
    if (!item.title.toLowerCase().contains(query) &&
        !item.comments.toLowerCase().contains(query)) {
      return false;
    }
  }

  return true;
}

/// Sorts FilterableItems using the shared calendar item comparison logic.
/// This ensures consistent sorting between sync and async code paths.
void _sortByStartThenTitle(List<FilterableItem> list) {
  list.sort((a, b) {
    return comparePlannerItems(
      aType: a.type,
      bType: b.type,
      aAllDay: a.allDay,
      bAllDay: b.allDay,
      aStart: a.start,
      bStart: b.start,
      aEnd: a.end,
      bEnd: b.end,
      aTitle: a.title,
      bTitle: b.title,
      aCourseId: a.courseId,
      bCourseId: b.courseId,
    );
  });
}
