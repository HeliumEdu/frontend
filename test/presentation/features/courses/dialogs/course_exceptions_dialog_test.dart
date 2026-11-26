import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/course_exceptions_dialog.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';

void main() {
  final holidays = [DateTime(2026, 11, 26), DateTime(2026, 11, 27)];

  Future<void> givenDialogIsOpen(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    tester
        .widget<IconButton>(find.byKey(const Key(PageHeader.saveButtonKey)))
        .onPressed!();
    await tester.pumpAndSettle();
  }

  Future<void> removeFirstDateAndConfirm(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    await confirm(tester);
  }

  testWidgets('confirming without onConfirm returns the edited dates', (
    tester,
  ) async {
    // GIVEN
    List<DateTime>? result;
    await givenDialogIsOpen(
      tester,
      (context) async => result = await showDialog<List<DateTime>>(
        context: context,
        builder: (_) => CourseExceptionsDialog(
          title: 'Holidays',
          exceptions: holidays,
          firstDate: DateTime(2026, 8, 24),
          lastDate: DateTime(2026, 12, 18),
        ),
      ),
    );

    // WHEN
    await removeFirstDateAndConfirm(tester);

    // THEN
    expect(result, [DateTime(2026, 11, 27)]);
    expect(find.text('Holidays'), findsNothing);
  });

  testWidgets('confirming without changes returns nothing', (tester) async {
    // GIVEN
    List<DateTime>? result = const [];
    await givenDialogIsOpen(
      tester,
      (context) async => result = await showDialog<List<DateTime>>(
        context: context,
        builder: (_) => CourseExceptionsDialog(
          title: 'Holidays',
          exceptions: holidays,
        ),
      ),
    );

    // WHEN
    await confirm(tester);

    // THEN
    expect(result, isNull);
  });

  testWidgets('confirming cancellations saves them through onConfirm', (
    tester,
  ) async {
    // GIVEN
    List<DateTime>? saved;
    await givenDialogIsOpen(
      tester,
      (context) => showCourseExceptionsDialog(
        context: context,
        courseExceptions: holidays,
        onConfirm: (exceptions, _) async {
          saved = exceptions;
          return null;
        },
      ),
    );

    // WHEN
    await removeFirstDateAndConfirm(tester);

    // THEN
    expect(saved, [DateTime(2026, 11, 27)]);
    expect(find.text('Cancellations'), findsNothing);
  });

  testWidgets('a failed save keeps the dialog open with the error', (
    tester,
  ) async {
    // GIVEN
    await givenDialogIsOpen(
      tester,
      (context) => showCourseExceptionsDialog(
        context: context,
        courseExceptions: holidays,
        onConfirm: (_, _) async => 'Could not save cancellations.',
      ),
    );

    // WHEN
    await removeFirstDateAndConfirm(tester);

    // THEN
    expect(find.text('Cancellations'), findsOneWidget);
    expect(find.text('Could not save cancellations.'), findsOneWidget);
    expect(find.byTooltip('Remove'), findsOneWidget);
  });

  testWidgets('with schedules, each date shows its scope and saves to it', (
    tester,
  ) async {
    // GIVEN
    Map<int, List<DateTime>>? savedSchedules;
    await givenDialogIsOpen(
      tester,
      (context) => showCourseExceptionsDialog(
        context: context,
        courseExceptions: [DateTime(2026, 11, 26)],
        scheduleLabels: const {1: 'Mon, Wed 9:00 AM - 9:50 AM', 2: 'Wed 2:00 PM - 3:50 PM'},
        scheduleExceptions: {
          2: [DateTime(2026, 11, 18)],
        },
        onConfirm: (_, scheduleExceptions) async {
          savedSchedules = scheduleExceptions;
          return null;
        },
      ),
    );

    // WHEN
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    await confirm(tester);

    // THEN
    expect(savedSchedules, {1: <DateTime>[], 2: <DateTime>[]});
  });

  testWidgets('with schedules, rows label all-meeting and per-meeting dates', (
    tester,
  ) async {
    // GIVEN
    await givenDialogIsOpen(
      tester,
      (context) => showCourseExceptionsDialog(
        context: context,
        courseExceptions: [DateTime(2026, 11, 26)],
        scheduleLabels: const {1: 'Mon, Wed 9:00 AM - 9:50 AM', 2: 'Wed 2:00 PM - 3:50 PM'},
        scheduleExceptions: {
          2: [DateTime(2026, 11, 18)],
        },
        courseGroupExceptions: [DateTime(2026, 11, 27)],
        onConfirm: (_, _) async => null,
      ),
    );

    // THEN
    expect(find.text('Wed 2:00 PM - 3:50 PM'), findsOneWidget);
    expect(find.text('All meetings'), findsOneWidget);
    expect(find.text('Also cancelled via Holidays & Breaks'), findsOneWidget);
  });
}
