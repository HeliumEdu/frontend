// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

extension AppTextStyles on BuildContext {
  // Used for smaller labels, counts, secondary info
  static TextStyle smallSecondaryText(BuildContext context) =>
      GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: Responsive.getFontSize(
          context,
          mobile: 11,
          tablet: 12,
          desktop: 13,
        ),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
      );

  // Used for body text, descriptions, secondary info
  static TextStyle standardBodyText(BuildContext context) =>
      GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: Responsive.getFontSize(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 14,
        ),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
      );

  // Used for primary headings, important UI text
  static TextStyle headingText(BuildContext context) => GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontSize: Responsive.getFontSize(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    ),
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Used for large featured text (prominent numbers, key metrics, callouts)
  static TextStyle featureText(BuildContext context) => GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.getFontSize(
      context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    ),
    color: Theme.of(context).colorScheme.onSurface,
  );

  // Used for schedule day-selection button text (course add screen only)
  static TextStyle scheduleButtonText(BuildContext context) =>
      GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: Responsive.getFontSize(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
        color: Theme.of(context).colorScheme.onSurface,
      );

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

  // Used for main page titles in app bars (auth screens, page headers)
  TextStyle get pageTitle => GoogleFonts.roboto(
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for major section headings within pages ("Categories", "Reminders", etc.)
  TextStyle get sectionHeading => GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for general body/paragraph text where more specific styles don't apply
  TextStyle get bodyText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  // Used for dialog and modal title text
  TextStyle get dialogTitle => GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 22,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for dialog and modal body content
  TextStyle get dialogText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Base style for form input text (parent for formLabel, formHint, formErrorStyle)
  // Also used directly in dropdowns, text fields, and form elements
  TextStyle get formText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  // Used for form field labels (derived from formText with reduced opacity)
  TextStyle get formLabel => formText.copyWith(
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  // Used for form field placeholder/hint text (derived from formText with minimal opacity)
  TextStyle get formHint => formText.copyWith(
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.5),
  );

  // Used for form validation error messages (derived from formText with error color)
  TextStyle get formErrorStyle => formText.copyWith(
    fontSize: 14,
    color: Theme.of(this).colorScheme.error.withValues(alpha: 0.9),
  );

  // Used for text inside primary elevated buttons
  TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(this).colorScheme.onPrimary,
  );

  // Used for settings menu item titles
  TextStyle get settingsMenuItem => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for descriptive hint text below settings menu items
  TextStyle get settingsMenuItemHint => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  // Used for calendar filter menu items and popup menu text
  TextStyle get calendarMenuItem => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  // Used for date display in calendar views
  TextStyle get calendarDate => GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: Theme.of(this).colorScheme.primary,
  );

  // Used for calendar item text content (uses responsive sizing from smallSecondaryText)
  TextStyle get calendarData => GoogleFonts.poppins(
    fontWeight: FontWeight.w300,
    fontSize: AppTextStyles.smallSecondaryText(this).fontSize,
    color: Colors.white,
  );

  // Used for calendar column headers (days of week, time labels, etc.)
  TextStyle get calendarHeader => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for inactive stepper step titles
  TextStyle get stepperTitle => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(this).colorScheme.onSurface,
  );

  // Used for active stepper step titles (derives from stepperTitle with primary color)
  TextStyle get stepperTitleActive =>
      stepperTitle.copyWith(color: Theme.of(this).colorScheme.primary);
}
