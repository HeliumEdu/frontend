// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class PrivateFeedModel {
  final String eventsPrivateUrl;
  final String homeworkPrivateUrl;
  final String courseSchedulesPrivateUrl;

  PrivateFeedModel({
    required this.eventsPrivateUrl,
    required this.homeworkPrivateUrl,
    required this.courseSchedulesPrivateUrl,
  });

  factory PrivateFeedModel.fromJson(Map<String, dynamic> json) {
    return PrivateFeedModel(
      eventsPrivateUrl: json['events_private_url'],
      homeworkPrivateUrl: json['homework_private_url'],
      courseSchedulesPrivateUrl: json['courseschedules_private_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events_private_url': eventsPrivateUrl,
      'homework_private_url': homeworkPrivateUrl,
      'courseschedules_private_url': courseSchedulesPrivateUrl,
    };
  }
}
