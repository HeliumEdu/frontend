// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/dropdown_extensions.dart';

class ReminderConstants {
  static final List<DropDownItem<String>> typeItems = [
    DropDownItem(id: 1, value: 'Email', iconData: Icons.mail_outline),
    DropDownItem(id: 3, value: 'Push', iconData: Icons.phone_android_outlined),
  ];

  /// The dropdown item for a reminder type (backend enum value).
  static DropDownItem<String> itemForType(int type) =>
      typeItems.firstWhere((t) => t.id == type);

  /// The reminder type (backend enum value) for a display [label].
  static int typeForLabel(String label) =>
      typeItems.firstWhere((t) => t.value == label).id;

  static const List<String> offsetTypes = ['Minutes', 'Hours', 'Days', 'Weeks'];
  static final List<DropDownItem<String>> offsetTypeItems = offsetTypes
      .toDropDownItems();
}
