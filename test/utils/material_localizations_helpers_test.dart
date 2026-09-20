import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/material_localizations_helpers.dart';

void main() {
  Widget buildApp(int firstDayOfWeekIndex) {
    return MaterialApp(
      localizationsDelegates: [
        HeliumMaterialLocalizationsDelegate(firstDayOfWeekIndex: firstDayOfWeekIndex, dateFormat: 0),
      ],
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDatePicker(
            context: context,
            initialDate: DateTime(2026, 9, 4),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }

  Future<List<String>> weekdayHeaders(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return tester
        .widgetList<Text>(find.descendant(of: find.byType(CalendarDatePicker), matching: find.byType(Text)))
        .map((text) => text.data ?? '')
        .where((data) => data.length == 1)
        .take(7)
        .toList();
  }

  group('HeliumMaterialLocalizationsDelegate', () {
    testWidgets('overrides the default first day of week for date pickers', (tester) async {
      // GIVEN
      await tester.pumpWidget(buildApp(1));

      // WHEN
      final headers = await weekdayHeaders(tester);

      // THEN
      expect(headers, ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });

    testWidgets('keeps Sunday first when the setting is Sunday', (tester) async {
      // GIVEN
      await tester.pumpWidget(buildApp(0));

      // WHEN
      final headers = await weekdayHeaders(tester);

      // THEN
      expect(headers, ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
    });

    testWidgets('reloads when the first day of week changes', (tester) async {
      // GIVEN
      await tester.pumpWidget(buildApp(0));

      // WHEN
      await tester.pumpWidget(buildApp(6));
      final headers = await weekdayHeaders(tester);

      // THEN
      expect(headers, ['S', 'S', 'M', 'T', 'W', 'T', 'F']);
    });
  });

  group('RegionalFormatScope', () {
    Widget buildScope(bool alwaysUse24HourFormat) {
      return MaterialApp(
        builder: (context, child) => RegionalFormatScope(
          alwaysUse24HourFormat: alwaysUse24HourFormat,
          child: child!,
        ),
        home: Builder(
          builder: (context) => Text(const TimeOfDay(hour: 15, minute: 0).format(context)),
        ),
      );
    }

    testWidgets('formats Material times on a 24-hour clock', (tester) async {
      // GIVEN
      await tester.pumpWidget(buildScope(true));

      // THEN
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('formats Material times on a 12-hour clock', (tester) async {
      // GIVEN
      await tester.pumpWidget(buildScope(false));

      // THEN
      expect(find.text('3:00 PM'), findsOneWidget);
    });
  });

  group('HeliumMaterialLocalizations', () {
    final date = DateTime(2026, 9, 4);
    HeliumMaterialLocalizations forOrder(int dateFormat) =>
        HeliumMaterialLocalizations(firstDayOfWeekIndex: 0, dateFormat: dateFormat);

    test('month/day/year keeps Material defaults', () {
      final localizations = forOrder(RegionalFormatConstants.dateFormatMonthDayYear);
      expect(localizations.formatMediumDate(date), 'Fri, Sep 4');
      expect(localizations.formatFullDate(date), 'Friday, September 4, 2026');
      expect(localizations.formatCompactDate(date), '09/04/2026');
      expect(localizations.dateHelpText, 'mm/dd/yyyy');
      expect(localizations.parseCompactDate('09/04/2026'), date);
    });

    test('day/month/year reads day-first and parses day-first', () {
      final localizations = forOrder(RegionalFormatConstants.dateFormatDayMonthYear);
      expect(localizations.formatMediumDate(date), 'Fri, 4 Sep');
      expect(localizations.formatShortDate(date), '4 Sep 2026');
      expect(localizations.formatCompactDate(date), '04/09/2026');
      expect(localizations.dateHelpText, 'dd/mm/yyyy');
      expect(localizations.parseCompactDate('04/09/2026'), date);
      expect(localizations.parseCompactDate('31/02/2026'), isNull);
    });

    testWidgets('date picker header follows the regional order', (tester) async {
      // GIVEN
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          HeliumMaterialLocalizationsDelegate(
            firstDayOfWeekIndex: 1,
            dateFormat: RegionalFormatConstants.dateFormatDayMonthYear,
          ),
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 9, 4),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      // WHEN
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // THEN
      expect(find.text('Fri, 4 Sep'), findsOneWidget);
    });
  });
}
