// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/dirty_dialog_registry.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/generic_label.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_editor.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/discard_changes_scope.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/print_service.dart';
import 'package:heliumapp/utils/quill_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/search_helpers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sentry_flutter/sentry_flutter.dart';

enum SaveStatus { unsaved, saving, saved, error }

/// Pushes the note editor route on the notebook shell.
///
/// Linked-entity context (homework, event, resource) rides as query params
/// on the note URL so the link survives browser refresh / sharing. A
/// deep-link edit ignores these — the note's own model carries the relation.
Future<void> showNoteAdd(
  BuildContext context, {
  required bool isNew,
  int? noteId,
  int? linkHomeworkId,
  int? linkEventId,
  int? linkResourceId,
}) {
  final id = noteId?.toString() ?? 'new';
  final queryParameters = <String, String>{
    if (linkHomeworkId != null)
      DeepLinkParam.linkHomeworkId: linkHomeworkId.toString(),
    if (linkEventId != null) DeepLinkParam.linkEventId: linkEventId.toString(),
    if (linkResourceId != null)
      DeepLinkParam.linkResourceId: linkResourceId.toString(),
  };
  final target = Uri(
    path: '${AppRoute.notebookScreen}/$id',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
  final currentUri = router.routerDelegate.currentConfiguration.uri;
  if (currentUri.toString() == target) {
    // Already on this exact route; avoid duplicate push that would stack
    // a second dialog page with the same shared key.
    return Future.value();
  }
  return context.push<void>(target);
}

class NoteAddScreen extends StatefulWidget {
  /// Shell path the dialog is overlaying — used to build the dialog's
  /// dirty-guard prefix and to resolve the underlying screen on dismissal.
  final String shellPath;

  final bool isNew;
  final int? noteId;
  final int? linkHomeworkId;
  final int? linkEventId;
  final int? linkResourceId;

  /// Full URL the route was matched at — passed in from the pageBuilder so
  /// the dialog's dirty-guard registration captures the active path without
  /// racing against `routerDelegate.currentConfiguration`, which lags push.
  final String initialFullPath;

  const NoteAddScreen({
    super.key,
    required this.shellPath,
    required this.isNew,
    required this.initialFullPath,
    this.noteId,
    this.linkHomeworkId,
    this.linkEventId,
    this.linkResourceId,
  });

  @override
  State<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends BasePageScreenState<NoteAddScreen>
    with WidgetsBindingObserver {
  static const _autoSaveDebounce = Duration(seconds: 1);

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  PrintHandler? _printHandler;

  NoteModel? _note;
  int? _currentNoteId;
  String? _linkedEntityType;
  String? _linkedEntityTitle;
  Color? _linkedEntityColor;
  bool? _linkedEntityCompleted;
  bool _showSearch = false;
  bool _hasRequestedInitialFocus = false;
  String? _registeredPrefix;

  // Link picker state
  bool _showLinkPicker = false;
  bool _isPickerLoading = false;
  bool _isLinking = false;
  bool _pendingUnlink = false;
  String _linkPickerType = 'homework';
  final TextEditingController _linkPickerSearchController =
      TextEditingController();
  List<HomeworkModel> _linkableHomework = [];
  List<EventModel> _linkableEvents = [];
  List<ResourceModel> _linkableResources = [];
  List<CourseModel> _linkableCourses = [];
  List<ResourceGroupModel> _linkableResourceGroups = [];

  // Auto-save state
  SaveStatus _saveStatus = SaveStatus.saved;
  Timer? _debounceTimer;
  bool _isAutoSaving = false;
  int _autoSaveErrorCount = 0;
  bool _isDiscardDialogOpen = false;
  StreamSubscription<DocChange>? _documentSubscription;

  String? _pendingRedirectRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentNoteId = widget.noteId;
    _quillController = heliumQuillController();
    _saveStatus = widget.noteId == null ? SaveStatus.unsaved : SaveStatus.saved;

    _titleController.addListener(_onContentChanged);
    _printHandler = _printNote;
    PrintService().register(_printHandler!);

    _registerDirtyGuard();
    router.routerDelegate.addListener(_syncFromUrl);

    context.read<NoteBloc>().add(
      FetchNoteScreenDataEvent(
        origin: EventOrigin.subScreen,
        noteId: widget.noteId,
        linkHomeworkId: widget.linkHomeworkId,
        linkEventId: widget.linkEventId,
        linkResourceId: widget.linkResourceId,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_debounceTimer?.isActive == true) {
        _debounceTimer!.cancel();
        _triggerAutoSave();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.routerDelegate.removeListener(_syncFromUrl);
    if (_registeredPrefix != null) {
      DirtyDialogRegistry.unregister(_registeredPrefix!);
    }
    PrintService().unregister(_printHandler);
    _debounceTimer?.cancel();
    _documentSubscription?.cancel();
    _titleController.removeListener(_onContentChanged);
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _linkPickerSearchController.dispose();
    super.dispose();
  }

  /// Registers (or re-registers, after a new-note save mints a real ID)
  /// this dialog with the dirty-dialog guard so URL-driven dismissals can't
  /// silently lose unsaved changes.
  void _registerDirtyGuard() {
    final prefix = '${widget.shellPath}/${_currentNoteId?.toString() ?? 'new'}';
    final routerPath = router.routerDelegate.currentConfiguration.uri.path;
    // Prefer the routerDelegate's settled path if it already matches our
    // dialog (e.g. after a new-note save); otherwise fall back to the URL
    // the pageBuilder matched on, which is authoritative for the active
    // route even when the routerDelegate hasn't caught up yet.
    final fullPath = routerPath.startsWith(prefix)
        ? routerPath
        : widget.initialFullPath;
    DirtyDialogRegistry.register(
      prefix: prefix,
      fullPath: fullPath,
      isDirty: () => isDirty,
    );
    _registeredPrefix = prefix;
  }

  void _syncFromUrl() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final prefix = _registeredPrefix;
    if (prefix != null && path.startsWith(prefix)) {
      DirtyDialogRegistry.updateFullPath(prefix: prefix, fullPath: path);
    }
  }

  bool get isDirty {
    return _saveStatus == SaveStatus.unsaved || _saveStatus == SaveStatus.error;
  }

  Duration get _effectiveDebounce {
    if (_autoSaveErrorCount == 0) return _autoSaveDebounce;
    return Duration(
      seconds: math.min(60, 5 * (1 << (_autoSaveErrorCount - 1))),
    );
  }

  @override
  String get screenTitle => widget.isNew ? 'Add Note' : 'Edit Note';

  @override
  IconData get icon => Icons.library_books;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function get cancelAction => _cancelAndClose;

  @override
  Function? get saveAction => _saveAndClose;

  @override
  List<Widget> get additionalHeaderButtons {
    if (_note == null) return const [];
    return [
      Semantics(
        label: 'Delete',
        button: true,
        child: HeliumIconButton(
          onPressed: _onDelete,
          icon: Icons.delete_outline,
          color: context.colorScheme.error,
        ),
      ),
    ];
  }

  @override
  List<Widget> get additionalRightHeaderButtons {
    if (_note == null && widget.noteId != null) return const [];
    return [_buildSyncStatusIcon()];
  }

  void _closeImmediately() {
    if (!mounted) return;
    final redirect = _pendingRedirectRoute;
    if (redirect != null) {
      _pendingRedirectRoute = null;
      DirtyDialogRegistry.releaseActive();
      navigateAndClearStack(context, redirect);
      return;
    }
    DirtyDialogRegistry.releaseActive();
    context.pop();
  }

  void _onDelete() {
    if (_note == null) return;
    showConfirmDeleteDialog<NoteModel>(
      parentContext: context,
      item: _note!,
      onDelete: (note) {
        setState(() {
          isSubmitting = true;
        });
        context.read<NoteBloc>().add(
          DeleteNoteEvent(origin: EventOrigin.subScreen, noteId: note.id),
        );
      },
    );
  }

  Future<void> _cancelAndClose() async {
    if ((isDirty && !_isNoteEmpty) || _pendingUnlink) {
      _debounceTimer?.cancel();
      _isDiscardDialogOpen = true;
      final shouldDiscard = await confirmDiscardChanges(context);
      _isDiscardDialogOpen = false;
      if (!mounted) return;
      if (!shouldDiscard) return;
    }
    _closeImmediately();
  }

  void _saveAndClose() {
    if (!mounted) return;

    // Initial fetch still in flight; nothing to save
    if (isLoading) {
      _closeImmediately();
      return;
    }

    // Manual save already in flight; bloc listener will close on completion
    if (_saveStatus == SaveStatus.saving && !_isAutoSaving) return;

    if (_isNoteEmpty) {
      _closeImmediately();
      return;
    }

    if (_saveStatus == SaveStatus.saved) {
      _closeImmediately();
      return;
    }

    if (!_formController.validateAndScrollToError()) {
      _pendingRedirectRoute = null;
      showSnackBar(
        context,
        'Fix the highlighted fields, then try again.',
        type: SnackType.error,
      );
      return;
    }

    // New linked note with empty body: skip stub creation
    final bodyIsEmpty = _quillController.document.toPlainText().trim().isEmpty;
    if (_note?.id == null &&
        (widget.linkEventId != null ||
            widget.linkHomeworkId != null ||
            widget.linkResourceId != null) &&
        bodyIsEmpty) {
      showSnackBar(
        context,
        'Note was empty, so nothing to save.',
        useRootMessenger: true,
      );
      _closeImmediately();
      return;
    }

    // Auto-save in flight: upgrade to manual so bloc listener closes
    if (_saveStatus == SaveStatus.saving && _isAutoSaving) {
      setState(() {
        _isAutoSaving = false;
        isSubmitting = true;
      });
      return;
    }

    _performSave(isAutoSave: false);
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError) {
            if (isLoading) {
              showSnackBar(
                context,
                state.message!,
                type: SnackType.error,
                useRootMessenger: true,
              );
              _closeImmediately();
            } else if (_isPickerLoading) {
              setState(() {
                _isPickerLoading = false;
                _showLinkPicker = false;
              });
              showSnackBar(context, state.message!, type: SnackType.error);
            } else if (_isAutoSaving) {
              if (_isLinking) {
                setState(() { _isLinking = false; isSubmitting = false; });
              } else if (_note == null) {
                setState(() => isSubmitting = false);
              }
              _handleAutoSaveError(state.message!);
              _isAutoSaving = false;
            } else {
              setState(() => isSubmitting = false);
              _handleAutoSaveError('Manual save failed');
            }
          } else if (state is NoteScreenDataFetched) {
            setState(() {
              _linkedEntityType = state.linkedEntityType;
              _linkedEntityTitle = state.linkedEntityTitle;
              _linkedEntityColor = state.linkedEntityColor;
              _linkedEntityCompleted = state.linkedEntityCompleted;
            });
            if (state.note != null) {
              _populateNoteData(state.note!);
            } else {
              // New note - set up document listener and clear loading
              _setupDocumentListener();
              setState(() => isLoading = false);
            }

            // Request focus once on mobile for create mode
            if (!_hasRequestedInitialFocus && !kIsWeb && _note?.id == null) {
              _hasRequestedInitialFocus = true;
              // Defer focus request so the text field is attached to the tree
              // before requestFocus is called; BLoC listeners run during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _titleFocusNode.requestFocus();
              });
            }
          } else if (state is NoteCreated) {
            if (_isAutoSaving) {
              // Auto-save created the note - update state but don't close
              setState(() {
                isSubmitting = false;
                _note = state.note;
                _currentNoteId = state.note.id;
                _saveStatus = SaveStatus.saved;
                _autoSaveErrorCount = 0;
              });
              _isAutoSaving = false;
              _onContentChanged();
              // Auto-save minted a real ID — the URL prefix that the
              // dirty-dialog guard owns has changed (`/notebook/new`
              // → `/notebook/<id>`), so swap the registration before
              // the URL update so the listener doesn't tear down the new
              // slot mid-transition.
              if (_registeredPrefix != null) {
                DirtyDialogRegistry.unregister(_registeredPrefix!);
              }
              _registerDirtyGuard();
              if (!Responsive.isMobile(context)) {
                context.go(
                  '${widget.shellPath}/${state.note.id}',
                );
              }
              showSnackBar(context, 'Note created.');
            } else {
              // Manual save - show message and close
              showSnackBar(context, 'Note created.', useRootMessenger: true);
              _closeImmediately();
            }
          } else if (state is LinkableEntitiesFetched) {
            setState(() {
              _isPickerLoading = false;
              _linkableHomework = state.homework;
              _linkableEvents = state.events;
              _linkableResources = state.resources;
              _linkableCourses = state.courses;
              _linkableResourceGroups = state.resourceGroups;
            });
          } else if (state is NoteUpdated) {
            if (_isAutoSaving) {
              // Auto-save or link change updated the note - update state but don't close
              setState(() {
                if (_isLinking) isSubmitting = false;
                _isLinking = false;
                _pendingUnlink = false;
                _note = state.note;
                _saveStatus = SaveStatus.saved;
                _autoSaveErrorCount = 0;
                _linkedEntityType = state.note.linkedEntityType.isEmpty
                    ? null
                    : state.note.linkedEntityType;
                _linkedEntityTitle = state.note.linkedEntityTitle;
                _linkedEntityCompleted = state.note.linkedEntityCompleted;
                _linkedEntityColor = state.note.courseColor ?? state.note.categoryColor;
              });
              _isAutoSaving = false;
              _onContentChanged();
            } else {
              // Manual save - close
              _pendingUnlink = false;
              _closeImmediately();
            }
          } else if (state is NoteDeleted) {
            showSnackBar(context, 'Note deleted.', useRootMessenger: true);
            _closeImmediately();
          }
        },
      ),
    ];
  }

  @override
  Widget buildMainArea(BuildContext context) {
    if (isLoading) {
      return const LoadingIndicator();
    }

    final isCompact = Responsive.useCompactLayout(context);

    return Expanded(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _cancelAndClose();
        },
        child: isCompact
            ? _buildCompactLayout(context, isCompact)
            : _buildDesktopLayout(context, isCompact),
      ),
    );
  }

  String _getSavedContentAsJson() {
    if (_note?.content == null || _note!.content!['ops'] == null) {
      return '';
    }
    return jsonEncode(_note!.content!['ops']);
  }

  void _onContentChanged() {
    if (isLoading || _saveStatus == SaveStatus.saving || _isDiscardDialogOpen) {
      return;
    }

    // Check if content actually changed from last saved state, comparing Delta
    // JSON so that formatting-only changes (bold, italic, etc.) are detected
    final currentTitle = _titleController.text;
    final currentContent = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );
    final savedTitle = _note?.title ?? '';
    final savedContent = _getSavedContentAsJson();
    if (currentTitle == savedTitle && currentContent == savedContent) {
      return;
    }

    setState(() {
      // Preserve error state — icon stays red until a save actually succeeds
      if (_saveStatus != SaveStatus.error) _saveStatus = SaveStatus.unsaved;
    });

    // For new notes, only auto-save once title OR body is non-empty
    final isNewNote = _note == null;
    if (isNewNote) {
      final hasTitle = currentTitle.trim().isNotEmpty;
      final hasBody = _quillController.document.toPlainText().trim().isNotEmpty;
      if (!hasTitle && !hasBody) return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_effectiveDebounce, _triggerAutoSave);
  }

  void _triggerAutoSave() {
    if (_saveStatus == SaveStatus.saving || _isAutoSaving || _isDiscardDialogOpen) return;

    final title = _titleController.text.trim();
    final bodyIsEmpty = _quillController.document.toPlainText().trim().isEmpty;

    // Require at least title or body
    if (title.isEmpty && bodyIsEmpty) return;

    _performSave(isAutoSave: true);
  }

  bool get _isNoteEmpty {
    final title = _titleController.text.trim();
    final bodyIsEmpty = _quillController.document.toPlainText().trim().isEmpty;
    return title.isEmpty && bodyIsEmpty;
  }

  void _performSave({required bool isAutoSave}) {
    _debounceTimer?.cancel();

    setState(() {
      if (_saveStatus != SaveStatus.error) _saveStatus = SaveStatus.saving;
      _isAutoSaving = isAutoSave;
      if (!isAutoSave || _note?.id == null) isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final content = _quillController.document.toDelta().toJson();

    if (_note?.id == null) {
      context.read<NoteBloc>().add(
        CreateNoteEvent(
          origin: EventOrigin.subScreen,
          request: NoteRequestModel(
            title: title,
            content: {'ops': content},
            homeworkId: widget.linkHomeworkId,
            eventId: widget.linkEventId,
            resourceId: widget.linkResourceId,
          ),
        ),
      );
    } else {
      context.read<NoteBloc>().add(
        UpdateNoteEvent(
          origin: EventOrigin.subScreen,
          noteId: _note!.id,
          request: NoteRequestModel(
            title: title,
            content: {'ops': content},
            clearLinks: _pendingUnlink,
          ),
        ),
      );
      _pendingUnlink = false;
    }
  }

  void _handleAutoSaveError(String message) {
    _autoSaveErrorCount++;

    AnalyticsService().logEvent(
      name: AnalyticsEvent.debugNoteAutosaveError,
      parameters: {'category': AnalyticsCategory.edgeCase.value},
    );
    Sentry.captureMessage(
      'Note autosave failed',
      level: SentryLevel.error,
      withScope: (scope) =>
          scope.setContexts('autosave_error', {'error': message}),
    );

    setState(() => _saveStatus = SaveStatus.error);

    // Reuse debounce slot to schedule background retry with backoff
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_effectiveDebounce, _triggerAutoSave);
  }

  void _setupDocumentListener() {
    _documentSubscription?.cancel();
    _documentSubscription = _quillController.document.changes.listen((change) {
      if (!isNoteEdited(change)) return;
      _onContentChanged();
    });
  }

  void _populateNoteData(NoteModel note) {
    _note = note;
    _titleController.text = note.title;

    if (note.content != null) {
      _quillController.document =
          tryParseNotesDocument(note.content) ?? buildUnrenderableNotePlaceholder();
    }

    _setupDocumentListener();
    _saveStatus = SaveStatus.saved;

    // Delay clearing isLoading to ignore async document change events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => isLoading = false);
    });
  }

  Widget _buildDesktopLayout(BuildContext context, bool isCompact) {
    return Form(
      key: _formController.formKey,
      child: Column(
        children: [
          _buildTitleRow(context),
          if (_showLinkPicker) _buildLinkPicker(context),
          Expanded(child: _buildEditorContainer(context, isCompact)),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, bool isCompact) {
    const double titleRowHeight = 64;
    const double minEditorContainerHeight = 260;

    return LayoutBuilder(
      builder: (context, constraints) {
        final editorContainerHeight = (constraints.maxHeight - titleRowHeight)
            .clamp(minEditorContainerHeight, double.infinity);

        return SingleChildScrollView(
          child: Form(
            key: _formController.formKey,
            child: Column(
              children: [
                _buildTitleRow(context),
                if (_showLinkPicker) _buildLinkPicker(context),
                SizedBox(
                  height: editorContainerHeight,
                  child: _buildEditorContainer(context, isCompact),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditorContainer(BuildContext context, bool isCompact) {
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: isCompact ? 2 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuillToolbar(context, isCompact),
              const Divider(height: 1),
              Expanded(
                child: HeliumQuillEditor(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  config: QuillEditorConfig(
                    padding: const EdgeInsets.all(12),
                    autoFocus: false,
                    expands: true,
                    customStyles: NotesEditor.buildDefaultStyles(context),
                    scrollBottomInset: MediaQuery.of(context).viewInsets.bottom,
                    // ignore: experimental_member_use
                    onKeyPressed: (event, node) {
                      final isFindShortcut =
                          event.logicalKey == LogicalKeyboardKey.keyF &&
                          (HardwareKeyboard.instance.isMetaPressed ||
                              HardwareKeyboard.instance.isControlPressed);
                      if (isFindShortcut) {
                        setState(() {
                _showSearch = !_showSearch;
              });
                        return KeyEventResult.handled;
                      }
                      return null;
                    },
                  ),
                ),
              ),
              if (_showSearch)
                QuillSearchBar(
                  controller: _quillController,
                  onClose: () {
                    setState(() {
                      _showSearch = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double titleMinWidth = 225;
          const double badgeMaxWidth = 250;
          const double gap = 8;
          final hasBadge = _linkedEntityType != null || _note != null;
          final effectiveBadgeMax = hasBadge
              ? (constraints.maxWidth - titleMinWidth - gap * 2).clamp(
                  0.0,
                  badgeMaxWidth,
                )
              : 0.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LabelAndTextFormField(
                  hintText: 'Title',
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  autofocus: kIsWeb,
                  validator: null,
                  fieldKey: _formController.getFieldKey('title'),
                  onFieldSubmitted: (_) => saveAction?.call(),
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: gap),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: effectiveBadgeMax),
                  child: _buildLinkedEntityBadge(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuillToolbar(BuildContext context, bool isCompact) {
    final isPhoneLandscape = Responsive.isPhoneLandscape(context);
    final baseOptions = HeliumQuillToolbar.defaultButtonOptions(context);
    return HeliumQuillToolbar(
      controller: _quillController,
      config: QuillSimpleToolbarConfig(
        toolbarRunSpacing: 0,
        toolbarSectionSpacing: 8,
        customButtons: [
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: _printNote,
          ),
        ],
        showDividers: !isCompact,
        showFontSize: !isCompact,
        showHeaderStyle: !isCompact,
        showInlineCode: !isCompact,
        showClearFormat: !isCompact,
        showStrikeThrough: !isCompact,
        showAlignmentButtons: !isCompact,
        showLeftAlignment: !isCompact,
        showCenterAlignment: !isCompact,
        showRightAlignment: !isCompact,
        showCodeBlock: !isCompact,
        showUnderLineButton: !isCompact,
        showIndent: !isCompact,
        showSubscript: !isCompact,
        showSuperscript: !isCompact,
        showBackgroundColorButton: !isCompact,
        showRedo: !isCompact,
        showSearchButton: !isPhoneLandscape,
        buttonOptions: QuillSimpleToolbarButtonOptions(
          search: QuillToolbarSearchButtonOptions(
            customOnPressedCallback: (_) async {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          base: baseOptions.base,
          color: baseOptions.color,
          backgroundColor: baseOptions.backgroundColor,
        ),
      ),
    );
  }

  Widget _buildSyncStatusIcon() {
    final IconData icon;
    final Color color;
    final String tooltip;

    if (_saveStatus == SaveStatus.error) {
      icon = Icons.cloud_off_outlined;
      color = context.colorScheme.error;
      tooltip = 'Auto-save failed, will retry';
    } else if (_note == null) {
      icon = Icons.cloud_outlined;
      color = context.colorScheme.onSurface.withValues(alpha: 0.5);
      tooltip = 'Auto-save not yet active';
    } else {
      icon = Icons.cloud_outlined;
      color = context.colorScheme.primary;
      tooltip = 'Auto-save active';
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> _printNote() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_linkedEntityTitle ?? '');
    final delta = _quillController.document.toDelta();

    if (!mounted) return;

    await showBuiltPdfPreview(
      context,
      pdfBytesFuture: _buildNotePdf(delta),
      title: title.isNotEmpty ? title : 'Note Preview',
      filename: title.isNotEmpty ? '$title.pdf' : 'note.pdf',
    );
  }

  Future<Uint8List> _buildNotePdf(Delta delta) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoSans = pw.Font.ttf(fontData);

    final converter = PDFConverter(
      pageFormat: PDFPageFormat.a4,
      document: delta,
      fallbacks: [notoSans],
      // ignore: experimental_member_use
      listLeadingBuilder: _buildPdfCheckbox,
      themeData: pw.ThemeData.withFont(
        base: notoSans,
        bold: notoSans,
        italic: notoSans,
        boldItalic: notoSans,
      ),
      onRequestFontFamily: (_) => FontFamilyResponse(
        fontNormalV: notoSans,
        boldFontV: notoSans,
        italicFontV: notoSans,
        boldItalicFontV: notoSans,
      ),
    );

    final document = await converter.createDocument();
    if (document == null) throw Exception('Failed to create PDF.');
    return document.save();
  }

  static pw.Widget? _buildPdfCheckbox(
    String type,
    int indentLevel,
    Object? extraArgs,
  ) {
    final isChecked = type == 'checked';
    final isUnchecked = type == 'unchecked';
    if (!isChecked && !isUnchecked) return null;

    const double size = 10;
    const double stroke = 1.0;
    return pw.Container(
      width: size,
      height: size,
      margin: const pw.EdgeInsets.only(top: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: stroke),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: isChecked
          ? pw.CustomPaint(
              size: const PdfPoint(size - stroke * 2, size - stroke * 2),
              painter: (canvas, size) {
                final w = size.x;
                final h = size.y;
                canvas
                  ..setLineWidth(1.5)
                  ..setLineCap(PdfLineCap.round)
                  ..setLineJoin(PdfLineJoin.round)
                  ..drawLine(w * 0.15, h * 0.50, w * 0.40, h * 0.20)
                  ..drawLine(w * 0.40, h * 0.20, w * 0.85, h * 0.80)
                  ..strokePath();
              },
            )
          : null,
    );
  }

  Widget _buildLinkedEntityBadge() {
    final entityType = _linkedEntityType ?? '';
    final title = _linkedEntityTitle ?? '';
    // Prefer the loaded note's completion (existing-edit flow) but fall
    // back to the linked-entity fetch's completion (new-note flow).
    final completed = _note?.linkedEntityCompleted ?? _linkedEntityCompleted;
    final strikethrough = completed == true ? TextDecoration.lineThrough : null;

    // Standalone note: show tappable badge with link icon to open the picker.
    if (entityType.isEmpty) {
      final outlineColor = context.colorScheme.outline.withValues(alpha: 0.4);
      final textColor = context.colorScheme.onSurface.withValues(alpha: 0.6);
      return MouseRegion(
        cursor: (_showLinkPicker || _isLinking)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: (_showLinkPicker || _isLinking)
              ? null
              : () {
                  setState(() {
                    _showLinkPicker = true;
                    _isPickerLoading = true;
                  });
                  context.read<NoteBloc>().add(
                    FetchLinkableEntitiesEvent(
                      origin: EventOrigin.subScreen,
                      currentNoteId: _note?.id,
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: outlineColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_link, size: 14, color: textColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Standalone',
                    style: AppStyles.standardBodyText(context)
                        .copyWith(color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final VoidCallback? onDelete =
        (_note != null && !_isLinking) ? _unlinkNote : null;

    final Widget badge;
    if (entityType == 'resource') {
      if (userSettings == null) return const SizedBox.shrink();
      badge = ResourceTitleLabel(
        title: title,
        userSettings: userSettings!,
        textDecoration: strikethrough,
        onDelete: onDelete,
        onDeleteLabel: 'Unlink',
      );
    } else if (entityType == 'event') {
      badge = GenericLabel(
        label: title,
        color: userSettings?.eventsColor ?? FallbackConstants.defaultEventsColor,
        icon: AppConstants.eventIcon,
        textDecoration: strikethrough,
        onDelete: onDelete,
        onDeleteLabel: 'Unlink',
      );
    } else {
      final courseColor = _note?.courseColor ?? _linkedEntityColor;
      final categoryColor = _note?.categoryColor;
      final badgeColor =
          (userSettings?.colorByCategory ?? FallbackConstants.defaultColorByCategory) && categoryColor != null
          ? categoryColor
          : courseColor;
      badge = GenericLabel(
        label: title,
        color: badgeColor ?? FallbackConstants.fallbackColor,
        icon: AppConstants.assignmentIcon,
        textDecoration: strikethrough,
        onDelete: onDelete,
        onDeleteLabel: 'Unlink',
      );
    }

    // For an existing note the link IDs come from the loaded model; for a
    // new note being created via the linked-entity flow they come from the
    // widget params (the IDs the route was opened with).
    final entityId = switch (entityType) {
      'homework' => _note?.homework.firstOrNull ?? widget.linkHomeworkId,
      'event' => _note?.events.firstOrNull ?? widget.linkEventId,
      'resource' => _note?.resources.firstOrNull ?? widget.linkResourceId,
      _ => null,
    };

    Widget badgeWidget = badge;
    if (entityId != null) {
      final route = switch (entityType) {
        'homework' =>
          '${AppRoute.plannerScreen}/$plannerItemHomeworkPath/$entityId/'
              '${plannerItemDialogSteps.first}',
        'event' =>
          '${AppRoute.plannerScreen}/$plannerItemEventPath/$entityId/'
              '${plannerItemDialogSteps.first}',
        'resource' =>
          '${AppRoute.resourcesScreen}/$entityId/${resourceDialogSteps.first}',
        _ => null,
      };
      if (route != null) {
        final tooltip =
            entityType == 'resource' ? 'Open in Resources' : 'Open in Planner';
        badgeWidget = MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: tooltip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _pendingRedirectRoute = route;
                _saveAndClose();
              },
              child: badge,
            ),
          ),
        );
      }
    }

    return badgeWidget;
  }

  void _unlinkNote() {
    if (_note == null) return;
    setState(() {
      _pendingUnlink = true;
      _saveStatus = SaveStatus.unsaved;
      _linkedEntityType = null;
      _linkedEntityTitle = null;
      _linkedEntityColor = null;
      _linkedEntityCompleted = null;
    });
  }

  void _linkNoteTo(String type, int id, String title) {
    if (_note == null) return;
    setState(() {
      _isAutoSaving = true;
      _isLinking = true;
      isSubmitting = true;
      _pendingUnlink = false;
      _saveStatus = SaveStatus.saving;
      _showLinkPicker = false;
      _linkPickerSearchController.clear();
    });
    final request = switch (type) {
      'homework' => NoteRequestModel(homeworkId: id),
      'event' => NoteRequestModel(eventId: id),
      _ => NoteRequestModel(resourceId: id),
    };
    context.read<NoteBloc>().add(
      UpdateNoteEvent(
        origin: EventOrigin.subScreen,
        noteId: _note!.id,
        request: request,
      ),
    );
  }

  Widget _buildLinkPicker(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SegmentedButton<String>(
                        selected: {_linkPickerType},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: Responsive.isMobile(context)
                              ? VisualDensity.compact
                              : null,
                        ),
                        onSelectionChanged: (selected) => setState(() {
                          _linkPickerType = selected.first;
                          _linkPickerSearchController.clear();
                        }),
                        segments: const [
                          ButtonSegment(
                            value: 'homework',
                            icon: Icon(AppConstants.assignmentIcon),
                          ),
                          ButtonSegment(
                            value: 'event',
                            icon: Icon(AppConstants.eventIcon),
                          ),
                          ButtonSegment(
                            value: 'resource',
                            icon: Icon(Icons.book_outlined),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            switch (_linkPickerType) {
                              'event' => 'Link Event',
                              'resource' => 'Link Resource',
                              _ => 'Link Assignment',
                            },
                            style: AppStyles.pageTitle(context).copyWith(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                desktop: 22,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Close',
                        button: true,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _showLinkPicker = false;
                            _linkPickerSearchController.clear();
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        border: Border.all(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TapRegion(
                          onTapOutside: Responsive.isMobile(context)
                              ? (_) => FocusScope.of(context).unfocus()
                              : null,
                          child: TextField(
                            controller: _linkPickerSearchController,
                            style: AppStyles.formText(context),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search ...',
                              hintStyle: AppStyles.formHint(context),
                              prefixIcon: Icon(
                                Icons.search,
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _linkPickerSearchController,
                                builder: (context, value, _) {
                                  if (value.text.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return IconButton(
                                    onPressed: () {
                                      _linkPickerSearchController.clear();
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: context.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                    tooltip: 'Clear',
                                  );
                                },
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 160,
                  child: _isPickerLoading
                      ? const Center(child: LoadingIndicator(expanded: false))
                      : _buildPickerList(context),
                ),
                const SizedBox(height: 4),
              ],
            ),
    );
  }

  Widget _buildPickerList(BuildContext context) {
    final query = _linkPickerSearchController.text.trim();
    final onSurface50 = context.colorScheme.onSurface.withValues(alpha: 0.5);
    final rows = <_LinkPickerRow>[];

    switch (_linkPickerType) {
      case 'homework':
        final courseIndex = {for (final c in _linkableCourses) c.id: c};
        final byGroup = <int, List<HomeworkModel>>{};
        for (final h in _linkableHomework) {
          final courseTitle = courseIndex[h.course.id]?.title ?? '';
          if (query.isEmpty ||
              SearchHelper.matches(h.title, query) ||
              SearchHelper.matches(courseTitle, query)) {
            byGroup.putIfAbsent(h.course.id, () => []).add(h);
          }
        }
        final sortedCourseIds = byGroup.keys.toList()
          ..sort(
            (a, b) => (courseIndex[a]?.title ?? '').compareTo(
              courseIndex[b]?.title ?? '',
            ),
          );
        for (final courseId in sortedCourseIds) {
          final course = courseIndex[courseId];
          rows.add(_LinkGroupHeader(
            title: course?.title ?? '',
            color: course?.color,
          ));
          for (final h in byGroup[courseId]!) {
            rows.add(_LinkPickerItem(id: h.id, title: h.title));
          }
        }

      case 'event':
        for (final e in _linkableEvents) {
          if (query.isEmpty || SearchHelper.matches(e.title, query)) {
            rows.add(_LinkPickerItem(id: e.id, title: e.title));
          }
        }

      default:
        final groupIndex = {
          for (final g in _linkableResourceGroups) g.id: g,
        };
        final byGroup = <int, List<ResourceModel>>{};
        for (final r in _linkableResources) {
          final groupTitle = groupIndex[r.resourceGroup]?.title ?? '';
          if (query.isEmpty ||
              SearchHelper.matches(r.title, query) ||
              SearchHelper.matches(groupTitle, query)) {
            byGroup.putIfAbsent(r.resourceGroup, () => []).add(r);
          }
        }
        final sortedGroupIds = byGroup.keys.toList()
          ..sort(
            (a, b) => (groupIndex[a]?.title ?? '').compareTo(
              groupIndex[b]?.title ?? '',
            ),
          );
        for (final groupId in sortedGroupIds) {
          rows.add(_LinkGroupHeader(title: groupIndex[groupId]?.title ?? ''));
          for (final r in byGroup[groupId]!) {
            rows.add(_LinkPickerItem(id: r.id, title: r.title));
          }
        }
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          switch (_linkPickerType) {
            'event' => query.isEmpty ? 'No available events' : 'No events match',
            'resource' => query.isEmpty ? 'No available resources' : 'No resources match',
            _ => query.isEmpty ? 'No available assignments' : 'No assignments match',
          },
          style: AppStyles.standardBodyTextLight(context).copyWith(
            color: onSurface50,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is _LinkGroupHeader) {
          final Widget groupBadge;
          if (_linkPickerType == 'resource' && userSettings != null) {
            groupBadge = ResourceTitleLabel(
              title: row.title,
              userSettings: userSettings!,
              compact: true,
            );
          } else {
            groupBadge = CourseTitleLabel(
              title: row.title,
              color: row.color ?? FallbackConstants.fallbackColor,
              compact: true,
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: groupBadge,
          );
        }
        final item = row as _LinkPickerItem;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            item.title,
            style: AppStyles.formText(context),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _linkNoteTo(_linkPickerType, item.id, item.title),
        );
      },
    );
  }
}

sealed class _LinkPickerRow {}

class _LinkGroupHeader extends _LinkPickerRow {
  final String title;
  final Color? color;
  _LinkGroupHeader({required this.title, this.color});
}

class _LinkPickerItem extends _LinkPickerRow {
  final int id;
  final String title;
  _LinkPickerItem({required this.id, required this.title});
}
