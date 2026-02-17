// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ResourceGroupRequestModel {
  final String title;
  final bool shownOnCalendar;

  ResourceGroupRequestModel({
    required this.title,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'shown_on_calendar': shownOnCalendar};
  }
}
