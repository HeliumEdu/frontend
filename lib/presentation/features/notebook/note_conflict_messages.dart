import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

ConflictMessage changedSinceDraftMessage(
  NoteModel latest,
  DateTime? draftSavedAt,
) {
  final changed = draftSavedAt == null
      ? describeVersionSaved(latest.version)
      : '${HeliumDateTime.describeRelativeTo(latest.updatedAt, draftSavedAt)} '
            'your recovered changes';
  final when = changed == null ? '' : ' $changed';
  return ConflictMessage(
    title: 'Recover Your Changes?',
    body:
        'This note was changed on another device$when. Recover your '
        'changes anyway, replacing that version?',
    discardLabel: 'Discard',
    saveLabel: 'Recover',
  );
}
