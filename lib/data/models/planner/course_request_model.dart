// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class CourseRequestModel {
  final String title;
  final String room;
  final String credits;
  final String color;
  final String website;
  final bool isOnline;
  final String teacherName;
  final String teacherEmail;
  final String startDate;
  final String endDate;
  final int courseGroup;

  CourseRequestModel({
    required this.title,
    required this.room,
    required this.credits,
    required this.color,
    required this.website,
    required this.isOnline,
    required this.teacherName,
    required this.teacherEmail,
    required this.startDate,
    required this.endDate,
    required this.courseGroup,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'room': room,
      'credits': credits,
      'color': color,
      'website': website,
      'is_online': isOnline,
      'teacher_name': teacherName,
      'teacher_email': teacherEmail,
      'start_date': startDate,
      'end_date': endDate,
      'course_group': courseGroup,
    };
  }

  factory CourseRequestModel.fromJson(Map<String, dynamic> json) {
    return CourseRequestModel(
      title: json['title'] ?? '',
      room: json['room'] ?? '',
      credits: json['credits'] ?? '0',
      color: json['color'] ?? '#cabdbf',
      website: json['website'] ?? '',
      isOnline: json['is_online'] ?? false,
      teacherName: json['teacher_name'] ?? '',
      teacherEmail: json['teacher_email'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      courseGroup: json['course_group'] ?? 0,
    );
  }
}
