# Multi-Step Dialog Pattern

This document describes the reusable pattern for implementing multi-step flows that work both as full-screen pages (mobile) and as centered dialogs (desktop/tablet).

## Architecture Overview

### Core Infrastructure (`dialog_step_navigation.dart`)

Three reusable components for any multi-step flow:

1. **`DialogStepNavigator`** - InheritedWidget that provides step navigation callback
2. **`navigateStepInDialog(context, stepIndex)`** - Helper function for dialog-aware navigation
3. **`DialogStepperContainer`** - Base class for stepper containers

## Implementation Steps

### Step 1: Update the Stepper Enum

Add `route` and `buildWidget()` to your step enum:

```dart
enum CalendarItemAddSteps {
  details(Icons.list, AppRoutes.plannerItemAddScreen),
  reminders(Icons.notifications_active_outlined, AppRoutes.plannerItemAddRemindersScreen),
  attachments(Icons.attachment_outlined, AppRoutes.plannerItemAddAttachmentsScreen);

  final IconData icon;
  final String route;

  const CalendarItemAddSteps(this.icon, this.route);

  /// Centralized widget builder - single source of truth!
  Widget buildWidget({
    required int? eventId,
    required int? homeworkId,
    required bool isEdit,
  }) {
    switch (this) {
      case CalendarItemAddSteps.details:
        return PlannerItemAddProvidedScreen(
          eventId: eventId,
          homeworkId: homeworkId,
          isEdit: isEdit,
        );
      case CalendarItemAddSteps.reminders:
        return PlannerItemRemindersScreen(
          isEvent: eventId != null,
          entityId: eventId ?? homeworkId!,
          isEdit: isEdit,
        );
      case CalendarItemAddSteps.attachments:
        return PlannerItemAttachmentsScreen(
          isEvent: eventId != null,
          entityId: eventId ?? homeworkId!,
          isEdit: isEdit,
        );
    }
  }
}
```

### Step 2: Update the Stepper Widget

Simplify navigation logic to use the enum and generic helper:

```dart
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';

void _onStepReached(BuildContext context, int index) {
  if (index == selectedIndex) return;

  onStep?.call();

  // Try dialog navigation first
  if (navigateStepInDialog(context, index)) {
    return;
  }

  // Fall back to router navigation
  final step = CalendarItemAddSteps.values[index];
  final calendarItemBloc = context.read<CalendarItemBloc>();
  final args = CalendarItemAddArgs(
    calendarItemBloc: calendarItemBloc,
    eventId: eventId,
    homeworkId: homeworkId,
    isEdit: isEdit,
  );

  context.pushReplacement(step.route, extra: args);
}
```

### Step 3: Create a Stepper Container

Extend the base class and implement `buildStepWidget`:

```dart
// calendar_item_stepper_container.dart
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';
import 'package:heliumapp/presentation/widgets/calendar_item_add_stepper.dart';

class CalendarItemStepperContainer extends DialogStepperContainer {
  final int? eventId;
  final int? homeworkId;
  final bool isEdit;

  const CalendarItemStepperContainer({
    super.key,
    this.eventId,
    this.homeworkId,
    required this.isEdit,
    super.initialStep = 0,
  });

  @override
  Widget buildStepWidget(BuildContext context, int stepIndex) {
    return CalendarItemAddSteps.values[stepIndex].buildWidget(
      eventId: eventId,
      homeworkId: homeworkId,
      isEdit: isEdit,
    );
  }
}
```

### Step 4: Create a `show*` Helper Function

```dart
// In planner_item_add_screen.dart or similar
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_item_stepper_container.dart';

void showCalendarItemAdd(
  BuildContext context, {
  int? eventId,
  int? homeworkId,
  bool isEdit = false,
  int initialStep = 0,
  List<SingleChildWidget>? providers,
}) {
  if (Responsive.isMobile(context)) {
    context.push(
      AppRoutes.plannerItemAddScreen,
      extra: CalendarItemAddArgs(
        calendarItemBloc: context.read<CalendarItemBloc>(),
        eventId: eventId,
        homeworkId: homeworkId,
        isEdit: isEdit,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      child: CalendarItemStepperContainer(
        eventId: eventId,
        homeworkId: homeworkId,
        isEdit: isEdit,
        initialStep: initialStep,
      ),
      providers: providers,
      width: 600,
      alignment: Alignment.center,
    );
  }
}
```

### Step 5: Update Step Screens to Use Dialog Navigation

In screens that advance to the next step:

```dart
import 'package:heliumapp/presentation/views/core/dialog_step_navigation.dart';

// When advancing to next step
if (state.advanceNavOnSuccess) {
  // Try dialog navigation first
  if (!navigateStepInDialog(context, 1)) {
    // Fall back to router navigation
    context.pushReplacement(
      AppRoutes.plannerItemAddRemindersScreen,
      extra: args,
    );
  }
}
```

### Step 6: Use the Helper Function

Replace all `context.push()` calls with the new helper:

```dart
// Before
context.push(
  AppRoutes.plannerItemAddScreen,
  extra: CalendarItemAddArgs(...),
);

// After
showCalendarItemAdd(
  context,
  eventId: eventId,
  homeworkId: homeworkId,
  isEdit: false,
  providers: [
    BlocProvider<CalendarItemBloc>.value(
      value: context.read<CalendarItemBloc>(),
    ),
  ],
);
```

## Benefits

✅ **DRY** - Step definitions in one place (the enum)
✅ **Reusable** - Core infrastructure works for any multi-step flow
✅ **Type-safe** - Enum ensures valid steps
✅ **Consistent UX** - Same pattern across all steppers
✅ **Easy to maintain** - Adding steps only requires updating the enum

## Result

- **Mobile**: Full-screen pages with router navigation (unchanged behavior)
- **Desktop/Tablet**: Centered modal dialog with internal step navigation (new behavior)
