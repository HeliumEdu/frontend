import 'package:flutter/material.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/controllers/linked_note_form_fields.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

/// A form that saves an item of type [T] together with its linked note, where
/// either save can lose to a newer version.
mixin LinkedNoteForm<W extends StatefulWidget, T> on ConflictResolvableForm<W> {
  bool _isEntityConflict = false;
  bool _redirectToNotebook = false;

  LinkedNoteFormFields get linkedNoteFields;

  /// The item conflict messages name: assignment, event, class or resource.
  String get conflictItem;

  /// The item a new note links to; one is set.
  ({int? homeworkId, int? eventId, int? resourceId, int? courseId}) get linkedItem;

  void resetSubmitting();

  void showSavedEntity(T entity);

  void loadLinkedNote(NoteModel? note) {
    linkedNoteFields.loadLinkedNote(note);
    _isEntityConflict = false;
  }

  /// Whether this save redirects to the Notebook; an overwrite keeps the
  /// choice of the save it retries.
  bool rememberRedirectToNotebook(bool requested) {
    if (!isOverwriting) _redirectToNotebook = requested;
    return _redirectToNotebook;
  }

  /// [version], or none when overwriting a newer version of the item.
  String? entityVersionToSend(String? version) =>
      isOverwriting && _isEntityConflict ? null : version;

  void applyConflict({T? savedEntity, LinkedNoteSave? linkedNoteSave}) {
    _isEntityConflict = savedEntity == null;
    if (savedEntity != null) showSavedEntity(savedEntity);
    linkedNoteFields.applyLinkedNoteSave(linkedNoteSave);
  }

  void _loadLatest() {
    if (!_redirectToNotebook) return loadLatest();
    openInNotebook(
      context,
      noteId: linkedNoteFields.noteIdToOpen,
      homeworkId: linkedItem.homeworkId,
      eventId: linkedItem.eventId,
      resourceId: linkedItem.resourceId,
      courseId: linkedItem.courseId,
    );
  }
}

/// Settles a save where the item or its linked note didn't save: asks how to
/// resolve a newer version, or, when only the note failed, keeps the form open
/// with the saved item and the unsaved note. [savedEntity] is set when the
/// item saved. [latestVersion] is the newer item's `updated_at` when the item
/// didn't save.
void resolveLinkedNoteConflict<T>(
  BuildContext context,
  LinkedNoteForm<StatefulWidget, T>? form, {
  T? savedEntity,
  String? latestVersion,
  LinkedNoteSave? linkedNoteSave,
}) {
  if (form == null) return;
  final isNoteConflict = linkedNoteSave?.isConflict ?? false;

  form.resetSubmitting();
  form.applyConflict(savedEntity: savedEntity, linkedNoteSave: linkedNoteSave);
  if (linkedNoteSave?.failure case final failure? when savedEntity != null) {
    SnackBarHelper.show(
      context,
      AppLocalizations.of(context).linkedNoteSaveFailedMessage(failure.message),
      type: SnackType.error,
    );
  }
  if (savedEntity != null && !isNoteConflict) return;

  resolveConflict(
    context,
    onLoadLatest: form._loadLatest,
    onOverwrite: form.overwriteNewer,
    canKeepEditing: isNoteConflict,
    message: _messageFor(
      AppLocalizations.of(context),
      form,
      isItemConflict: savedEntity == null,
      latestVersion: latestVersion,
      latestNote: isNoteConflict ? linkedNoteSave?.note : null,
    ),
  );
}

String get noteRecreatedMessage =>
    LocaleNotifier().localizations.linkedNoteRecreatedMessage;

ConflictMessage _messageFor(
  AppLocalizations l10n,
  LinkedNoteForm<StatefulWidget, dynamic> form, {
  required bool isItemConflict,
  required String? latestVersion,
  required NoteModel? latestNote,
}) {
  final item = form.conflictItem;
  if (latestNote == null) {
    return ConflictMessage.changedAt(l10n, latestVersion, item: item);
  }

  final deletesNote = form.linkedNoteFields.overwriteDeletesNote;

  if (!isItemConflict) {
    final when = describeVersionSaved(latestNote.version);
    if (deletesNote) {
      return ConflictMessage(
        title: l10n.linkedNoteChangedTitle,
        body: when == null
            ? l10n.linkedNoteChangedDeleteMessage(item)
            : l10n.linkedNoteChangedAtDeleteMessage(item, when),
        discardLabel: l10n.linkedNoteKeepButton,
        saveLabel: l10n.linkedNoteDeleteButton,
        isSaveDestructive: true,
      );
    }
    return ConflictMessage(
      title: l10n.linkedNoteChangedTitle,
      body: when == null
          ? l10n.linkedNoteChangedSaveMessage(item)
          : l10n.linkedNoteChangedAtSaveMessage(item, when),
      discardLabel: l10n.conflictDiscardChangesButton,
      saveLabel: l10n.conflictSaveChangesButton,
    );
  }

  final mostRecently = describeVersionSaved(
    HeliumDateTime.laterTimestamp(latestVersion, latestNote.version),
  );
  if (deletesNote) {
    return ConflictMessage(
      title: l10n.conflictChangedTitle,
      body: mostRecently == null
          ? l10n.linkedNoteBothChangedDeleteMessage(item)
          : l10n.linkedNoteBothChangedAtDeleteMessage(item, mostRecently),
      discardLabel: l10n.conflictDiscardChangesButton,
      saveLabel: l10n.linkedNoteDeleteButton,
      isSaveDestructive: true,
    );
  }
  return ConflictMessage(
    title: l10n.conflictChangedTitle,
    body: mostRecently == null
        ? l10n.linkedNoteBothChangedSaveMessage(item)
        : l10n.linkedNoteBothChangedAtSaveMessage(item, mostRecently),
    discardLabel: l10n.conflictDiscardChangesButton,
    saveLabel: l10n.conflictSaveChangesButton,
  );
}
