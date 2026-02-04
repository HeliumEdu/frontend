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
  TextStyle get pageTitle => GoogleFonts.roboto(
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get sectionHeading => GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get dialogTitle => GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 22,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get dialogText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get formText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  TextStyle get formLabel => formText.copyWith(
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  TextStyle get formHint => formText.copyWith(
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.5),
  );

  TextStyle get formErrorStyle => formText.copyWith(
    fontSize: 14,
    color: Theme.of(this).colorScheme.error.withValues(alpha: 0.9),
  );

  TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(this).colorScheme.onPrimary,
  );

  TextStyle get menuItem => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  TextStyle get settingsMenuItem => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get settingsMenuItemHint => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  TextStyle get paragraphText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  TextStyle get calendarDate => GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: Theme.of(this).colorScheme.primary,
  );

  TextStyle get calendarData =>
      GoogleFonts.poppins(fontWeight: FontWeight.w300, color: Colors.white);

  static double calendarDataFontSize(BuildContext context) {
    return Responsive.getFontSize(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 13.0,
    );
  }

  static double calendarCheckboxScale(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.mobile:
        return 0.8;
    }
  }

  TextStyle get calendarHeader => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get stepperTitle => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(this).colorScheme.onSurface,
  );

  TextStyle get stepperTitleActive => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Theme.of(this).colorScheme.primary,
  );
}
