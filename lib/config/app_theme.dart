import 'package:flutter/material.dart';
import 'package:heliumapp/config/semantic_colors.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';

const Color seedColor = Color(0xff418eb9);

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class AppTheme {
  static ThemeData light({bool reduceMotion = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      error: const Color(0xffc51d4b),
    );
    return _buildTheme(colorScheme, SemanticColors.light, reduceMotion: reduceMotion);
  }

  static ThemeData dark({bool reduceMotion = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xff5aa2c2),
      error: const Color(0xffe15c7b),
    );
    return _buildTheme(colorScheme, SemanticColors.dark, reduceMotion: reduceMotion);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    SemanticColors semantic, {
    bool reduceMotion = false,
  }) {
    return ThemeData(
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: _NoMotionPageTransitionsBuilder(),
              TargetPlatform.iOS: _NoMotionPageTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
          foregroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurfaceVariant;
          }),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        cancelButtonStyle: HeliumElevatedButton.baseStyle(
          colorScheme,
          backgroundColor: colorScheme.outline,
          minimumWidth: 0,
        ),
        confirmButtonStyle: HeliumElevatedButton.baseStyle(
          colorScheme,
          minimumWidth: 0,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        cancelButtonStyle: HeliumElevatedButton.baseStyle(
          colorScheme,
          backgroundColor: colorScheme.outline,
          minimumWidth: 0,
        ),
        confirmButtonStyle: HeliumElevatedButton.baseStyle(
          colorScheme,
          minimumWidth: 0,
        ),
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
