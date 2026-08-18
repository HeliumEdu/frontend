import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';

class DropDownItem<T> extends BaseModel {
  final T? value;
  final String? _label;
  final IconData? iconData;
  final Color? iconColor;
  final bool isDivider;

  DropDownItem({
    required super.id,
    this.value,
    String? label,
    this.iconData,
    this.iconColor,
    this.isDivider = false,
  }) : _label = label;

  String get label => _label ?? value.toString();
}
