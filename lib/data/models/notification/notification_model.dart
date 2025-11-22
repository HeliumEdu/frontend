// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

class NotificationModel {
  final String? title;
  final String? body;
  final Color? color;
  final Map<String, dynamic>? data;
  final String? notificationId;
  final DateTime? timestamp;
  final bool? isRead;
  final String? type;
  final String? action;
  final int? apiId; // HeliumEdu API ID for deletion

  NotificationModel({
    this.title,
    this.body,
    this.color,
    this.data,
    this.notificationId,
    this.timestamp,
    this.isRead,
    this.type,
    this.action,
    this.apiId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'],
      body: json['body'],
      color: json['color'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      notificationId: json['notification_id'] ?? json['notificationId'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      type: json['type'],
      action: json['action'],
      apiId: json['api_id'] ?? json['apiId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'color': color,
      'data': data,
      'notification_id': notificationId,
      'timestamp': timestamp?.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'action': action,
      'api_id': apiId,
    };
  }

  NotificationModel copyWith({
    String? title,
    String? body,
    Color? color,
    Map<String, dynamic>? data,
    String? notificationId,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? action,
    int? apiId,
  }) {
    return NotificationModel(
      title: title ?? this.title,
      body: body ?? this.body,
      color: color ?? this.color,
      data: data ?? this.data,
      notificationId: notificationId ?? this.notificationId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      action: action ?? this.action,
      apiId: apiId ?? this.apiId,
    );
  }
}
