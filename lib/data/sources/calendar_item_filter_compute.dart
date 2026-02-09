// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/utils/app_globals.dart';

/// Lightweight representation of a calendar item for filtering/sorting in isolate.
/// Contains only the fields needed for filtering and sorting operations.
class FilterableItem {
  final int id;
  final int index;
  final CalendarItemType type;
  final String title;
  final String comments;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final bool completed;
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
    this.courseId,
    this.categoryId,
    this.ownerId,
  });
}

/// Parameters for filtering calendar items.
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

  const FilterComputeInput({
    required this.items,
    required this.params,
  });
}

/// Priority order for calendar item types when times are equal.
/// Lower values appear first: Homework → ClassSchedule → Event → External
const _typeSortPriority = {
  CalendarItemType.homework: 0,
  CalendarItemType.courseSchedule: 1,
  CalendarItemType.event: 2,
  CalendarItemType.external: 3,
};

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

  // Sort using the same logic as Sort.byStartThenTitle
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
    case CalendarItemType.homework:
      return filterTypes.contains('Assignments');
    case CalendarItemType.event:
      return filterTypes.contains('Events');
    case CalendarItemType.courseSchedule:
      return filterTypes.contains('Class Schedules');
    case CalendarItemType.external:
      return filterTypes.contains('External Calendars');
  }
}

bool _passesFilters(FilterableItem item, FilterParams params) {
  // Course filter (applies to homework and course schedule)
  if (params.selectedCourseIds.isNotEmpty) {
    if (item.type == CalendarItemType.homework && item.courseId != null) {
      if (!params.selectedCourseIds.contains(item.courseId)) {
        return false;
      }
    } else if (item.type == CalendarItemType.courseSchedule &&
        item.ownerId != null) {
      final courseId = int.tryParse(item.ownerId!);
      if (courseId != null && !params.selectedCourseIds.contains(courseId)) {
        return false;
      }
    }
  }

  // Category filter (applies to homework only)
  if (params.filterCategories.isNotEmpty &&
      item.type == CalendarItemType.homework) {
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
      item.type == CalendarItemType.homework) {
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

// TODO: can we re-use CalendarItemBaseModel, and then use Sort.sortByStartThenTitle?
void _sortByStartThenTitle(List<FilterableItem> list) {
  list.sort((a, b) {
    final aPriority = _typeSortPriority[a.type] ?? 0;
    final bPriority = _typeSortPriority[b.type] ?? 0;

    // Apply priority-based time adjustments for sorting
    final aSecondsToSubtract = a.allDay ? 0 : 3 - aPriority;
    final bSecondsToSubtract = b.allDay ? 0 : 3 - bPriority;
    final aStart = a.start.subtract(Duration(seconds: aSecondsToSubtract));
    final bStart = b.start.subtract(Duration(seconds: bSecondsToSubtract));
    final aEnd = a.end.subtract(Duration(minutes: a.allDay ? 0 : 3 - aPriority));
    final bEnd = b.end.subtract(Duration(minutes: b.allDay ? 0 : 3 - bPriority));

    final startDateCompare = _compareDatesOnly(aStart, bStart);
    if (startDateCompare != 0) return startDateCompare;

    final sameEndDate = _isSameDate(aEnd, bEnd);

    // Before considering type-based priorities, all-day events always shown first
    if (sameEndDate) {
      if (a.allDay != b.allDay) {
        return a.allDay ? -1 : 1;
      }
      final startTimeCompare = aStart.compareTo(bStart);
      if (startTimeCompare != 0) return startTimeCompare;
    } else {
      final aDuration = aEnd.difference(aStart).inMinutes;
      final bDuration = bEnd.difference(bStart).inMinutes;
      final durationCompare = aDuration.compareTo(bDuration);
      if (durationCompare != 0) return durationCompare;
    }

    return aPriority.compareTo(bPriority);
  });
}

int _compareDatesOnly(DateTime a, DateTime b) {
  final aDate = DateTime(a.year, a.month, a.day);
  final bDate = DateTime(b.year, b.month, b.day);
  return aDate.compareTo(bDate);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
