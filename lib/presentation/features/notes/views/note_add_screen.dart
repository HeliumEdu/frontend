// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
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
import 'package:heliumapp/utils/responsive_helpers.dart';

void showNoteAdd(
  BuildContext context, {
  required bool isEdit,
  required bool isNew,
  int? noteId,
  int? homeworkId,
  int? eventId,
  int? resourceId,
  int? resourceGroupId,
}) {
  final noteBloc = context.read<NoteBloc>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoute.notebookEditScreen,
      extra: NoteAddArgs(
        noteBloc: noteBloc,
        isEdit: !isNew,
        isNew: isNew,
        noteId: noteId,
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
        resourceGroupId: resourceGroupId,
      ),
    );
  } else {
    showScreenAsDialog(
      context,
      barrierDismissible: false,
      child: BlocProvider<NoteBloc>.value(
        value: noteBloc,
        child: NoteAddScreen(
          isEdit: !isNew,
          isNew: isNew,
          noteId: noteId,
          homeworkId: homeworkId,
          eventId: eventId,
          resourceId: resourceId,
          resourceGroupId: resourceGroupId,
        ),
      ),
      width: double.infinity,
      insetPadding: const EdgeInsets.all(32),
      alignment: Alignment.center,
    );
  }
}

class NoteAddScreen extends StatefulWidget {
  final bool isEdit;
  final bool isNew;
  final int? noteId;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final int? resourceGroupId;

  const NoteAddScreen({
    super.key,
    required this.isEdit,
    required this.isNew,
    this.noteId,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    this.resourceGroupId,
  });

  @override
  State<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends BasePageScreenState<NoteAddScreen> {
  final BasicFormController _formController = BasicFormController();
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  // State
  NoteModel? _note;
  String? _linkedEntityType;
  String? _linkedEntityTitle;
  Color? _linkedEntityColor;
  bool _showSearch = false;
  bool _hasRequestedInitialFocus = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();

    context.read<NoteBloc>().add(
      FetchNoteScreenDataEvent(
        origin: EventOrigin.subScreen,
        noteId: widget.noteId,
        homeworkId: widget.homeworkId,
        eventId: widget.eventId,
        resourceId: widget.resourceId,
        resourceGroupId: widget.resourceGroupId,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
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
      if (isLoading) return;

      if (!_formController.validateAndScrollToError()) {
        showSnackBar(
          context,
          'Fix the highlighted fields, then try again.',
          type: SnackType.error,
        );
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final title = _titleController.text.trim();
      final bodyIsEmpty = _quillController.document
          .toPlainText()
          .trim()
          .isEmpty;
      final hasLinkedEntity =
          widget.homeworkId != null ||
          widget.eventId != null ||
          widget.resourceId != null;

      // Standalone notes can be title-only, but linked notes require content
      final isEmptyNote =
          (title.isEmpty && bodyIsEmpty) || (hasLinkedEntity && bodyIsEmpty);
      if (widget.isNew && isEmptyNote) {
        setState(() {
          isSubmitting = false;
        });
        showSnackBar(
          context,
          'Not created, Note is empty',
          useRootMessenger: true,
        );
        cancelAction();
        return;
      }

      final content = _quillController.document.toDelta().toJson();

      if (widget.isNew) {
        context.read<NoteBloc>().add(
          CreateNoteEvent(
            origin: EventOrigin.subScreen,
            request: NoteRequestModel(
              title: title,
              content: {'ops': content},
              homeworkId: widget.homeworkId,
              eventId: widget.eventId,
              resourceId: widget.resourceId,
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
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NotesError) {
            setState(() {
              isSubmitting = false;
            });
            showSnackBar(context, state.message!, type: SnackType.error);
          } else if (state is NoteScreenDataFetched) {
            setState(() {
              isLoading = false;
              _linkedEntityType = state.linkedEntityType;
              _linkedEntityTitle = state.linkedEntityTitle;
              _linkedEntityColor = state.linkedEntityColor;
            });
            if (state.note != null) {
              _populateNoteData(state.note!);
            }

            // Request focus once on mobile for create mode
            if (!_hasRequestedInitialFocus && !kIsWeb && widget.isNew) {
              _hasRequestedInitialFocus = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _titleFocusNode.requestFocus();
              });
            }
          } else if (state is NoteCreated) {
            showSnackBar(context, 'Note created', useRootMessenger: true);
            cancelAction();
          } else if (state is NoteUpdated) {
            cancelAction();
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
                  const double gap = 8;
                  final hasBadge = _linkedEntityType != null;
                  final effectiveBadgeMax = hasBadge
                      ? (constraints.maxWidth - titleMinWidth - gap).clamp(
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
                          validator: hasBadge
                              ? null
                              : BasicFormController.validateRequiredField,
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

  Widget _buildLinkedEntityBadge() {
    final entityType = _linkedEntityType ?? '';
    final entityTitle = _linkedEntityTitle;
    final courseColor = _note?.courseColor ?? _linkedEntityColor;
    final categoryColor = _note?.categoryColor;

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
