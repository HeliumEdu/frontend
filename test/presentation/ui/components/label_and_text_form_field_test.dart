import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_picker_field.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/utils/app_style.dart';

void main() {
  final boundaryKey = GlobalKey();

  Future<void> pumpField(WidgetTester tester, Widget field, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: const Size(800, 300), textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: RepaintBoundary(key: boundaryKey, child: field),
            ),
          ),
        ),
      ),
    );
  }

  Rect boxOf(WidgetTester tester, Finder field) =>
      tester.getRect(find.descendant(of: field, matching: find.byType(DecoratedBox)).first);

  Rect textFieldOf(WidgetTester tester) => tester.getRect(find.byType(InputDecorator));

  Future<List<int>> rowsPainted(WidgetTester tester, Color color, int x) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final rows = <int>[];
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      for (var y = 0; y < image.height; y++) {
        final i = (y * image.width + x) * 4;
        final pixel = Color.fromARGB(255, bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
        if (pixel.toARGB32() == color.withAlpha(255).toARGB32()) rows.add(y);
      }
    });
    return rows;
  }

  for (final textScale in [1.0, 0.8, 1.3]) {
    testWidgets('a single-line field is 48 tall with its text centered at text scale $textScale', (tester) async {
      // GIVEN
      await pumpField(
        tester,
        LabelAndTextFormField(hintText: 'Title', controller: TextEditingController(text: 'Hello')),
        textScale: textScale,
      );

      // WHEN
      final box = textFieldOf(tester);
      final text = tester.getRect(find.byType(EditableText));

      // THEN
      expect(box.height, AppStyles.formFieldHeight);
      expect(text.center.dy, closeTo(box.center.dy, 0.5),
          reason: 'the text should sit at the vertical center of the bordered box');
    });
  }

  testWidgets('the hover fill covers the whole box inside its border', (tester) async {
    // GIVEN
    await pumpField(
      tester,
      LabelAndTextFormField(hintText: 'Title', controller: TextEditingController(text: 'Hello')),
      textScale: 0.8,
    );
    final box = textFieldOf(tester);
    final theme = AppTheme.dark();
    final hoverFill = Color.alphaBlend(theme.hoverColor, theme.inputDecorationTheme.fillColor!);

    // WHEN
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset(box.right - 40, box.center.dy));
    await tester.pumpAndSettle();
    final rows = await rowsPainted(tester, hoverFill, (box.right - 8 - 40).toInt());

    // THEN
    expect(rows.first, (box.top - 8 + AppStyles.formFieldBorderWidth).toInt());
    expect(rows.last, (box.bottom - 8 - AppStyles.formFieldBorderWidth - 1).toInt(),
        reason: 'the fill should reach the bottom border, not stop at the text');
  });

  testWidgets('an error shows below the field, which keeps its height', (tester) async {
    // GIVEN
    await pumpField(tester, const LabelAndTextFormField(hintText: 'Title', errorText: 'This field is required'));

    // WHEN
    final field = textFieldOf(tester);
    final input = tester.getRect(find.byType(EditableText));
    final error = tester.getRect(find.text('This field is required'));

    // THEN
    expect(error.top, greaterThanOrEqualTo(field.top + AppStyles.formFieldHeight));
    expect(input.center.dy, closeTo(field.top + AppStyles.formFieldHeight / 2, 0.5),
        reason: 'the error shouldn\'t move the text off the center of the bordered box');
  });

  testWidgets('a read-only field is filled with the read-only surface color', (tester) async {
    // GIVEN
    await pumpField(tester, const LabelAndTextFormField(initialValue: 'student@example.com', readOnly: true));

    // WHEN
    final decoration = tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

    // THEN
    expect(decoration.fillColor, AppTheme.dark().colorScheme.surfaceContainerHighest);
  });

  testWidgets('a text field matches the spinner and date picker heights', (tester) async {
    // GIVEN
    await pumpField(
      tester,
      Column(
        children: [
          LabelAndTextFormField(hintText: 'Title', controller: TextEditingController()),
          SpinnerField(controller: TextEditingController(text: '1')),
          HeliumDateField(date: DateTime(2026, 11, 17), onTap: () {}),
        ],
      ),
    );

    // WHEN
    final text = tester
        .getRect(find.descendant(of: find.byType(LabelAndTextFormField), matching: find.byType(InputDecorator)))
        .height;
    final spinner = tester
        .getRect(find.descendant(of: find.byType(SpinnerField), matching: find.byType(InputDecorator)))
        .height;
    final picker = boxOf(tester, find.byType(HeliumDateField)).height;

    // THEN
    expect(text, AppStyles.formFieldHeight);
    expect(spinner, AppStyles.formFieldHeight);
    expect(picker, AppStyles.formFieldHeight);
  });
}
