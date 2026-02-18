// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/dropdown_extensions.dart';

class ResourceConstants {
  static final List<String> status = [
    'Owned',
    'Rented',
    'Ordered',
    'Shipped',
    'Needed',
    'Returned',
    'To Sell',
    'Digital',
  ];
  static final List<DropDownItem<String>> statusItems = status
      .toDropDownItems();

  static final List<String> condition = [
    'Brand New',
    'Refurbished',
    'Used - Like New',
    'Used - Very Good',
    'Used - Good',
    'Used - Acceptable',
    'Used - Poor',
    'Broken',
    'Digital',
  ];
  static final List<DropDownItem<String>> conditionItems = condition
      .toDropDownItems();
}
