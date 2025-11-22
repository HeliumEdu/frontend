// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class EventRequestModel {
  final String title;
  final bool allDay;
  final bool showEndTime;
  final String start; // ISO 8601 format
  final String? end; // ISO 8601 format
  final int priority;
  final String? url;
  final String? comments;

  EventRequestModel({
    required this.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    this.end,
    required this.priority,
    this.url,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'all_day': allDay,
      'show_end_time': showEndTime,
      'start': start,
      'priority': priority,
    };

    // API requires these fields but accepts null
    data['end'] = (end != null && end!.isNotEmpty) ? end : null;

    if (url != null && url!.isNotEmpty) data['url'] = url;
    if (comments != null && comments!.isNotEmpty) data['comments'] = comments;

    return data;
  }
}
