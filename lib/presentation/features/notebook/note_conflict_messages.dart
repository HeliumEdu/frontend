import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

ConflictMessage changedSinceDraftMessage(
  AppLocalizations l10n,
  NoteModel latest,
  DateTime? draftSavedAt,
) {
  return ConflictMessage(
    title: l10n.noteRecoverChangesTitle,
    body: _changedSinceDraftBody(l10n, latest, draftSavedAt),
    discardLabel: l10n.discardChangesButton,
    saveLabel: l10n.noteRecoverButton,
  );
}

String _changedSinceDraftBody(
  AppLocalizations l10n,
  NoteModel latest,
  DateTime? draftSavedAt,
) {
  if (draftSavedAt != null) {
    final relative = HeliumDateTime.describeRelativeTo(latest.updatedAt, draftSavedAt);
    return l10n.noteRecoverChangedRelativeMessage(relative.direction, relative.gap);
  }
  final when = describeVersionSaved(latest.version);
  return when == null ? l10n.noteRecoverChangedMessage : l10n.noteRecoverChangedAtMessage(when);
}
