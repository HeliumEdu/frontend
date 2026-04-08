// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ExternalCalendarRequestModel {
  final String? title;
  final String? url;
  final String? color;
  final bool? shownOnCalendar;

  const ExternalCalendarRequestModel({
    this.title,
    this.url,
    this.color,
    this.shownOnCalendar,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) json['title'] = title;
    if (url != null) json['url'] = url;
    if (color != null) json['color'] = color;
    if (shownOnCalendar != null) json['shown_on_calendar'] = shownOnCalendar;

    return json;
  }
}
