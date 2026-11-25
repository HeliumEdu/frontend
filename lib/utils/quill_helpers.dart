import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
// ignore: implementation_imports
import 'package:flutter_quill/src/editor/raw_editor/keyboard_shortcuts/editor_keyboard_shortcut_actions.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/forwarding_localizations.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

class HeliumQuillLocalizations extends ForwardingQuillLocalizations {
  final AppLocalizations _app;

  HeliumQuillLocalizations(super.base, this._app);

  @override
  String get pleaseEnterTheLinkURL => _app.noteLinkUrlLabel;

  @override
  String get pleaseEnterTextForYourLink => _app.noteLinkTextLabel;
}

class HeliumQuillLocalizationsDelegate
    extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const HeliumQuillLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale) &&
      FlutterQuillLocalizations.delegate.isSupported(locale);

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) => SynchronousFuture(
        HeliumQuillLocalizations(
          lookupFlutterQuillLocalizations(locale),
          lookupAppLocalizations(locale),
        ),
      );

  @override
  bool shouldReload(covariant LocalizationsDelegate<FlutterQuillLocalizations> old) => false;
}

/// Checks if a Quill Delta JSON map represents empty content.
/// Returns true if notes is null, has no ops, or only contains a newline.
bool isNotesEmpty(Map<String, dynamic>? notes) {
  if (notes == null) return true;
  final ops = notes['ops'];
  if (ops is! List || ops.isEmpty) return true;
  if (ops.length == 1 && ops[0]['insert'] == '\n') return true;
  return false;
}

/// Returns true if [change] was triggered by the user (not programmatic),
/// indicating the document has been meaningfully edited.
bool isNoteEdited(DocChange change) => change.source == ChangeSource.local;

/// Attempts to parse a Quill Document from a Note's `content` map. Returns
/// null if [notes] is null or the content is malformed. Parse failures are
/// logged and reported to Sentry.
Document? tryParseNotesDocument(Map<String, dynamic>? notes) {
  if (notes == null) return null;
  try {
    return Document.fromJson(_ensureTrailingNewline(notes['ops'] as List));
  } catch (e, stack) {
    ErrorHelpers.logAndReport('Quill note content failed to parse', e, stack);
    return null;
  }
}

/// Quill requires a document to end in a newline. Content lacking it (e.g. a
/// note ending in text or an embed) parses into a child-less document
/// that crashes flutter_quill's hit-testing on tap. Returns [ops] terminated,
/// leaving an empty list for [Document.fromJson] to reject into the placeholder.
List<dynamic> _ensureTrailingNewline(List<dynamic> ops) {
  if (ops.isEmpty) return ops;
  final last = ops.last;
  final insert = last is Map ? last['insert'] : null;
  if (insert is String && insert.endsWith('\n')) return ops;
  return [...ops, {'insert': '\n'}];
}

/// An unrenderable note comes back as a placeholder the editor must never save.
({Document document, bool isRenderable}) notesDocumentFor(
  Map<String, dynamic>? notes,
) {
  if (isNotesEmpty(notes)) return (document: Document(), isRenderable: true);
  final document = tryParseNotesDocument(notes);
  if (document == null) {
    return (document: _unrenderableNotePlaceholder(), isRenderable: false);
  }
  return (document: document, isRenderable: true);
}

/// The content of [notes] as the editor holds it once loaded.
Delta editorDeltaFor(Map<String, dynamic>? notes) =>
    notesDocumentFor(notes).document.toDelta();

Document _unrenderableNotePlaceholder() {
  return Document.fromJson([
    {
      'insert': 'This note is not in a valid format and cannot be loaded.',
      'attributes': {'italic': true},
    },
    {'insert': '\n'},
  ]);
}

/// Creates a [QuillController] pre-configured with Helium's clipboard settings:
/// rich-paste enabled on native platforms, and the web paste interceptor
/// activated on web. Where [PlatformBehavior.typesTabAsText], Tab follows
/// Quill's desktop rule ([allowsTypedText]). Pass an optional [document] to
/// pre-populate content; omit it for a blank controller.
QuillController heliumQuillController({Document? document}) {
  // ignore: experimental_member_use
  final clipboardConfig = QuillClipboardConfig(
    // ignore: experimental_member_use
    enableExternalRichPaste: !kIsWeb,
    // ignore: experimental_member_use
    onClipboardPaste: kIsWeb ? () async => true : null,
  );
  // ignore: experimental_member_use
  final config = QuillControllerConfig(clipboardConfig: clipboardConfig);
  final controller = document != null
      ? QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
          config: config,
        )
      : QuillController.basic(config: config);
  if (PlatformBehavior.typesTabAsText) {
    controller.onReplaceText = (index, len, data) =>
        allowsTypedText(controller, index, len, data);
  }
  return controller;
}

/// Where Tab reaches the editor only as a typed tab
/// ([PlatformBehavior.typesTabAsText]), applies flutter_quill's desktop Tab
/// rule: in a list, Tab at the start of a line or over a selection indents
/// (Shift+Tab outdents); over a selection outside a list it does nothing;
/// anywhere else it types a tab. Returns whether the typed text goes in.
@visibleForTesting
bool allowsTypedText(QuillController controller, int index, int len, Object? data) {
  if (data != '\t') return true;
  final node = controller.document.queryChild(index).node;
  final parent = node?.parent;
  final isListLine = node is Line &&
      parent is Block &&
      (parent.style.containsKey(Attribute.ol.key) ||
          parent.style.containsKey(Attribute.ul.key) ||
          parent.style.containsKey(Attribute.checked.key));
  if (len == 0) {
    if (!isListLine) return true;
    final first = node.isEmpty ? null : node.first;
    if (first != null && first is! QuillText) return true;
    if (first is QuillText &&
        first.value.isNotEmpty &&
        index > node.documentOffset) {
      return true;
    }
  }
  final outdent = HardwareKeyboard.instance.isShiftPressed;
  scheduleMicrotask(() {
    if (isListLine) controller.indentSelection(!outdent);
    controller.updateSelection(controller.selection, ChangeSource.local);
  });
  return false;
}

/// Cmd versions of flutter_quill's formatting and undo shortcuts, for
/// [PlatformBehavior.usesCommandForNoteShortcuts], where Quill binds them to
/// Ctrl. Search (Cmd+F) is left to the editor's own configuration.
final Map<ShortcutActivator, Intent> heliumCommandNoteShortcuts = {
  const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
      const UndoTextIntent(SelectionChangedCause.keyboard),
  const SingleActivator(LogicalKeyboardKey.keyY, meta: true):
      const RedoTextIntent(SelectionChangedCause.keyboard),
  const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
      const RedoTextIntent(SelectionChangedCause.keyboard),
  const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
      const ToggleTextStyleIntent(Attribute.bold),
  const SingleActivator(LogicalKeyboardKey.keyU, meta: true):
      const ToggleTextStyleIntent(Attribute.underline),
  const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
      const ToggleTextStyleIntent(Attribute.italic),
  const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true):
      const ToggleTextStyleIntent(Attribute.strikeThrough),
  const SingleActivator(LogicalKeyboardKey.backquote, meta: true):
      const ToggleTextStyleIntent(Attribute.inlineCode),
  const SingleActivator(LogicalKeyboardKey.tilde, meta: true, shift: true):
      const ToggleTextStyleIntent(Attribute.codeBlock),
  const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true):
      const ToggleTextStyleIntent(Attribute.blockQuote),
  const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
      const QuillEditorApplyLinkIntent(),
  const SingleActivator(LogicalKeyboardKey.keyL, meta: true, shift: true):
      const ToggleTextStyleIntent(Attribute.ul),
  const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true):
      const ToggleTextStyleIntent(Attribute.ol),
  const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true):
      const QuillEditorApplyCheckListIntent(),
  const SingleActivator(LogicalKeyboardKey.keyM, meta: true):
      const IndentSelectionIntent(true),
  const SingleActivator(LogicalKeyboardKey.keyM, meta: true, shift: true):
      const IndentSelectionIntent(false),
  for (final (key, header) in [
    (LogicalKeyboardKey.digit1, Attribute.h1),
    (LogicalKeyboardKey.digit2, Attribute.h2),
    (LogicalKeyboardKey.digit3, Attribute.h3),
    (LogicalKeyboardKey.digit4, Attribute.h4),
    (LogicalKeyboardKey.digit5, Attribute.h5),
    (LogicalKeyboardKey.digit6, Attribute.h6),
    (LogicalKeyboardKey.digit0, Attribute.header),
  ])
    SingleActivator(key, meta: true): QuillEditorApplyHeaderIntent(header),
};

/// Builds a Quill Delta JSON map from a QuillController.
/// Returns null if the content is empty (only whitespace/newline).
Map<String, dynamic>? buildNotesDelta(QuillController controller) {
  final delta = controller.document.toDelta();
  final ops = delta.toJson();
  if (ops.isEmpty || (ops.length == 1 && ops[0]['insert'] == '\n')) {
    return null;
  }
  return {'ops': ops};
}
