import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/contrast_service.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';

const double _wcagAaTextMinimum = 4.5;
const double _wcagAaLargeTextMinimum = 3.0;
const double _wcagAaNonTextMinimum = 3.0;

bool _isLargeText(TextStyle style) {
  final size = style.fontSize ?? 14;
  final bold = (style.fontWeight?.value ?? FontWeight.w400.value) >= FontWeight.w700.value;
  return size >= 18 || (bold && size >= 14);
}

Map<String, TextStyle> _stylesOnSurface(BuildContext context) => {
      'standardBodyText': AppStyles.standardBodyText(context),
      'standardBodyTextLight': AppStyles.standardBodyTextLight(context),
      'headingText': AppStyles.headingText(context),
      'featureText': AppStyles.featureText(context),
      'smallSecondaryText': AppStyles.smallSecondaryText(context),
      'smallSecondaryTextLight': AppStyles.smallSecondaryTextLight(context),
      'pageTitle': AppStyles.pageTitle(context),
      'formText': AppStyles.formText(context),
      'formLabel': AppStyles.formLabel(context),
      'formHint': AppStyles.formHint(context),
      'formErrorStyle': AppStyles.formErrorStyle(context),
      'menuItem': AppStyles.menuItem(context),
      'menuItemHint': AppStyles.menuItemHint(context),
      'calendarItemText': AppStyles.calendarItemText(context),
      'calendarItemTextLight': AppStyles.calendarItemTextLight(context),
    };

Future<BuildContext> _pumpTheme(WidgetTester tester, ThemeData theme) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final mode in ['light', 'dark']) {
    group('$mode theme', () {
      final theme = mode == 'light' ? AppTheme.light() : AppTheme.dark();

      testWidgets('every AppStyles text style reads at WCAG AA on the surface', (tester) async {
        final context = await _pumpTheme(tester, theme);
        final surface = theme.colorScheme.surface;

        for (final entry in _stylesOnSurface(context).entries) {
          final minimum = _isLargeText(entry.value) ? _wcagAaLargeTextMinimum : _wcagAaTextMinimum;
          expect(
            HeliumColors.contrastRatio(entry.value.color!, surface),
            greaterThanOrEqualTo(minimum),
            reason: '${entry.key} on surface in $mode',
          );
        }
      });

      testWidgets('muted text and icon alphas read at WCAG AA on the surface', (tester) async {
        final onSurface = theme.colorScheme.onSurface;
        final surface = theme.colorScheme.surface;

        expect(
          HeliumColors.contrastRatio(onSurface.withValues(alpha: AppStyles.mutedTextAlpha), surface),
          greaterThanOrEqualTo(_wcagAaTextMinimum),
          reason: 'mutedTextAlpha in $mode',
        );
        expect(
          HeliumColors.contrastRatio(onSurface.withValues(alpha: AppStyles.mutedIconAlpha), surface),
          greaterThanOrEqualTo(_wcagAaNonTextMinimum),
          reason: 'mutedIconAlpha in $mode',
        );
      });

      testWidgets('without Increase Contrast, buttons keep the brand primary and its default label color',
          (tester) async {
        final colorScheme = theme.colorScheme;

        expect(AppTheme.onPrimaryText(colorScheme), colorScheme.onPrimary);
        expect(AppTheme.primaryText(colorScheme), colorScheme.primary);
        expect(colorScheme.primary, mode == 'light' ? seedColor : const Color(0xff5aa2c2));
      });

      testWidgets('with Increase Contrast on, button labels read at WCAG AA without moving the brand primary',
          (tester) async {
        ContrastService().init(true);
        addTearDown(() => ContrastService().init(false));
        final context = await _pumpTheme(tester, theme);
        final colorScheme = theme.colorScheme;

        expect(
          HeliumColors.contrastRatio(AppStyles.buttonText(context).color!, colorScheme.primary),
          greaterThanOrEqualTo(_wcagAaTextMinimum),
          reason: 'label on filled buttons in $mode',
        );
        expect(
          HeliumColors.contrastRatio(AppTheme.primaryText(colorScheme), colorScheme.surface),
          greaterThanOrEqualTo(_wcagAaTextMinimum),
          reason: 'text/outlined button labels on surface in $mode',
        );
        expect(
          HeliumColors.contrastRatio(colorScheme.primary, colorScheme.surface),
          greaterThanOrEqualTo(_wcagAaNonTextMinimum),
          reason: 'brand primary as an icon or control on surface in $mode',
        );
        expect(
          HeliumColors.contrastRatio(colorScheme.error, colorScheme.surface),
          greaterThanOrEqualTo(_wcagAaTextMinimum),
          reason: 'error as text on surface in $mode',
        );
      });

      testWidgets('without Increase Contrast, tile text keeps the brand rule (white on mid-tone colors)',
          (tester) async {
        expect(ContrastService().increaseContrast, isFalse);
        expect(FallbackConstants.defaultEventsColor.contrasting, Colors.white);
        expect(PlannerTypeColors.homework.contrasting, Colors.white);
      });

      testWidgets('with Increase Contrast on, text on every palette color reads at WCAG AA on tiles and badges',
          (tester) async {
        ContrastService().init(true);
        addTearDown(() => ContrastService().init(false));
        final context = await _pumpTheme(tester, theme);

        for (final color in HeliumColors.preferredColors) {
          final hex = color.toARGB32().toRadixString(16);
          expect(
            HeliumColors.contrastRatio(color.contrasting, color),
            greaterThanOrEqualTo(_wcagAaTextMinimum),
            reason: 'tile text on $hex in $mode',
          );
          expect(
            HeliumColors.contrastRatio(
              BadgeColors.foreground(context, color),
              BadgeColors.background(context, color),
            ),
            greaterThanOrEqualTo(_wcagAaTextMinimum),
            reason: 'badge text on $hex in $mode',
          );
        }
      });
    });
  }
}
