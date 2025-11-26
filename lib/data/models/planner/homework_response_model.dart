// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class HomeworkResponseModel {
  final int id;
  final String title;
  final bool allDay;
  final bool showEndTime;
  final String start;
  final String? end;
  final int priority;
  final String? url;
  final String? comments;
  final String? currentGrade;
  final bool completed;
  final int? category;
  final List<int>? materials;
  final int course;
  final int userId;

  HomeworkResponseModel({
    required this.id,
    required this.title,
    required this.allDay,
    required this.showEndTime,
    required this.start,
    this.end,
    required this.priority,
    this.url,
    this.comments,
    this.currentGrade,
    required this.completed,
    this.category,
    this.materials,
    required this.course,
    required this.userId,
  });

  factory HomeworkResponseModel.fromJson(Map<String, dynamic> json) {
    return HomeworkResponseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      allDay: json['all_day'] ?? false,
      showEndTime: json['show_end_time'] ?? false,
      start: json['start'] ?? '',
      end: json['end'],
      priority: json['priority'] ?? 0,
      url: json['url'],
      comments: json['comments'],
      currentGrade: json['current_grade'],
      completed: json['completed'] ?? false,
      category: json['category'],
      materials: json['materials'] != null
          ? List<int>.from(json['materials'])
          : null,
      course: json['course'] ?? 0,
      userId: json['user'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'all_day': allDay,
      'show_end_time': showEndTime,
      'start': start,
      'end': end,
      'priority': priority,
      'url': url,
      'comments': comments,
      'current_grade': currentGrade,
      'completed': completed,
      'category': category,
      'materials': materials,
      'course': course,
      'user': userId,
    };
  }

  // Helper to check if course has grade
  bool hasGrade() {
    return currentGrade != '-1/100' && currentGrade!.isNotEmpty;
  }

  // Helper to get formatted grade
  String getFormattedGrade() {
    if (!hasGrade()) {
      return '';
    }
    try {
      final split = currentGrade!.split('/');
      final grade = (double.parse(split[0]) / double.parse(split[1])) * 100;
      return '${grade.toStringAsFixed(2)}%';
    } catch (e) {
      return '';
    }
  }
}
