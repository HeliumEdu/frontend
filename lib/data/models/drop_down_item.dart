// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/base_model.dart';

class DropDownItem<T> extends BaseModel {
  final T? value;
  final IconData? iconData;
  final Color? iconColor;
  final bool isDivider;

  DropDownItem({
    required super.id,
    this.value,
    this.iconData,
    this.iconColor,
    this.isDivider = false,
  });
}
