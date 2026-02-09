// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ExternalCalendarRequestModel {
  final String title;
  final String url;
  final String color;
  final bool shownOnCalendar;

  const ExternalCalendarRequestModel({
    required this.title,
    required this.url,
    required this.color,
    required this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'color': color,
      'shown_on_calendar': shownOnCalendar,
    };
  }
}
