// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class NoteAddScreen extends StatefulWidget {
  final int? noteId;
  final int? homeworkId;
  final int? eventId;
  final int? materialId;

  const NoteAddScreen({
    super.key,
    this.noteId,
    this.homeworkId,
    this.eventId,
    this.materialId,
  });

  @override
  State<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends BasePageScreenState<NoteAddScreen> {
  @override
  String get screenTitle => _isNewNote ? 'New Note' : 'Edit Note';

  @override
  IconData get icon => Icons.library_books;

  @override
  ScreenType get screenType => ScreenType.entityPage;

  @override
  Function? get saveAction => _saveNote;

  // Controllers
  final BasicFormController _formController = BasicFormController();
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  // State
  NoteModel? _note;
  bool _isNewNote = true;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();

    if (widget.noteId != null) {
      _isNewNote = false;
      _fetchNote();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _fetchNote() {
    context.read<NoteBloc>().add(
      FetchNoteEvent(
        origin: EventOrigin.screen,
        noteId: widget.noteId!,
        forceRefresh: true,
      ),
    );
  }

  void _saveNote() {
    if (!_formController.validateAndScrollToError()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final title = _titleController.text.trim();

    final content = _quillController.document.toDelta().toJson();

    if (_isNewNote) {
      final request = NoteRequestModel(
        title: title,
        content: {'ops': content},
        homeworkId: widget.homeworkId,
        eventId: widget.eventId,
        materialId: widget.materialId,
      );
      context.read<NoteBloc>().add(
        CreateNoteEvent(
          origin: EventOrigin.screen,
          request: request,
        ),
      );
    } else {
      final request = NoteRequestModel(
        title: title,
        content: {'ops': content},
      );
      context.read<NoteBloc>().add(
        UpdateNoteEvent(
          origin: EventOrigin.screen,
          noteId: _note!.id,
          request: request,
        ),
      );
    }
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
          } else if (state is NoteFetched) {
            setState(() {
              isLoading = false;
            });
            _populateNoteData(state.note);
          } else if (state is NoteCreated) {
            showSnackBar(context, 'Note created');
            context.pop();
          } else if (state is NoteUpdated) {
            context.pop();
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
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      hintText: 'Title',
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      validator: BasicFormController.validateRequiredField,
                      fieldKey: _formController.getFieldKey('title'),
                      onFieldSubmitted: (_) => _editorFocusNode.requestFocus(),
                    ),
                  ),
                  if (_note?.link != null) ...[
                    const SizedBox(width: 8),
                    _buildLinkedEntityInfo(),
                  ],
                ],
              ),
            ),

          const Divider(height: 1),

          // Quill toolbar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                showDividers: !isMobile,
                showFontFamily: false,
                showFontSize: !isMobile,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: !isMobile,
                showInlineCode: !isMobile,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: !isMobile,
                showAlignmentButtons: !isMobile,
                showLeftAlignment: !isMobile,
                showCenterAlignment: !isMobile,
                showRightAlignment: !isMobile,
                showJustifyAlignment: false,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: true,
                showCodeBlock: !isMobile,
                showQuote: true,
                showIndent: !isMobile,
                showLink: true,
                showUndo: !isMobile,
                showRedo: !isMobile,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                multiRowsDisplay: isMobile,
                buttonOptions: QuillSimpleToolbarButtonOptions(
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
                            context.colorScheme.onPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      iconButtonUnselectedData: IconButtonData(
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Quill editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                config: const QuillEditorConfig(
                  padding: EdgeInsets.all(8),
                  autoFocus: false,
                  expands: true,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildLinkedEntityInfo() {
    final link = _note!.link!;
    final icon = _getEntityIcon(link.linkedEntityType);

    // Determine color based on entity type
    Color? color;
    if (link.linkedEntityType == 'homework') {
      color = link.linkedEntityColor;
    } else if (link.linkedEntityType == 'event') {
      color = userSettings?.eventsColor;
    } else if (link.linkedEntityType == 'material') {
      color = userSettings?.resourceColor;
    }

    // Fallback color for standalone notes
    final effectiveColor = color ?? context.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BadgeColors.background(context, effectiveColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BadgeColors.border(context, effectiveColor),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: BadgeColors.foreground(context, effectiveColor),
          ),
          const SizedBox(width: 6),
          Text(
            link.linkedEntityTitle ?? 'Linked ${link.linkedEntityType}',
            style: AppStyles.standardBodyTextLight(context).copyWith(
              fontSize: 12,
              color: BadgeColors.foreground(context, effectiveColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'homework':
        return AppConstants.assignmentIcon;
      case 'event':
        return AppConstants.eventIcon;
      case 'material':
        return Icons.book;
      default:
        return Icons.link;
    }
  }
}
