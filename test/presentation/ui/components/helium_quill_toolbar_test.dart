import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

const _iconButtons = [
  HeliumToolbarButton.undo,
  HeliumToolbarButton.bold,
  HeliumToolbarButton.italic,
  HeliumToolbarButton.bulletedList,
  HeliumToolbarButton.numberedList,
  HeliumToolbarButton.checklist,
  HeliumToolbarButton.link,
  HeliumToolbarButton.color,
  HeliumToolbarButton.quote,
  HeliumToolbarButton.search,
  HeliumToolbarButton.print,
];

void main() {
  Future<void> pumpToolbar(
    WidgetTester tester, {
    required double width,
    required HeliumToolbarDensity density,
    required List<List<HeliumToolbarButton>> groups,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [HeliumQuillLocalizationsDelegate()],
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: HeliumQuillToolbar(
                controller: QuillController.basic(),
                density: density,
                groups: groups,
                onSearch: () {},
                onPrint: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder toggle(IconData icon) => find.byIcon(icon).hitTestable();

  group('HeliumQuillToolbar compact', () {
    testWidgets('shows one row of what fits, ending in "more"', (tester) async {
      // WHEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.compact,
        groups: [_iconButtons],
      );

      // THEN
      expect(
        tester.getSize(find.byType(HeliumQuillToolbar)).height,
        48,
        reason: 'one 40pt row with 4pt above and below',
      );
      expect(toggle(Icons.expand_more), findsOneWidget);
      expect(
        find.byIcon(Icons.print_outlined).hitTestable(),
        findsNothing,
        reason: 'print is past the fold',
      );
      expect(
        tester.getTopRight(find.byIcon(Icons.expand_more)).dx,
        greaterThan(tester.getTopRight(find.byIcon(Icons.link)).dx),
        reason: 'the toggle ends the first row',
      );
    });

    testWidgets('expands to every button, with "less" in the same spot', (
      tester,
    ) async {
      // GIVEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.compact,
        groups: [_iconButtons],
      );
      final collapsedToggle = tester.getRect(find.byIcon(Icons.expand_more));

      // WHEN
      await tester.tap(toggle(Icons.expand_more));
      await tester.pumpAndSettle();

      // THEN
      expect(tester.getRect(find.byIcon(Icons.expand_less)), collapsedToggle);
      expect(find.byIcon(Icons.print_outlined).hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byType(HeliumQuillToolbar)).height,
        88,
        reason: 'two 40pt rows',
      );
    });

    testWidgets('centers each row', (tester) async {
      // GIVEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.compact,
        groups: [_iconButtons],
      );

      // WHEN
      await tester.tap(toggle(Icons.expand_more));
      await tester.pumpAndSettle();

      // THEN
      final toolbar = tester.getRect(find.byType(HeliumQuillToolbar));
      final secondRowLeft = tester
          .getRect(find.byType(QuillToolbarColorButton))
          .left;
      final secondRowRight = tester
          .getRect(find.byIcon(Icons.print_outlined))
          .right;
      expect(
        (secondRowLeft - toolbar.left) - (toolbar.right - secondRowRight),
        moreOrLessEquals(0, epsilon: 9),
        reason: 'the second row is centered (within a button\'s inner padding)',
      );
    });

    testWidgets(
      'measures wide buttons, like a dropdown, to fill the first row',
      (tester) async {
        // WHEN
        await pumpToolbar(
          tester,
          width: 377,
          density: HeliumToolbarDensity.compact,
          groups: [
            [HeliumToolbarButton.fontFamily, ..._iconButtons],
          ],
        );

        // THEN
        expect(
          tester.getSize(find.byType(HeliumQuillToolbar)).height,
          48,
          reason: 'the first row still fits one line',
        );
        expect(toggle(Icons.expand_more), findsOneWidget);
      },
    );

    testWidgets('shows every button without a toggle when they fit in a row', (
      tester,
    ) async {
      // WHEN
      await pumpToolbar(
        tester,
        width: 700,
        density: HeliumToolbarDensity.compact,
        groups: [_iconButtons],
      );

      // THEN
      expect(find.byIcon(Icons.print_outlined).hitTestable(), findsOneWidget);
      expect(toggle(Icons.expand_more), findsNothing);
    });
  });

  group('HeliumQuillToolbar minimal and full', () {
    testWidgets(
      'minimal shows its buttons in a centered row, without dividers or a toggle',
      (tester) async {
        // WHEN
        await pumpToolbar(
          tester,
          width: 377,
          density: HeliumToolbarDensity.minimal,
          groups: [
            [HeliumToolbarButton.undo, HeliumToolbarButton.bold],
            [HeliumToolbarButton.link],
          ],
        );

        // THEN
        final wrap = tester.widget<Wrap>(find.byType(Wrap).first);
        expect(wrap.alignment, WrapAlignment.center);
        expect(find.byType(QuillToolbarDivider), findsNothing);
        expect(find.byIcon(Icons.expand_more), findsNothing);
      },
    );

    testWidgets('full shows every button, with a divider between groups', (
      tester,
    ) async {
      // WHEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.full,
        groups: [
          [HeliumToolbarButton.undo, HeliumToolbarButton.bold],
          [],
          [HeliumToolbarButton.numberedList],
          [HeliumToolbarButton.link, HeliumToolbarButton.print],
        ],
      );

      // THEN
      expect(
        find.byType(QuillToolbarDivider),
        findsNWidgets(2),
        reason: 'one between each pair of non-empty groups',
      );
      expect(
        tester.getSize(find.byType(QuillToolbarDivider).first).height,
        kDefaultToolbarSize * 1.4,
        reason: 'as tall as Quill\'s own dividers',
      );
      expect(find.byIcon(Icons.print_outlined).hitTestable(), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });
  });

  group('toolbarRows with 40pt buttons and 1pt dividers', () {
    const widths = [40.0, 40.0, 1.0, 40.0, 40.0, 1.0, 40.0, 40.0];
    const dividers = [false, false, true, false, false, true, false, false];

    bool startsOrEndsWithDivider(List<int> row) {
      final items = row.where((index) => index >= 0).toList();
      return items.isNotEmpty &&
          (dividers[items.first] || dividers[items.last]);
    }

    test('puts everything in one row, without a toggle, when it fits', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 400,
        expanded: true,
      );

      // THEN
      expect(layout.fold, isNull);
      expect(layout.rows, [
        [0, 1, 2, 3, 4, 5, 6, 7],
      ]);
    });

    test('drops a divider that would sit just before the toggle', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 150,
        expanded: false,
      );

      // THEN
      expect(
        layout.fold,
        3,
        reason: '40 + 8 + 40 + 8 + 1 + 8 + 40 (toggle) = 145 fits in 150',
      );
      expect(layout.rows, [
        [0, 1, -1],
      ]);
    });

    test('opens into rows that never start or end with a divider', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 150,
        expanded: true,
      );

      // THEN
      expect(
        layout.rows.first.last,
        -1,
        reason: 'the toggle ends the first row',
      );
      expect(layout.rows.where(startsOrEndsWithDivider), isEmpty);
      expect(
        layout.rows
            .expand((row) => row)
            .where((index) => index >= 0 && !dividers[index])
            .length,
        6,
        reason: 'every button is shown',
      );
    });
  });

  group('HeliumQuillToolbar full when it wraps', () {
    const groups = [
      _iconButtons,
      [HeliumToolbarButton.numberedList],
    ];

    testWidgets('starts open, with "less" ending the first row', (
      tester,
    ) async {
      // WHEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.full,
        groups: groups,
      );

      // THEN
      expect(toggle(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.print_outlined).hitTestable(), findsOneWidget);
    });

    testWidgets('folds to one row', (tester) async {
      // GIVEN
      await pumpToolbar(
        tester,
        width: 377,
        density: HeliumToolbarDensity.full,
        groups: groups,
      );

      // WHEN
      await tester.tap(toggle(Icons.expand_less));
      await tester.pumpAndSettle();

      // THEN
      expect(tester.getSize(find.byType(HeliumQuillToolbar)).height, 48);
      expect(toggle(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.print_outlined).hitTestable(), findsNothing);
    });
  });
}
