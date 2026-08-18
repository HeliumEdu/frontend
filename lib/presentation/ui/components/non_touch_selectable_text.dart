import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class NonTouchSelectableText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;

  const NonTouchSelectableText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isTouchDevice(context)) {
      return SelectableText(
        data,
        style: style,
        maxLines: maxLines,
      );
    }

    return Text(
      data,
      style: style,
      maxLines: maxLines,
    );
  }
}
