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
  static const List<String> types = ['Popup', 'Email', 'Text', 'Push'];
  static final List<DropDownItem<String>> typeItems = [
    DropDownItem(
      id: 0,
      value: 'Popup',
      iconData: Icons.notifications_active_outlined,
    ),
    DropDownItem(id: 1, value: 'Email', iconData: Icons.mail_outline),
    DropDownItem(id: 2, value: 'Text', iconData: Icons.sms_outlined),
    DropDownItem(id: 3, value: 'Push', iconData: Icons.phone_android_outlined),
  ];

  static const List<String> offsetTypes = ['Minutes', 'Hours', 'Days', 'Weeks'];
  static final List<DropDownItem<String>> offsetTypeItems = offsetTypes
      .toDropDownItems();
}
