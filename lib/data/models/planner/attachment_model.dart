import 'package:heliumapp/data/models/base_model.dart';

class AttachmentModel extends BaseTitledModel {
  final String attachment;
  final int size;
  final int user;
  final int? course;
  final int? event;
  final int? homework;
  final int? resource;

  AttachmentModel({
    required super.id,
    required super.title,
    required this.attachment,
    required this.size,
    required this.user,
    this.course,
    this.event,
    this.homework,
    this.resource,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'],
      title: json['title'],
      attachment: json['attachment'],
      size: json['size'],
      user: json['user'],
      course: json['course'],
      event: json['event'],
      homework: json['homework'],
      resource: json['resource'],
    );
  }
}
