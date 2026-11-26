import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_picker_field.dart';
import 'package:heliumapp/presentation/ui/components/helium_search_field.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/presentation/ui/components/searchable_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

void main() {
  final items = [
    DropDownItem<int>(id: 1, value: 1, label: 'Fall'),
    DropDownItem<int>(id: 2, value: 2, label: 'Spring'),
  ];
  final date = DateTime(2026, 11, 17);
  final fields = <String, ({Widget Function() build, String? typedText, String? shownText})>{
    'LabelAndTextFormField': (
      build: () => LabelAndTextFormField(controller: TextEditingController(text: '42')),
      typedText: null,
      shownText: null,
    ),
    'SpinnerField': (
      build: () => SpinnerField(controller: TextEditingController(text: '42')),
      typedText: null,
      shownText: null,
    ),
    'DropDown': (
      build: () => DropDown<int>(items: items, initialValue: items.last, onChanged: (_) {}),
      typedText: null,
      shownText: items.last.label,
    ),
    'SearchableDropdown': (
      build: () => SearchableDropdown<int>(items: items, initialValue: items.last, onChanged: (_) {}),
      typedText: null,
      shownText: null,
    ),
    'QuillSearchBar': (
      build: () => QuillSearchBar(controller: QuillController.basic(), onClose: () {}),
      typedText: '42',
      shownText: null,
    ),
    'HeliumSearchField': (
      build: () => HeliumSearchField(controller: TextEditingController(), onChanged: (_) {}),
      typedText: '42',
      shownText: null,
    ),
    'HeliumDateField': (
      build: () => HeliumDateField(date: date, onTap: () {}),
      typedText: null,
      shownText: HeliumDateTime.formatDate(date),
    ),
  };
  final densities = {'standard': VisualDensity.standard, 'compact': VisualDensity.compact};

  Future<void> pumpField(
    WidgetTester tester,
    Widget field, {
    required VisualDensity density,
    required double textScale,
  }) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark().copyWith(visualDensity: density),
        home: MediaQuery(
          data: MediaQueryData(size: const Size(800, 300), textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Padding(padding: const EdgeInsets.all(8), child: field),
          ),
        ),
      ),
    );
  }

  Rect globalRectOf(RenderBox text, List<TextBox> boxes) => MatrixUtils.transformRect(
    text.getTransformTo(null),
    boxes.map((box) => box.toRect()).reduce((a, b) => a.expandToInclude(b)),
  );

  Rect renderedTextOf(WidgetTester tester, String? shownText) {
    if (shownText != null) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(shownText));
      return globalRectOf(
        paragraph,
        paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: shownText.length)),
      );
    }
    final editableText = find.byType(EditableText);
    final input = tester.state<EditableTextState>(editableText).renderEditable;
    return globalRectOf(
      input,
      input.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: input.plainText.length)),
    );
  }

  for (final MapEntry(key: name, value: field) in fields.entries) {
    for (final MapEntry(key: densityName, value: density) in densities.entries) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets('$name centers its text at $densityName density and text scale $textScale', (tester) async {
          // GIVEN
          await pumpField(tester, field.build(), density: density, textScale: textScale);
          if (field.typedText != null) {
            await tester.enterText(find.byType(EditableText), field.typedText!);
            await tester.pump(const Duration(seconds: 1));
          }

          // WHEN
          final box = tester.getRect(find.byType(InputDecorator));
          final text = renderedTextOf(tester, field.shownText);

          // THEN
          expect(text.center.dy, closeTo(box.center.dy, 1),
              reason: 'the rendered text should sit at the vertical center of the field box');
        });
      }
    }
  }

  for (final name in [
    'LabelAndTextFormField',
    'SpinnerField',
    'DropDown',
    'SearchableDropdown',
    'HeliumSearchField',
    'HeliumDateField',
  ]) {
    testWidgets('$name draws the shared form field outline in every state', (tester) async {
      // GIVEN
      await pumpField(tester, fields[name]!.build(), density: VisualDensity.standard, textScale: 1);

      // WHEN
      final decoration = tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final shared = AppStyles.formFieldDecoration(tester.element(find.byType(InputDecorator)));

      // THEN
      for (final border in [
        decoration.border,
        decoration.enabledBorder,
        decoration.focusedBorder,
        decoration.disabledBorder,
        decoration.errorBorder,
        decoration.focusedErrorBorder,
      ]) {
        expect(border, shared.enabledBorder, reason: 'every field state should use the shared outline');
      }
      expect(decoration.contentPadding?.horizontal, shared.contentPadding?.horizontal,
          reason: 'text should start at the shared content inset');
    });
  }
}
