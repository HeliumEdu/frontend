// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/generic_label.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/deep_link_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum SaveStatus { unsaved, saving, saved, error }

Future<void> showNoteAdd(
  BuildContext context, {
  required bool isNew,
  int? noteId,
  int? linkHomeworkId,
  int? linkEventId,
  int? linkResourceId,
}) {
  final noteBloc = context.read<NoteBloc>();
  final basePath = router.routerDelegate.currentConfiguration.uri.path;
  final idParam = noteId?.toString() ?? (isNew ? 'new' : null);

  if (idParam != null) {
    context.setQueryParam(DeepLinkParam.id, idParam);
  }

  final isMobile = Responsive.isMobile(context);

  return showScreenAsDialog(
    context,
    barrierDismissible: false,
    child: BlocProvider<NoteBloc>.value(
      value: noteBloc,
      child: NoteAddScreen(
        isNew: isNew,
        noteId: noteId,
        linkHomeworkId: linkHomeworkId,
        linkEventId: linkEventId,
        linkResourceId: linkResourceId,
      ),
    ),
    width: double.infinity,
    insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(32),
    alignment: Alignment.center,
  ).then((_) => clearRouteQueryParams(basePath));
}

class NoteAddScreen extends StatefulWidget {
  final bool isNew;
  final int? noteId;
  final int? linkHomeworkId;
  final int? linkEventId;
  final int? linkResourceId;

  const NoteAddScreen({
    super.key,
    required this.isNew,
    this.noteId,
    this.linkHomeworkId,
    this.linkEventId,
    this.linkResourceId,
  });

  @override
  State<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends BasePageScreenState<NoteAddScreen> {
  static const _autoSaveDebounce = Duration(seconds: 5);
  static const _maxAutoSaveErrors = 3;

  final BasicFormController _formController = BasicFormController();
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  NoteModel? _note;
  String? _linkedEntityType;
  String? _linkedEntityTitle;
  Color? _linkedEntityColor;
  bool _showSearch = false;
  bool _hasRequestedInitialFocus = false;

  // Auto-save state
  SaveStatus _saveStatus = SaveStatus.saved;
  Timer? _debounceTimer;
  bool _isAutoSaving = false;
  int _autoSaveErrorCount = 0;
  bool _autoSaveDisabled = false;
  StreamSubscription<DocChange>? _documentSubscription;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    // Set initial save status based on whether this is a new or existing note
    _saveStatus = widget.noteId == null ? SaveStatus.unsaved : SaveStatus.saved;

    // Set up auto-save listeners
    _titleController.addListener(_onContentChanged);
    _editorFocusNode.addListener(_onEditorFocusChanged);

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

  void _setupDocumentListener() {
    _documentSubscription?.cancel();
    _documentSubscription = _quillController.document.changes.listen((_) {
      _onContentChanged();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _documentSubscription?.cancel();
    _titleController.removeListener(_onContentChanged);
    _editorFocusNode.removeListener(_onEditorFocusChanged);
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  String _getSavedContentAsJson() {
    if (_note?.content == null || _note!.content!['ops'] == null) {
      return '';
    }
    return jsonEncode(_note!.content!['ops']);
  }

  void _onContentChanged() {
    if (isLoading || _autoSaveDisabled || _saveStatus == SaveStatus.saving) {
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
      _saveStatus = SaveStatus.unsaved;
    });

    // For new notes, only auto-save once title OR body is non-empty
    final isNewNote = _note == null;
    if (isNewNote) {
      final hasTitle = currentTitle.trim().isNotEmpty;
      final hasBody = _quillController.document.toPlainText().trim().isNotEmpty;
      if (!hasTitle && !hasBody) return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autoSaveDebounce, _triggerAutoSave);
  }

  void _onEditorFocusChanged() {
    // Trigger save on blur if there are unsaved changes
    if (!_editorFocusNode.hasFocus &&
        _saveStatus == SaveStatus.unsaved &&
        !_autoSaveDisabled) {
      _triggerAutoSave();
    }
  }

  void _triggerAutoSave() {
    if (_saveStatus == SaveStatus.saving || _autoSaveDisabled) return;

    final title = _titleController.text.trim();
    final bodyIsEmpty = _quillController.document.toPlainText().trim().isEmpty;

    // Require at least title or body
    if (title.isEmpty && bodyIsEmpty) return;

    _performSave(isAutoSave: true);
  }

  void _onSaveIconTapped() {
    if (_saveStatus == SaveStatus.saving) return;
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
      _saveStatus = SaveStatus.saving;
      _isAutoSaving = isAutoSave;
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
          request: NoteRequestModel(title: title, content: {'ops': content}),
        ),
      );
    }
  }

  void _handleAutoSaveError(String message) {
    _autoSaveErrorCount++;

    Sentry.metrics.count('note.autosave.error', 1);

    if (_autoSaveErrorCount >= _maxAutoSaveErrors) {
      setState(() {
        _saveStatus = SaveStatus.error;
        _autoSaveDisabled = true;
      });
      showSnackBar(
        context,
        'Auto-save disabled. Connect to the Internet and manually save to re-enable.',
        type: SnackType.error,
        seconds: 5,
      );
    } else {
      setState(() {
        _saveStatus = SaveStatus.error;
      });
      showSnackBar(context, message, type: SnackType.error);
    }
  }

  @override
  String get screenTitle => widget.isNew ? 'Add Note' : 'Edit Note';

  @override
  IconData get icon => Icons.library_books;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function? get saveAction {
    return () {
      if (isLoading || isSubmitting) return;

      if (!_formController.validateAndScrollToError()) {
        showSnackBar(
          context,
          'Fix the highlighted fields, then try again.',
          type: SnackType.error,
        );
        return;
      }

      final title = _titleController.text.trim();
      final bodyIsEmpty = _quillController.document
          .toPlainText()
          .trim()
          .isEmpty;

      if (_note?.id == null &&
          (widget.linkEventId != null ||
          widget.linkHomeworkId != null ||
          widget.linkResourceId != null) &&
          bodyIsEmpty) {
        showSnackBar(
          context,
          'Note was empty, so nothing to save',
          useRootMessenger: true,
        );
        cancelAction();
        return;
      }

      setState(() {
        isSubmitting = true;
        _isAutoSaving = false;
      });

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
            request: NoteRequestModel(title: title, content: {'ops': content}),
          ),
        );
      }
    };
  }

  void _populateNoteData(NoteModel note) {
    _note = note;
    _titleController.text = note.title;

    if (note.content != null && note.content!['ops'] != null) {
      final ops = note.content!['ops'] as List;
      _quillController.document = Document.fromJson(ops);
    }

    _setupDocumentListener();
    _saveStatus = SaveStatus.saved;

    // Delay clearing isLoading to ignore async document change events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => isLoading = false);
    });
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError) {
            if (_isAutoSaving) {
              _handleAutoSaveError(state.message ?? 'Auto-save failed');
              _isAutoSaving = false;
            } else {
              setState(() {
                isSubmitting = false;
              });
              showSnackBar(context, state.message!, type: SnackType.error);
            }
          } else if (state is NoteScreenDataFetched) {
            setState(() {
              _linkedEntityType = state.linkedEntityType;
              _linkedEntityTitle = state.linkedEntityTitle;
              _linkedEntityColor = state.linkedEntityColor;
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _titleFocusNode.requestFocus();
              });
            }
          } else if (state is NoteCreated) {
            if (_isAutoSaving) {
              // Auto-save created the note - update state but don't close
              setState(() {
                _note = state.note;
                _saveStatus = SaveStatus.saved;
                _autoSaveErrorCount = 0;
                _autoSaveDisabled = false;
              });
              _isAutoSaving = false;
              // Update URL from id=new to the actual ID
              if (!Responsive.isMobile(context)) {
                context.setQueryParam(
                  DeepLinkParam.id,
                  state.note.id.toString(),
                );
              }
              showSnackBar(context, 'Note created');
            } else {
              // Manual save - show message and close
              showSnackBar(context, 'Note created', useRootMessenger: true);
              cancelAction();
            }
          } else if (state is NoteUpdated) {
            if (_isAutoSaving) {
              // Auto-save updated the note - update state but don't close
              setState(() {
                _note = state.note;
                _saveStatus = SaveStatus.saved;
                _autoSaveErrorCount = 0;
                _autoSaveDisabled = false;
              });
              _isAutoSaving = false;
            } else {
              // Manual save - close
              cancelAction();
            }
          } else if (state is NoteDeleted) {
            showSnackBar(context, 'Note deleted', useRootMessenger: true);
            cancelAction();
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

    final isMobile = Responsive.isMobile(context);

    return Expanded(
      child: Form(
        key: _formController.formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double titleMinWidth = 225;
                  const double badgeMaxWidth = 250;
                  const double gap = 4;
                  final hasBadge = _linkedEntityType != null;
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
                          constraints: BoxConstraints(
                            maxWidth: effectiveBadgeMax,
                          ),
                          child: _buildLinkedEntityBadge(),
                        ),
                      ],
                      const SizedBox(width: gap),
                      _buildSaveStatusIcon(),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: QuillSimpleToolbar(
                            controller: _quillController,
                            config: QuillSimpleToolbarConfig(
                              toolbarRunSpacing: 0,
                              showDividers: !isMobile,
                              showFontSize: !isMobile,
                              showHeaderStyle: !isMobile,
                              showInlineCode: !isMobile,
                              showClearFormat: !isMobile,
                              showStrikeThrough: !isMobile,
                              showAlignmentButtons: !isMobile,
                              showLeftAlignment: !isMobile,
                              showCenterAlignment: !isMobile,
                              showRightAlignment: !isMobile,
                              showCodeBlock: !isMobile,
                              showIndent: !isMobile,
                              showSubscript: !isMobile,
                              showSuperscript: !isMobile,
                              showBackgroundColorButton: !isMobile,
                              showSearchButton: true,
                              buttonOptions: QuillSimpleToolbarButtonOptions(
                                search: QuillToolbarSearchButtonOptions(
                                  customOnPressedCallback: (_) async {
                                    setState(() {
                                      _showSearch = !_showSearch;
                                    });
                                  },
                                ),
                                base: QuillToolbarBaseButtonOptions(
                                  iconTheme: QuillIconTheme(
                                    iconButtonSelectedData: IconButtonData(
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          context.colorScheme.primary,
                                        ),
                                        foregroundColor: WidgetStatePropertyAll(
                                          context.colorScheme.onPrimary,
                                        ),
                                        overlayColor: WidgetStatePropertyAll(
                                          context.colorScheme.onPrimary
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ),
                                    iconButtonUnselectedData: IconButtonData(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                color: QuillToolbarColorButtonOptions(
                                  customOnPressedCallback:
                                      (ctrl, isBackground) =>
                                          NotesEditor.showColorPicker(
                                            context,
                                            ctrl,
                                            isBackground,
                                          ),
                                ),
                                backgroundColor: QuillToolbarColorButtonOptions(
                                  customOnPressedCallback:
                                      (ctrl, isBackground) =>
                                          NotesEditor.showColorPicker(
                                            context,
                                            ctrl,
                                            isBackground,
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            config: QuillEditorConfig(
                              padding: const EdgeInsets.all(12),
                              autoFocus: false,
                              expands: true,
                              customStyles: NotesEditor.buildDefaultStyles(
                                context,
                              ),
                              scrollBottomInset: MediaQuery.of(context).viewInsets.bottom,
                              // ignore: experimental_member_use
                              onKeyPressed: (event, node) {
                                final isFindShortcut =
                                    event.logicalKey ==
                                        LogicalKeyboardKey.keyF &&
                                    (HardwareKeyboard.instance.isMetaPressed ||
                                        HardwareKeyboard
                                            .instance
                                            .isControlPressed);
                                if (isFindShortcut) {
                                  setState(() => _showSearch = !_showSearch);
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveStatusIcon() {
    final IconData icon;
    final Color color;
    final String tooltip;
    final bool animate;

    switch (_saveStatus) {
      case SaveStatus.unsaved:
        icon = Icons.cloud_outlined;
        color = context.colorScheme.onSurface.withValues(alpha: 0.5);
        tooltip = 'Unsaved changes';
        animate = false;
      case SaveStatus.saving:
        icon = Icons.sync;
        color = context.colorScheme.primary;
        tooltip = 'Saving ...';
        animate = true;
      case SaveStatus.saved:
        icon = Icons.cloud_done_outlined;
        color = context.colorScheme.primary;
        tooltip = 'All changes saved';
        animate = false;
      case SaveStatus.error:
        icon = Icons.cloud_off_outlined;
        color = context.colorScheme.error;
        tooltip = _autoSaveDisabled
            ? 'Auto-save disabled - tap to retry'
            : 'Save failed - tap to retry';
        animate = false;
    }

    final isEmpty = _isNoteEmpty;
    final isDisabled = isEmpty || _saveStatus == SaveStatus.saving;

    // Dim the icon when disabled due to empty note
    final effectiveColor = isEmpty ? color.withValues(alpha: 0.3) : color;

    Widget iconWidget = Icon(icon, size: 18, color: effectiveColor);

    if (animate) {
      iconWidget = _AnimatedSyncIcon(color: effectiveColor);
    }

    final button = InkWell(
      onTap: isDisabled ? null : _onSaveIconTapped,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.all(8), child: iconWidget),
    );

    // No tooltip when empty
    if (isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildLinkedEntityBadge() {
    final entityType = _linkedEntityType ?? '';
    final entityTitle = _linkedEntityTitle;
    final title = entityTitle ?? 'Linked $entityType';

    if (entityType == 'resource') {
      if (userSettings == null) return const SizedBox.shrink();
      return ResourceTitleLabel(title: title, userSettings: userSettings!);
    }

    if (entityType == 'event') {
      return GenericLabel(
        label: title,
        color: userSettings?.eventsColor ?? context.colorScheme.tertiary,
        icon: AppConstants.eventIcon,
      );
    }

    // Homework badge - respect colorByCategory setting
    final courseColor = _note?.courseColor ?? _linkedEntityColor;
    final categoryColor = _note?.categoryColor;
    final badgeColor =
        (userSettings?.colorByCategory ?? false) && categoryColor != null
        ? categoryColor
        : courseColor;
    return GenericLabel(
      label: title,
      color: badgeColor ?? context.colorScheme.primary,
      icon: AppConstants.assignmentIcon,
    );
  }
}

class _AnimatedSyncIcon extends StatefulWidget {
  final Color color;

  const _AnimatedSyncIcon({required this.color});

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, size: 18, color: widget.color),
    );
  }
}
