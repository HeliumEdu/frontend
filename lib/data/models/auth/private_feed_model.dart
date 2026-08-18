// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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
