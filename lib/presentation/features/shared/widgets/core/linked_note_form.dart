import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/controllers/linked_note_form_fields.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

const noteRecreatedMessage =
    'This note was deleted on another device, so it was saved as a new note.';

/// A form that saves an item of type [T] together with its linked note, where
/// either save can lose to a newer version.
mixin LinkedNoteForm<W extends StatefulWidget, T> on ConflictResolvableForm<W> {
  bool _isEntityConflict = false;
  bool _redirectToNotebook = false;

  LinkedNoteFormFields get linkedNoteFields;

  /// What the item is called in messages, like "assignment".
  String get itemNoun;

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
      'Your other changes are saved, but the note failed to save: '
      '${failure.message}',
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
      form,
      isItemConflict: savedEntity == null,
      latestVersion: latestVersion,
      latestNote: isNoteConflict ? linkedNoteSave?.note : null,
    ),
  );
}

ConflictMessage _messageFor(
  LinkedNoteForm<StatefulWidget, dynamic> form, {
  required bool isItemConflict,
  required String? latestVersion,
  required NoteModel? latestNote,
}) {
  final noun = form.itemNoun;
  if (latestNote == null) {
    return ConflictMessage.changedAt(latestVersion, subject: 'This $noun');
  }

  final deletesNote = form.linkedNoteFields.overwriteDeletesNote;

  if (!isItemConflict) {
    final noteChanged = describeVersionSaved(latestNote.version);
    final when = noteChanged == null ? '' : ' $noteChanged,';
    final changed =
        "Your other changes are saved, but this $noun's note changed on "
        'another device$when after you opened it.';
    if (deletesNote) {
      return ConflictMessage(
        title: 'Note Changed on Another Device',
        body: '$changed Delete the note anyway, including those changes?',
        discardLabel: 'Keep Note',
        saveLabel: 'Delete Note',
        isSaveDestructive: true,
      );
    }
    return ConflictMessage(
      title: 'Note Changed on Another Device',
      body: '$changed Save your note changes over that version?',
    );
  }

  final mostRecently = describeVersionSaved(
    HeliumDateTime.laterTimestamp(latestVersion, latestNote.version),
  );
  final when = mostRecently == null ? '' : ', most recently $mostRecently';
  final changed =
      'This $noun and its note changed on another device after you opened '
      'it$when.';
  if (deletesNote) {
    return ConflictMessage(
      body: '$changed Save your changes and delete the note?',
      saveLabel: 'Delete Note',
      isSaveDestructive: true,
    );
  }
  return ConflictMessage(
    body: '$changed Save your changes over those versions?',
  );
}
