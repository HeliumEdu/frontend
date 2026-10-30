import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size screen,
    required NotesEditorLayout layout,
  }) async {
    tester.view.physicalSize = screen * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [HeliumQuillLocalizationsDelegate()],
        home: Scaffold(
          body: layout == NotesEditorLayout.page
              ? NotesEditor(
                  layout: layout,
                  controller: QuillController.basic(),
                  onPrint: () {},
                )
              : SingleChildScrollView(
                  child: NotesEditor(
                    layout: layout,
                    controller: QuillController.basic(),
                    onOpenInNotebook: () {},
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  HeliumQuillToolbar toolbar(WidgetTester tester) =>
      tester.widget(find.byType(HeliumQuillToolbar));

  const phone = Size(393, 852);
  const desktop = Size(1280, 800);

  group('NotesEditor embedded', () {
    testWidgets(
      'on phones, shows the minimal toolbar under the "Notes" label',
      (tester) async {
        // WHEN
        await pumpEditor(
          tester,
          screen: phone,
          layout: NotesEditorLayout.embedded,
        );

        // THEN
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('Open in Notebook'), findsOneWidget);
        expect(toolbar(tester).density, HeliumToolbarDensity.minimal);
        expect(find.byType(QuillToolbarDivider), findsNothing);
        expect(toolbar(tester).groups.expand((group) => group), [
          HeliumToolbarButton.undo,
          HeliumToolbarButton.bold,
          HeliumToolbarButton.italic,
          HeliumToolbarButton.bulletedList,
          HeliumToolbarButton.numberedList,
          HeliumToolbarButton.checklist,
          HeliumToolbarButton.link,
        ]);
      },
    );

    testWidgets(
      'on wider screens, shows the full toolbar with its groups divided',
      (tester) async {
        // WHEN
        await pumpEditor(
          tester,
          screen: desktop,
          layout: NotesEditorLayout.embedded,
        );

        // THEN
        expect(toolbar(tester).density, HeliumToolbarDensity.full);
        expect(toolbar(tester).groups, [
          [
            HeliumToolbarButton.undo,
            HeliumToolbarButton.redo,
            HeliumToolbarButton.bold,
            HeliumToolbarButton.italic,
            HeliumToolbarButton.underline,
            HeliumToolbarButton.strikeThrough,
            HeliumToolbarButton.color,
            HeliumToolbarButton.clearFormat,
          ],
          [
            HeliumToolbarButton.bulletedList,
            HeliumToolbarButton.numberedList,
            HeliumToolbarButton.checklist,
            HeliumToolbarButton.indentIncrease,
            HeliumToolbarButton.indentDecrease,
          ],
          [HeliumToolbarButton.fontFamily],
          [HeliumToolbarButton.quote, HeliumToolbarButton.link],
        ]);
        expect(find.byType(QuillToolbarDivider), findsNWidgets(3));
        expect(find.byIcon(Icons.print_outlined), findsNothing);
      },
    );
  });

  group('NotesEditor page', () {
    testWidgets('on phones, collapses the toolbar behind "more"', (
      tester,
    ) async {
      // WHEN
      await pumpEditor(tester, screen: phone, layout: NotesEditorLayout.page);

      // THEN
      expect(toolbar(tester).density, HeliumToolbarDensity.compact);
      expect(find.byType(QuillToolbarDivider), findsNothing);
      expect(toolbar(tester).groups.expand((group) => group), [
        HeliumToolbarButton.undo,
        HeliumToolbarButton.bold,
        HeliumToolbarButton.italic,
        HeliumToolbarButton.backgroundColor,
        HeliumToolbarButton.bulletedList,
        HeliumToolbarButton.numberedList,
        HeliumToolbarButton.checklist,
        HeliumToolbarButton.headerStyle,
        HeliumToolbarButton.quote,
        HeliumToolbarButton.link,
        HeliumToolbarButton.print,
        HeliumToolbarButton.search,
      ]);
      expect(find.byIcon(Icons.expand_more).hitTestable(), findsOneWidget);
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets(
      'on wider screens, shows the full toolbar with find and print',
      (tester) async {
        // WHEN
        await pumpEditor(
          tester,
          screen: desktop,
          layout: NotesEditorLayout.page,
        );

        // THEN
        expect(toolbar(tester).density, HeliumToolbarDensity.full);
        expect(toolbar(tester).groups, [
          [
            HeliumToolbarButton.undo,
            HeliumToolbarButton.redo,
            HeliumToolbarButton.bold,
            HeliumToolbarButton.italic,
            HeliumToolbarButton.underline,
            HeliumToolbarButton.strikeThrough,
            HeliumToolbarButton.inlineCode,
            HeliumToolbarButton.subscript,
            HeliumToolbarButton.superscript,
            HeliumToolbarButton.color,
            HeliumToolbarButton.backgroundColor,
            HeliumToolbarButton.clearFormat,
          ],
          [
            HeliumToolbarButton.bulletedList,
            HeliumToolbarButton.numberedList,
            HeliumToolbarButton.checklist,
            HeliumToolbarButton.indentIncrease,
            HeliumToolbarButton.indentDecrease,
          ],
          [
            HeliumToolbarButton.headerStyle,
            HeliumToolbarButton.fontFamily,
            HeliumToolbarButton.fontSize,
          ],
          [
            HeliumToolbarButton.quote,
            HeliumToolbarButton.codeBlock,
            HeliumToolbarButton.link,
          ],
          [HeliumToolbarButton.alignment],
          [HeliumToolbarButton.print, HeliumToolbarButton.search],
        ]);
        expect(find.byType(QuillToolbarDivider), findsNWidgets(5));
        expect(find.byIcon(Icons.print_outlined).hitTestable(), findsOneWidget);
        expect(find.byType(QuillToolbarSearchButton), findsOneWidget);
      },
    );

    testWidgets('opens and closes the find bar from the toolbar', (
      tester,
    ) async {
      // GIVEN
      await pumpEditor(tester, screen: desktop, layout: NotesEditorLayout.page);

      // WHEN
      await tester.tap(find.byType(QuillToolbarSearchButton));
      await tester.pumpAndSettle();

      // THEN
      expect(find.byType(QuillSearchBar), findsOneWidget);
    });
  });

  testWidgets('every toolbar keeps the order of the Notebook\'s web toolbar', (
    tester,
  ) async {
    // GIVEN
    Future<List<HeliumToolbarButton>> buttonsOf(
      Size screen,
      NotesEditorLayout layout,
    ) async {
      await pumpEditor(tester, screen: screen, layout: layout);
      return toolbar(tester).groups.expand((group) => group).toList();
    }

    final master = await buttonsOf(desktop, NotesEditorLayout.page);

    // WHEN
    final subsets = {
      'Notebook, phone': await buttonsOf(phone, NotesEditorLayout.page),
      'linked notes, web': await buttonsOf(desktop, NotesEditorLayout.embedded),
      'linked notes, phone': await buttonsOf(phone, NotesEditorLayout.embedded),
    };

    // THEN
    for (final MapEntry(key: name, value: buttons) in subsets.entries) {
      final positions = [for (final button in buttons) master.indexOf(button)];
      expect(
        positions,
        isNot(contains(-1)),
        reason: '$name only uses buttons the web toolbar has',
      );
      expect(
        positions,
        orderedEquals([...positions]..sort()),
        reason: '$name keeps the web toolbar\'s order',
      );
    }
  });
}
