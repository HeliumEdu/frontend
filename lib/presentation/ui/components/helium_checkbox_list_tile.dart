// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

/// A drop-in replacement for [CheckboxListTile] that delivers a single,
/// consistent tap sound regardless of whether the user taps the row body or
/// the checkbox glyph itself.
///
/// [CheckboxListTile] has two tap targets — the surrounding [ListTile] (which
/// fires [Feedback.forTap] via its [InkWell]) and the inner [Checkbox] (which
/// has no built-in feedback). This wrapper disables the underlying
/// [InkWell] feedback and emits [Feedback.forTap] from [onChanged] so both
/// paths produce exactly one click sound on Android.
class HeliumCheckboxListTile extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  final VisualDensity? visualDensity;
  final bool tristate;
  final bool? enabled;
  final bool selected;
  final Color? activeColor;
  final Color? checkColor;
  final Color? tileColor;
  final ShapeBorder? shape;
  final FocusNode? focusNode;
  final bool autofocus;

  const HeliumCheckboxListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.contentPadding,
    this.dense,
    this.visualDensity,
    this.tristate = false,
    this.enabled,
    this.selected = false,
    this.activeColor,
    this.checkColor,
    this.tileColor,
    this.shape,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              Feedback.forTap(context);
              onChanged!(newValue);
            },
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      controlAffinity: controlAffinity,
      contentPadding: contentPadding,
      dense: dense,
      visualDensity: visualDensity,
      tristate: tristate,
      enabled: enabled,
      selected: selected,
      activeColor: activeColor,
      checkColor: checkColor,
      tileColor: tileColor,
      shape: shape,
      focusNode: focusNode,
      autofocus: autofocus,
      enableFeedback: false,
    );
  }
}
