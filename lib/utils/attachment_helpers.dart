import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Attachments from one source, under its sub-heading; the item's own
/// attachments have none.
typedef AttachmentGroup = ({String? title, List<AttachmentModel> attachments});

/// Groups and counts attachments by where they come from: an item's own, or
/// pulled through from the class or resources it belongs to.
class AttachmentGroups {
  AttachmentGroups._();

  /// The assignment's own attachments, then those it pulls through, leaving
  /// out sources with none.
  static List<AttachmentGroup> forHomework(
    HomeworkModel homework,
    List<AttachmentModel> attachments,
  ) =>
      [
        ..._group(null, attachments.where((a) => a.homework == homework.id)),
        ...pulledThroughForHomework(homework, attachments),
      ];

  /// The attachments an assignment pulls through: its class's, then its
  /// resources', leaving out sources with none.
  static List<AttachmentGroup> pulledThroughForHomework(
    HomeworkModel homework,
    List<AttachmentModel> attachments,
  ) {
    final resourceIds = {for (final resource in homework.resources) resource.id};
    return [
      ..._group('Class', attachments.where((a) => a.course == homework.course.id)),
      ..._group(
        'Resource',
        attachments.where((a) => resourceIds.contains(a.resource)),
      ),
    ];
  }

  static List<AttachmentGroup> forCourse(
    int courseId,
    List<AttachmentModel> attachments,
  ) =>
      _group(null, attachments.where((a) => a.course == courseId));

  static List<AttachmentGroup> forResource(
    int resourceId,
    List<AttachmentModel> attachments,
  ) =>
      _group(null, attachments.where((a) => a.resource == resourceId));

  /// How many attachments an assignment shows beyond its own: its class's and
  /// its resources'.
  static int pulledThroughCount(
    HomeworkModel homework,
    List<AttachmentModel> attachments,
  ) {
    final resourceIds = {for (final resource in homework.resources) resource.id};
    return attachments
        .where(
          (a) =>
              a.course == homework.course.id ||
              resourceIds.contains(a.resource),
        )
        .length;
  }

  static List<AttachmentGroup> _group(
    String? title,
    Iterable<AttachmentModel> attachments,
  ) {
    final list = attachments.toList();
    if (list.isEmpty) return const [];
    Sort.byTitle(list);
    return [(title: title, attachments: list)];
  }
}
