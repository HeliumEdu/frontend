import 'dart:math';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/contrast_service.dart';

class HeliumColors {
  static const List<Color> preferredColors = [
    Color(0xffec6f92),
    Color(0xffe74674),
    Color(0xffe21d55),
    Color(0xffb91846),
    Color(0xff901336),
    Color(0xff5e0c23),
    Color(0xffdc7d50),
    Color(0xffd5602a),
    Color(0xffaf4f23),
    Color(0xff7b3718),
    Color(0xff622c13),
    Color(0xff3c1b0c),
    Color(0xffcfa25e),
    Color(0xffc48d3b),
    Color(0xffa17430),
    Color(0xff7e5a26),
    Color(0xff5a411b),
    Color(0xff372810),
    Color(0xff33fabe),
    Color(0xff06f9b0),
    Color(0xff05cc90),
    Color(0xff049f71),
    Color(0xff037251),
    Color(0xff024b35),
    Color(0xff5658d7),
    Color(0xff3033cf),
    Color(0xff282aa9),
    Color(0xff1f2184),
    Color(0xff16175f),
    Color(0xff0d0e38),
    Color(0xffc964b5),
    Color(0xffbd42a4),
    Color(0xff9b3687),
    Color(0xff792a69),
    Color(0xff571e4c),
    Color(0xff3c1534),
    Color(0xffc09bc0),
    Color(0xffae7eae),
    Color(0xff9d629d),
    Color(0xff815181),
    Color(0xff643f64),
    Color(0xff553555),
  ];

  static Color hexToColor(String hex) {
    String h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    return Color(int.parse('ff$h', radix: 16));
  }

  static String colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  static Color getRandomColor() {
    final random = Random();
    final i = random.nextInt(preferredColors.length);
    return preferredColors[i];
  }

  static Color getColorForPriority(double value) {
    final int index = ((value.clamp(1, 100) - 1) / 10).floor();

    const colors = [
      Color(0xff6FCC43), // (green)
      Color(0xff86D238),
      Color(0xffA1D72E),
      Color(0xffBEDC26),
      Color(0xffD9DF1E),
      Color(0xffF2DD19),
      Color(0xffFBC313),
      Color(0xffF79E0E),
      Color(0xffEF6A0B),
      Color(0xffD92727), // (red)
    ];

    return colors[index];
  }

  static Color urgencyColor(BuildContext context, int value) {
    switch (value.clamp(1, 3)) {
      case 1:
        return context.semanticColors.success;
      case 2:
        return context.semanticColors.warning;
      case 3:
      default:
        return context.colorScheme.error;
    }
  }

  /// WCAG contrast ratio between [foreground] composited over [background].
  static double contrastRatio(Color foreground, Color background) {
    final composited = Color.alphaBlend(foreground, background);
    final lighter = max(composited.computeLuminance(), background.computeLuminance());
    final darker = min(composited.computeLuminance(), background.computeLuminance());
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns a contrasting text color (white or black) for [backgroundColor].
  /// Flips to black at a luminance of 0.5, which keeps white text on most
  /// palette colors; when the OS asks for increased contrast, picks whichever
  /// of the two reads better instead, which always clears WCAG AA (4.5:1).
  static Color contrastingTextColor(Color backgroundColor) {
    if (ContrastService().increaseContrast) {
      return contrastRatio(Colors.black, backgroundColor) >=
              contrastRatio(Colors.white, backgroundColor)
          ? Colors.black
          : Colors.white;
    }
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  /// Moves [color] toward [target] in small steps until it reads at
  /// [minimumRatio] against [background]; returns [color] unchanged when it
  /// already does.
  static Color ensureContrast(
    Color color, {
    required Color background,
    required Color target,
    double minimumRatio = 4.5,
  }) {
    var adjusted = color;
    var amount = 0.0;
    while (contrastRatio(adjusted, background) < minimumRatio && amount < 1.0) {
      amount += 0.05;
      adjusted = Color.lerp(color, target, amount)!;
    }
    return adjusted;
  }
}

/// Extension on Color that provides a memoized contrasting color.
/// Useful for screens with many items sharing a small set of colors
/// (e.g., planner items colored by course/category).
extension ContrastingColor on Color {
  static final _cache = <int, Color>{};

  /// Returns a contrasting text color (white or black) based on luminance.
  /// Results are cached by color value for efficiency.
  Color get contrasting => _cache.putIfAbsent(
        (toARGB32() << 1) | (ContrastService().increaseContrast ? 1 : 0),
        () => HeliumColors.contrastingTextColor(this),
      );
}

/// Helpers for creating badge-style backgrounds that work in both light and dark mode.
/// Instead of using alpha transparency (which fails with dark colors on dark backgrounds),
/// these blend the user's color with the surface color.
class BadgeColors {
  /// Creates a subtle background tint by blending the color with the surface.
  /// Works in both light and dark mode, unlike alpha transparency.
  static Color background(BuildContext context, Color color) {
    return Color.lerp(
      context.colorScheme.surface,
      color,
      0.15,
    )!;
  }

  /// Creates a border color by blending the color with the surface at higher ratio
  static Color border(BuildContext context, Color color) {
    return Color.lerp(
      context.colorScheme.surface,
      color,
      0.35,
    )!;
  }

  /// Returns a foreground color (for text/icons) that ensures readability.
  /// In dark mode, lightens dark colors. In light mode, darkens light colors.
  /// When the OS asks for increased contrast, moves the color only as far as
  /// needed to read at WCAG AA against [background] instead.
  static Color foreground(BuildContext context, Color color) {
    final isDark = context.isDarkMode;
    if (ContrastService().increaseContrast) {
      return HeliumColors.ensureContrast(
        color,
        background: background(context, color),
        target: isDark ? Colors.white : Colors.black,
      );
    }

    final luminance = color.computeLuminance();
    if (isDark && luminance < 0.4) {
      return Color.lerp(color, Colors.white, 0.5)!;
    } else if (!isDark && luminance > 0.7) {
      return Color.lerp(color, Colors.black, 0.4)!;
    }
    return color;
  }
}
