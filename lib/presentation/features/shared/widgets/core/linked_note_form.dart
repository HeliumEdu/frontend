import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/domain/linked_note_saver.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/shared/controllers/linked_note_form_fields.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
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
  ({int? homeworkId, int? eventId, int? resourceId}) get linkedItem;

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
    );
  }
}

/// Settles a save where the item or its linked note didn't save: asks how to
/// resolve a newer version, or, when only the note failed, keeps the form open
/// with the saved item and the unsaved note. [savedEntity] is set when the
/// item saved.
void resolveLinkedNoteConflict<T>(
  BuildContext context,
  LinkedNoteForm<StatefulWidget, T>? form, {
  T? savedEntity,
  LinkedNoteSave? linkedNoteSave,
}) {
  if (form == null) return;
  final isNoteConflict = linkedNoteSave?.isConflict ?? false;

  form.resetSubmitting();
  form.applyConflict(savedEntity: savedEntity, linkedNoteSave: linkedNoteSave);
  if (linkedNoteSave?.failure case final failure?) {
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
    wording: _wordingFor(
      form,
      isItemConflict: savedEntity == null,
      isNoteConflict: isNoteConflict,
    ),
  );
}

ConflictWording _wordingFor(
  LinkedNoteForm<StatefulWidget, dynamic> form, {
  required bool isItemConflict,
  required bool isNoteConflict,
}) {
  if (!isNoteConflict) return const ConflictWording();

  final noun = form.itemNoun;
  final deletesNote = form.linkedNoteFields.overwriteDeletesNote;
  final overwriteLabel = deletesNote ? 'Delete Note' : 'Overwrite';

  if (!isItemConflict) {
    final overwrite = deletesNote
        ? 'delete the note, including the changes from the other device'
        : 'overwrite it with yours';
    return ConflictWording(
      title: 'Note Changed on Another Device',
      message:
          "This $noun's note changed on another device after you opened it. "
          'Your other changes are saved. Load the latest note and discard '
          'your note changes, or $overwrite?',
      overwriteLabel: overwriteLabel,
    );
  }

  final overwrite = deletesNote
      ? 'overwrite the $noun with your changes and delete its note, including '
            'the changes from the other device'
      : 'overwrite them with your changes';
  return ConflictWording(
    message:
        'This $noun and its note changed on another device after you opened '
        'it. Load the latest version and discard your changes, or $overwrite?',
    overwriteLabel: overwriteLabel,
  );
}
