// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_style.dart';

const Color seedColor = Color(0xff418eb9);

/// Theme extension for semantic colors (success, warning, info)
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color successContainer;
  final Color warningContainer;
  final Color infoContainer;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.successContainer,
    required this.warningContainer,
    required this.infoContainer,
  });

  static const light = SemanticColors(
    success: Color(0xff049f71),
    warning: Color(0xffc48d3b),
    info: Color(0xff418eb9),
    successContainer: Color(0xffE8F5E9),
    warningContainer: Color(0xffFFF8E1),
    infoContainer: Color(0xffdff7e7),
  );

  static const dark = SemanticColors(
    success: Color(0xff33fabe),
    warning: Color(0xfffbc313),
    info: Color(0xff5aa2c2),
    successContainer: Color(0xff1B3D2F),
    warningContainer: Color(0xff3D3520),
    infoContainer: Color(0xff192f37),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? successContainer,
    Color? warningContainer,
    Color? infoContainer,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  SemanticColors lerp(SemanticColors? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      error: const Color(0xffc51d4b),
    );
    return _buildTheme(colorScheme, SemanticColors.light);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xff5aa2c2),
      error: const Color(0xffe15c7b),
    );
    return _buildTheme(colorScheme, SemanticColors.dark);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    SemanticColors semantic,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppStyles.defaultTextTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            } else {
              return colorScheme.primary.withValues(alpha: 0.3);
            }
          }),
          foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          side: WidgetStateProperty.all<BorderSide>(
            BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            return null; // Use default overlay
          }),
        ),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 6.0),
      timePickerTheme: TimePickerThemeData(
        dayPeriodColor: colorScheme.primary.withValues(alpha: 0.3),
        hourMinuteTextStyle: AppStyles.poppins(
          fontSize: 56,
          fontWeight: FontWeight.w400,
        ),
        dayPeriodTextStyle: AppStyles.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helpTextStyle: AppStyles.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        headerHelpStyle: AppStyles.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        headerHeadlineStyle: AppStyles.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        weekdayStyle: AppStyles.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        dayStyle: AppStyles.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        yearStyle: AppStyles.poppins(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: AppStyles.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      extensions: [semantic],
    );
  }
}

extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  SemanticColors get semanticColors =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
