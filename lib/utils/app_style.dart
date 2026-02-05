// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

extension AppStyles on BuildContext {
  // Fallback font for characters not in Poppins (e.g., bullet •)
  static const fallbackFonts = ['Noto Sans'];

  /// Creates a Poppins TextStyle with Noto Sans fallback for missing characters.
  /// Use this instead of GoogleFonts.poppins() throughout the app.
  static TextStyle poppins({
    FontWeight? fontWeight,
    double? fontSize,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.poppins(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      fontFeatures: fontFeatures,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }

  static TextTheme defaultTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamilyFallback: fallbackFonts,
    );
  }

  // Used for body text, descriptions, secondary info
  static TextStyle standardBodyText(BuildContext context) => poppins(
    fontWeight: FontWeight.w500,
    fontSize: Responsive.getFontSize(
      context,
      mobile: 13,
      tablet: 14,
      desktop: 15,
    ),
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for secondary text with a lighter weight (like prominent calendar data)
  static TextStyle standardBodyTextLight(BuildContext context) {
    final base = standardBodyText(context);
    return poppins(
      fontWeight: FontWeight.w300,
      fontSize: base.fontSize,
      color: base.color,
      fontFeatures: base.fontFeatures,
    );
  }

  // Used for primary headings, important UI text
  static TextStyle headingText(BuildContext context) => poppins(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.getFontSize(context, mobile: 15, desktop: 16),
    color: Theme.of(context).colorScheme.onSurface,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for large featured text (prominent numbers, key metrics, callouts)
  static TextStyle featureText(BuildContext context) =>
      GoogleFonts.dmSerifDisplay(
        fontWeight: FontWeight.w400,
        fontSize: Responsive.getFontSize(context, mobile: 18, desktop: 19),
        color: Theme.of(context).colorScheme.onSurface,
        fontFeatures: [const FontFeature.tabularFigures()],
      ).copyWith(fontFamilyFallback: fallbackFonts);

  // Used for smaller labels, counts, tertiary info
  static TextStyle smallSecondaryText(BuildContext context) => poppins(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.getFontSize(context, mobile: 12, desktop: 13),
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for secondary text with a lighter weight (like on the calendar)
  static TextStyle smallSecondaryTextLight(BuildContext context) {
    final base = smallSecondaryText(context);
    return poppins(
      fontWeight: FontWeight.w300,
      fontSize: base.fontSize,
      color: base.color,
      fontFeatures: base.fontFeatures,
    );
  }

  // Used for responsive button text
  static TextStyle buttonText(BuildContext context) => poppins(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.getFontSize(context, mobile: 15, desktop: 16),
    color: Theme.of(context).colorScheme.onPrimary,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for page and dialog titles
  static TextStyle pageTitle(BuildContext context) =>
      GoogleFonts.dmSerifDisplay(
        fontWeight: FontWeight.w400,
        fontSize: Responsive.getFontSize(
          context,
          mobile: 18,
          tablet: 20,
          desktop: 22,
        ),
        color: Theme.of(context).colorScheme.onSurface,
        fontFeatures: [const FontFeature.tabularFigures()],
      ).copyWith(fontFamilyFallback: fallbackFonts);

  // Used for dropdowns, text fields, and form elements
  static TextStyle formText(BuildContext context) => poppins(
    fontSize: Responsive.getFontSize(context, mobile: 14, desktop: 15),
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for form field labels
  static TextStyle formLabel(BuildContext context) =>
      formText(context).copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      );

  // Used for form field placeholder/hint text
  static TextStyle formHint(BuildContext context) => formText(context).copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
  );

  // Used for form validation error messages
  static TextStyle formErrorStyle(BuildContext context) => formText(
    context,
  ).copyWith(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9));

  // Used for menu items and popup menu text
  static TextStyle menuItem(BuildContext context) => poppins(
    fontSize: Responsive.getFontSize(context, mobile: 14, desktop: 15),
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // Used for menu item hints
  static TextStyle menuItemHint(BuildContext context) =>
      menuItem(context).copyWith(
        fontSize: Responsive.getFontSize(context, mobile: 12, desktop: 13),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      );

  // Used for active menu items
  static TextStyle menuItemActive(BuildContext context) =>
      menuItem(context).copyWith(color: Theme.of(context).colorScheme.primary);

  // Used for responsive scaling of calendar item prefixes (checkboxes, icons)
  static double calendarItemPrefixScale(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.mobile:
        return 0.8;
    }
  }
}
