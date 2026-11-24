import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Moves focus on Tab (Shift+Tab back) where Tab reaches a text field only as
/// a typed tab character ([PlatformBehavior.typesTabAsText]): the tab is
/// dropped and focus moves, as Tab does everywhere else.
class TabMovesFocusFormatter extends TextInputFormatter {
  const TabMovesFocusFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selection = oldValue.selection;
    final isTypedTab = selection.isValid &&
        newValue.text ==
            oldValue.text.replaceRange(selection.start, selection.end, '\t');
    if (!isTypedTab) return newValue;
    final backward = HardwareKeyboard.instance.isShiftPressed;
    scheduleMicrotask(() {
      final focused = FocusManager.instance.primaryFocus;
      backward ? focused?.previousFocus() : focused?.nextFocus();
    });
    return oldValue;
  }
}
