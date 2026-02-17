// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/drop_down_item.dart';

extension DropDownItemsExtension on List<String> {
  List<DropDownItem<String>> toDropDownItems() {
    return map((item) => DropDownItem(id: indexOf(item), value: item)).toList();
  }
}
