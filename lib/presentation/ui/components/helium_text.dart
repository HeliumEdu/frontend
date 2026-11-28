import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:heliumapp/utils/app_globals.dart';

/// A one-line label that renders as a plain [Text] when it fits its width,
/// and otherwise shrinks until it does, down to
/// [AppConstants.textFitMinimumScale] of [style]'s size and never below
/// [AppConstants.textFitMinimumFontSize] once the OS text scale applies. Past
/// that it ellipsizes and shows the full text in a tooltip.
class HeliumText extends StatelessWidget {
  static const _fontSizeStep = 0.5;

  final String text;
  final TextStyle? style;

  const HeliumText(this.text, {super.key, this.style});

  /// A font size, at most [style]'s, at which [text] fits on one line in
  /// [maxWidth], and whether it fits at all; when it doesn't, the size is the
  /// smallest allowed.
  static ({double fontSize, bool fits}) fit({
    required String text,
    required TextStyle style,
    required TextScaler textScaler,
    required double maxWidth,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final fontSize = style.fontSize ?? kDefaultFontSize;
    final naturalWidth = _widthAt(text, style, fontSize, textScaler, textDirection);
    if (naturalWidth <= maxWidth) return (fontSize: fontSize, fits: true);

    final minimumSize = math.min(
      fontSize,
      math.max(
        fontSize * AppConstants.textFitMinimumScale,
        AppConstants.textFitMinimumFontSize * fontSize / textScaler.scale(fontSize),
      ),
    );
    var size = math.max(minimumSize, fontSize * maxWidth / naturalWidth);
    var width = _widthAt(text, style, size, textScaler, textDirection);
    while (width > maxWidth && size > minimumSize) {
      size = math.max(minimumSize, size - _fontSizeStep);
      width = _widthAt(text, style, size, textScaler, textDirection);
    }
    return (fontSize: size, fits: width <= maxWidth);
  }

  static double _widthAt(
    String text,
    TextStyle style,
    double size,
    TextScaler textScaler,
    TextDirection textDirection,
  ) =>
      measure(text, style.copyWith(fontSize: size), textScaler, textDirection: textDirection).width;

  static Size measure(
    String text,
    TextStyle style,
    TextScaler textScaler, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    return _HeliumTextLayoutBuilder(
      text: text,
      style: effectiveStyle,
      textScaler: textScaler,
      textDirection: textDirection,
      builder: (context, constraints) => _buildForWidth(
        constraints.maxWidth,
        effectiveStyle,
        textScaler,
        textDirection,
      ),
    );
  }

  Widget _buildForWidth(
    double maxWidth,
    TextStyle effectiveStyle,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final natural = Text(text, style: style);
    if (maxWidth.isInfinite) return natural;

    final (:fontSize, :fits) = fit(
      text: text,
      style: effectiveStyle,
      textScaler: textScaler,
      maxWidth: maxWidth,
      textDirection: textDirection,
    );
    if (fits && fontSize == (effectiveStyle.fontSize ?? kDefaultFontSize)) {
      return natural;
    }

    final fittedStyle = (style ?? const TextStyle()).copyWith(fontSize: fontSize);
    if (fits) {
      return Text(text, style: fittedStyle, maxLines: 1, softWrap: false);
    }
    return Tooltip(
      message: text,
      excludeFromSemantics: true,
      child: Text(
        text,
        style: fittedStyle,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeliumTextLayoutBuilder extends ConstrainedLayoutBuilder<BoxConstraints> {
  final String text;
  final TextStyle style;
  final TextScaler textScaler;
  final TextDirection textDirection;

  const _HeliumTextLayoutBuilder({
    required this.text,
    required this.style,
    required this.textScaler,
    required this.textDirection,
    required super.builder,
  });

  @override
  _RenderHeliumTextLayoutBuilder createRenderObject(BuildContext context) =>
      _RenderHeliumTextLayoutBuilder(
        text: text,
        style: style,
        textScaler: textScaler,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeliumTextLayoutBuilder renderObject,
  ) {
    renderObject.update(
      text: text,
      style: style,
      textScaler: textScaler,
      textDirection: textDirection,
    );
  }
}

class _RenderHeliumTextLayoutBuilder extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<BoxConstraints, RenderBox>,
        RelayoutWhenSystemFontsChangeMixin {
  String _text;
  TextStyle _style;
  TextScaler _textScaler;
  TextDirection _textDirection;

  _RenderHeliumTextLayoutBuilder({
    required String text,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) : _text = text,
       _style = style,
       _textScaler = textScaler,
       _textDirection = textDirection;

  void update({
    required String text,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    if (text == _text &&
        style == _style &&
        textScaler == _textScaler &&
        textDirection == _textDirection) {
      return;
    }
    _text = text;
    _style = style;
    _textScaler = textScaler;
    _textDirection = textDirection;
    markNeedsLayout();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    scheduleLayoutCallback();
  }

  Size get _naturalSize => HeliumText.measure(
    _text,
    _style,
    _textScaler,
    textDirection: _textDirection,
  );

  @override
  double computeMinIntrinsicWidth(double height) {
    final painter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: _textDirection,
      textScaler: _textScaler,
    )..layout();
    final width = painter.minIntrinsicWidth;
    painter.dispose();
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) => _naturalSize.width;

  @override
  double computeMinIntrinsicHeight(double width) => _naturalSize.height;

  @override
  double computeMaxIntrinsicHeight(double width) => _naturalSize.height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_naturalSize);

  @override
  void performLayout() {
    runLayoutCallback();
    if (child case final child?) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
    } else {
      size = constraints.smallest;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child?.getDistanceToActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child?.hitTest(result, position: position) ?? false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child case final child?) context.paintChild(child, offset);
  }
}
