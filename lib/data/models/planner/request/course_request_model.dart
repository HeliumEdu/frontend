// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Server-side category provisioning template passed on course create; the backend seeds the
/// corresponding default categories in the same request (see `CATEGORY_TEMPLATE_CHOICES`).
enum CourseTemplate {
  standard(0);

  const CourseTemplate(this.value);

  final int value;
}

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
  final int? template;

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
    this.template,
  });

  CourseRequestModel copyWith({int? template}) {
    return CourseRequestModel(
      title: title,
      room: room,
      credits: credits,
      color: color,
      website: website,
      isOnline: isOnline,
      teacherName: teacherName,
      teacherEmail: teacherEmail,
      startDate: startDate,
      endDate: endDate,
      courseGroup: courseGroup,
      template: template ?? this.template,
    );
  }

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
      if (template != null) 'template': template,
    };
  }

  factory CourseRequestModel.fromJson(Map<String, dynamic> json) {
    return CourseRequestModel(
      title: json['title'],
      room: json['room'],
      credits: json['credits'],
      color: json['color'],
      website: json['website'],
      isOnline: json['is_online'],
      teacherName: json['teacher_name'],
      teacherEmail: json['teacher_email'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      courseGroup: json['course_group'],
    );
  }
}
