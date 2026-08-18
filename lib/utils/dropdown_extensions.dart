// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/drop_down_item.dart';

extension DropDownItemsExtension on List<String> {
  List<DropDownItem<String>> toDropDownItems() {
    return map((item) => DropDownItem(id: indexOf(item), value: item)).toList();
  }
}
