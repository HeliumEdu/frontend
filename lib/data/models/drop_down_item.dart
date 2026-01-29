// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

class DropDownItem<T> {
  final int id;
  final T value;
  final IconData? icon;

  DropDownItem({required this.id, required this.value, this.icon});
}
