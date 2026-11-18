import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_model.dart';
import 'package:heliumapp/data/sources/planner_item_data_source.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class PlannerFilterMenuContent extends StatelessWidget {
  final PlannerItemDataSource? plannerItemDataSource;
  final PlannerView currentView;
  final UserSettingsModel userSettings;
  final List<CourseModel> displayCourses;
  final bool isMobile;
  final List<CategoryModel> deduplicatedCategories;
  final Map<int, CategoryModel> categoriesMap;
  final Map<int, ExternalCalendarModel> externalCalendarsById;
  final StateSetter setSheetState;

  const PlannerFilterMenuContent({
    super.key,
    required this.plannerItemDataSource,
    required this.currentView,
    required this.userSettings,
    required this.displayCourses,
    required this.isMobile,
    required this.deduplicatedCategories,
    required this.categoriesMap,
    required this.externalCalendarsById,
    required this.setSheetState,
  });

  static bool hasCoursesFilter(
    PlannerItemDataSource? plannerItemDataSource,
  ) {
    if (plannerItemDataSource == null) return false;

    final selectedCourses = plannerItemDataSource.selectedCourses;

    if (selectedCourses.isEmpty) return false;

    return selectedCourses.values.any((isSelected) => isSelected);
  }

  static bool hasStatusFilters(
    PlannerItemDataSource? plannerItemDataSource,
  ) {
    if (plannerItemDataSource == null) return false;

    final categories = plannerItemDataSource.filterCategories;
    final types = plannerItemDataSource.filterTypes;
    final statuses = plannerItemDataSource.filterStatuses;
    final selectedCalendars =
        plannerItemDataSource.selectedExternalCalendarIds;

    if (types.isNotEmpty) return true;

    if (categories.isNotEmpty) return true;

    if (statuses.isNotEmpty) return true;

    if (selectedCalendars.isNotEmpty) return true;

    return false;
  }

  static List<CategoryModel> deduplicateCategoriesByTitle(
    Iterable<CategoryModel> categories,
  ) {
    final uniqueCategories = <String, CategoryModel>{};
    for (final category in categories) {
      if (!uniqueCategories.containsKey(category.title)) {
        uniqueCategories[category.title] = category;
      }
    }
    return uniqueCategories.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = plannerItemDataSource!.filterStatuses;
    final isCompleteFilterEnabled =
        statuses.contains(PlannerFilterStatus.complete.value) ||
        statuses.contains(PlannerFilterStatus.incomplete.value);
    final showCompletedOnly = statuses.contains(
      PlannerFilterStatus.complete.value,
    );
    final isGradedFilterEnabled =
        statuses.contains(PlannerFilterStatus.graded.value) ||
        statuses.contains(PlannerFilterStatus.ungraded.value);
    final showGradedOnly = statuses.contains(PlannerFilterStatus.graded.value);

    void setCompleteFilterMode({
      required bool enabled,
      required bool completeOnly,
    }) {
      final currentStatuses = Set<String>.from(
        plannerItemDataSource!.filterStatuses,
      );
      currentStatuses.remove(PlannerFilterStatus.complete.value);
      currentStatuses.remove(PlannerFilterStatus.incomplete.value);
      if (enabled) {
        currentStatuses.add(
          completeOnly
              ? PlannerFilterStatus.complete.value
              : PlannerFilterStatus.incomplete.value,
        );
      }
      plannerItemDataSource!.setFilterStatuses(currentStatuses);
      setSheetState(() {});
    }

    void setGradedFilterMode({
      required bool enabled,
      required bool gradedOnly,
    }) {
      final currentStatuses = Set<String>.from(
        plannerItemDataSource!.filterStatuses,
      );
      currentStatuses.remove(PlannerFilterStatus.graded.value);
      currentStatuses.remove(PlannerFilterStatus.ungraded.value);
      if (enabled) {
        currentStatuses.add(
          gradedOnly
              ? PlannerFilterStatus.graded.value
              : PlannerFilterStatus.ungraded.value,
        );
      }
      plannerItemDataSource!.setFilterStatuses(currentStatuses);
      setSheetState(() {});
    }

    Widget buildStatusTile(String label) {
      final isChecked = plannerItemDataSource!.filterStatuses.contains(label);
      return HeliumCheckboxListTile(
        title: Text(label, style: AppStyles.formText(context)),
        value: isChecked,
        onChanged: (value) {
          final currentStatuses = Set<String>.from(
            plannerItemDataSource!.filterStatuses,
          );
          if (value == true) {
            currentStatuses.add(label);
          } else {
            currentStatuses.remove(label);
          }
          plannerItemDataSource!.setFilterStatuses(currentStatuses);
          setSheetState(() {});
        },
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
    }

    final visibleCategories = _getVisibleCategories();
    final visibleExternalCalendars = _getVisibleExternalCalendars();
    final selectedExternalCalendarIds =
        plannerItemDataSource!.selectedExternalCalendarIds;

    return ConstrainedBox(
      constraints: isMobile
          ? BoxConstraints.tightFor(
              height:
                  MediaQuery.of(context).size.height *
                  AppConstants.bottomSheetMaxHeightFactor,
            )
          : BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
      child: SingleChildScrollView(
        padding: Responsive.sheetContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: HeliumMenuTitle(title: 'Filters')),
                TextButton(
                  onPressed: () {
                    plannerItemDataSource!.clearFilters();
                    setSheetState(() {});
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),

            if (currentView != PlannerView.todos) ...[
              const HeliumMenuSectionHeader(title: 'TYPES'),
              HeliumCheckboxListTile(
                title: Row(
                  children: [
                    currentView == PlannerView.month &&
                            Responsive.isMobile(context)
                        ? const Icon(
                            AppConstants.assignmentIcon,
                            size: 18,
                            color: PlannerTypeColors.homework,
                          )
                        : PlannerTypeColors.rainbowIcon(
                            AppConstants.assignmentIcon,
                          ),
                    const SizedBox(width: 8),
                    Text(
                      PlannerFilterType.assignments.value,
                      style: AppStyles.formText(context),
                    ),
                  ],
                ),
                value: plannerItemDataSource!.filterTypes.contains(
                  PlannerFilterType.assignments.value,
                ),
                onChanged: (value) {
                  final currentTypes = List<String>.from(
                    plannerItemDataSource!.filterTypes,
                  );
                  if (value == true) {
                    if (!currentTypes.contains(
                      PlannerFilterType.assignments.value,
                    )) {
                      currentTypes.add(PlannerFilterType.assignments.value);
                    }
                  } else {
                    currentTypes.remove(PlannerFilterType.assignments.value);
                  }
                  plannerItemDataSource!.setFilterTypes(currentTypes);
                  setSheetState(() {});
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              HeliumCheckboxListTile(
                title: Row(
                  children: [
                    currentView == PlannerView.month &&
                            Responsive.isMobile(context)
                        ? const Icon(
                            AppConstants.courseScheduleIcon,
                            size: 18,
                            color: PlannerTypeColors.classSchedules,
                          )
                        : PlannerTypeColors.rainbowIcon(
                            AppConstants.courseScheduleIcon,
                          ),
                    const SizedBox(width: 8),
                    Text(
                      PlannerFilterType.classSchedules.value,
                      style: AppStyles.formText(context),
                    ),
                  ],
                ),
                value: plannerItemDataSource!.filterTypes.contains(
                  PlannerFilterType.classSchedules.value,
                ),
                onChanged: (value) {
                  final currentTypes = List<String>.from(
                    plannerItemDataSource!.filterTypes,
                  );
                  if (value == true) {
                    if (!currentTypes.contains(
                      PlannerFilterType.classSchedules.value,
                    )) {
                      currentTypes.add(PlannerFilterType.classSchedules.value);
                    }
                  } else {
                    currentTypes.remove(PlannerFilterType.classSchedules.value);
                  }
                  plannerItemDataSource!.setFilterTypes(currentTypes);
                  setSheetState(() {});
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              HeliumCheckboxListTile(
                title: Row(
                  children: [
                    Icon(
                      AppConstants.eventIcon,
                      size: 18,
                      color: userSettings.eventsColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      PlannerFilterType.events.value,
                      style: AppStyles.formText(context),
                    ),
                  ],
                ),
                value: plannerItemDataSource!.filterTypes.contains(
                  PlannerFilterType.events.value,
                ),
                onChanged: (value) {
                  final currentTypes = List<String>.from(
                    plannerItemDataSource!.filterTypes,
                  );
                  if (value == true) {
                    if (!currentTypes.contains(
                      PlannerFilterType.events.value,
                    )) {
                      currentTypes.add(PlannerFilterType.events.value);
                    }
                  } else {
                    currentTypes.remove(PlannerFilterType.events.value);
                  }
                  plannerItemDataSource!.setFilterTypes(currentTypes);
                  setSheetState(() {});
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              HeliumCheckboxListTile(
                title: Row(
                  children: [
                    currentView == PlannerView.month &&
                            Responsive.isMobile(context)
                        ? const Icon(
                            AppConstants.externalCalendarIcon,
                            size: 18,
                            color: PlannerTypeColors.externalCalendars,
                          )
                        : PlannerTypeColors.rainbowIcon(
                            AppConstants.externalCalendarIcon,
                          ),
                    const SizedBox(width: 8),
                    Text(
                      PlannerFilterType.externalCalendars.value,
                      style: AppStyles.formText(context),
                    ),
                  ],
                ),
                value: plannerItemDataSource!.filterTypes.contains(
                  PlannerFilterType.externalCalendars.value,
                ),
                onChanged: (value) {
                  final currentTypes = List<String>.from(
                    plannerItemDataSource!.filterTypes,
                  );
                  if (value == true) {
                    if (!currentTypes.contains(
                      PlannerFilterType.externalCalendars.value,
                    )) {
                      currentTypes.add(
                        PlannerFilterType.externalCalendars.value,
                      );
                    }
                  } else {
                    currentTypes.remove(
                      PlannerFilterType.externalCalendars.value,
                    );
                  }
                  plannerItemDataSource!.setFilterTypes(currentTypes);
                  setSheetState(() {});
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            if (_areCourseItemsVisible() && displayCourses.length > 1) ...[
              const HeliumMenuSectionHeader(title: 'CLASSES'),
              for (int i = 0; i < displayCourses.length; i++) ...[
                if (i > 0 &&
                    displayCourses[i].courseGroup !=
                        displayCourses[i - 1].courseGroup)
                  const Divider(height: 20),
                Builder(
                  builder: (context) {
                    final course = displayCourses[i];
                    final isSelected =
                        plannerItemDataSource!.selectedCourses[course.id] ??
                        false;
                    return HeliumCheckboxListTile(
                      title: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: course.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course.title,
                              style: AppStyles.formText(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        final currentFilters = Map<int, bool>.from(
                          plannerItemDataSource!.selectedCourses,
                        );
                        if (value == true) {
                          currentFilters[course.id] = true;
                        } else {
                          currentFilters.remove(course.id);
                        }
                        plannerItemDataSource!.setSelectedCourses(
                          currentFilters,
                        );
                        setSheetState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ],

            if (visibleExternalCalendars.isNotEmpty) ...[
              const HeliumMenuSectionHeader(title: 'EXTERNAL CALENDARS'),
              ...visibleExternalCalendars.map((calendar) {
                return HeliumCheckboxListTile(
                  title: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: calendar.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          calendar.title,
                          style: AppStyles.formText(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  value: selectedExternalCalendarIds.contains(calendar.id),
                  onChanged: (value) {
                    final current = Set<int>.from(selectedExternalCalendarIds);
                    if (value == true) {
                      current.add(calendar.id);
                    } else {
                      current.remove(calendar.id);
                    }
                    plannerItemDataSource!.setSelectedExternalCalendarIds(
                      current,
                    );
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],

            if (_areAssignmentsVisible()) ...[
              const HeliumMenuSectionHeader(title: 'STATUS'),
              _CheckboxToggle(
                isChecked: isCompleteFilterEnabled,
                isToggleOn: showCompletedOnly,
                baseLabel: PlannerFilterStatus.complete.value,
                toggleOnLabel: PlannerFilterStatus.complete.value,
                toggleOffLabel: PlannerFilterStatus.incomplete.value,
                onCheckedChanged: (value) {
                  setCompleteFilterMode(
                    enabled: value ?? false,
                    // Default to complete-only when enabling via checkbox.
                    completeOnly: true,
                  );
                },
                onToggleChanged: (value) {
                  setCompleteFilterMode(enabled: true, completeOnly: value);
                },
                onToggleTapWhenDisabled: () {
                  setCompleteFilterMode(
                    enabled: true,
                    // If switch is tapped first, enable and show complete-only.
                    completeOnly: true,
                  );
                },
              ),
              _CheckboxToggle(
                isChecked: isGradedFilterEnabled,
                isToggleOn: showGradedOnly,
                baseLabel: PlannerFilterStatus.graded.value,
                toggleOnLabel: PlannerFilterStatus.graded.value,
                toggleOffLabel: PlannerFilterStatus.ungraded.value,
                onCheckedChanged: (value) {
                  setGradedFilterMode(
                    enabled: value ?? false,
                    // Default to graded-only when enabling via checkbox.
                    gradedOnly: true,
                  );
                },
                onToggleChanged: (value) {
                  setGradedFilterMode(enabled: true, gradedOnly: value);
                },
                onToggleTapWhenDisabled: () {
                  setGradedFilterMode(
                    enabled: true,
                    // If switch is tapped first, enable and show graded-only.
                    gradedOnly: true,
                  );
                },
              ),
              buildStatusTile(PlannerFilterStatus.overdue.value),
            ],

            if (visibleCategories.length > 1 && _areAssignmentsVisible()) ...[
              const HeliumMenuSectionHeader(title: 'CATEGORIES'),
              ...visibleCategories.map((category) {
                return HeliumCheckboxListTile(
                  title: Text(
                    category.title,
                    style: AppStyles.formText(context),
                  ),
                  value: plannerItemDataSource!.filterCategories.contains(
                    category.title,
                  ),
                  onChanged: (value) {
                    final currentCategories = List<String>.from(
                      plannerItemDataSource!.filterCategories,
                    );
                    if (value == true) {
                      if (!currentCategories.contains(category.title)) {
                        currentCategories.add(category.title);
                      }
                    } else {
                      currentCategories.remove(category.title);
                    }
                    plannerItemDataSource!.setFilterCategories(
                      currentCategories,
                    );
                    setSheetState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  List<CategoryModel> _getVisibleCategories() {
    if (!hasCoursesFilter(plannerItemDataSource)) {
      return deduplicatedCategories;
    }

    final filteredCourseIds = plannerItemDataSource!.selectedCourses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();

    final filteredCategories = categoriesMap.values.where(
      (cat) => filteredCourseIds.contains(cat.course),
    );

    return deduplicateCategoriesByTitle(filteredCategories);
  }

  List<ExternalCalendarModel> _getVisibleExternalCalendars() {
    if (currentView == PlannerView.todos) return [];

    final enabled = externalCalendarsById.values
        .where((c) => c.shownOnCalendar == true)
        .toList();
    if (enabled.length <= 1) return [];

    final filterTypes = plannerItemDataSource!.filterTypes;
    final externalCalendarsVisible =
        filterTypes.isEmpty ||
        filterTypes.contains(PlannerFilterType.externalCalendars.value);
    if (!externalCalendarsVisible) return [];

    return enabled;
  }

  bool _areAssignmentsVisible() {
    if (currentView == PlannerView.todos) return true;
    final types = plannerItemDataSource!.filterTypes;
    return types.isEmpty || types.contains(PlannerFilterType.assignments.value);
  }

  bool _areCourseItemsVisible() {
    if (currentView == PlannerView.todos) return true;
    final types = plannerItemDataSource!.filterTypes;
    return types.isEmpty ||
        types.contains(PlannerFilterType.assignments.value) ||
        types.contains(PlannerFilterType.classSchedules.value);
  }
}

class _CheckboxToggle extends StatelessWidget {
  final bool isChecked;
  final bool isToggleOn;
  final String baseLabel;
  final String toggleOnLabel;
  final String toggleOffLabel;
  final ValueChanged<bool?> onCheckedChanged;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onToggleTapWhenDisabled;

  const _CheckboxToggle({
    required this.isChecked,
    required this.isToggleOn,
    required this.baseLabel,
    required this.toggleOnLabel,
    required this.toggleOffLabel,
    required this.onCheckedChanged,
    required this.onToggleChanged,
    required this.onToggleTapWhenDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final label = isChecked
        ? (isToggleOn ? toggleOnLabel : toggleOffLabel)
        : baseLabel;

    return HeliumCheckboxListTile(
      title: Text(label, style: AppStyles.formText(context)),
      value: isChecked,
      onChanged: onCheckedChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Only',
            style: AppStyles.smallSecondaryTextLight(
              context,
            ).copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !isChecked
                ? () {
                    Feedback.forTap(context);
                    onToggleTapWhenDisabled();
                  }
                : null,
            child: Switch(
              value: isToggleOn,
              onChanged: isChecked ? onToggleChanged : null,
              mouseCursor: SystemMouseCursors.click,
            ),
          ),
        ],
      ),
    );
  }
}
