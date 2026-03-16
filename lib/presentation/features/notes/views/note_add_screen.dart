// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/note_link_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/repositories/note_repository_impl.dart';
import 'package:heliumapp/data/repositories/resource_repository_impl.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/data/sources/note_remote_data_source.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/notes/bloc/note_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/components/quill_search_bar.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Shows note add/edit as a dialog on desktop, or navigates on mobile
void showNoteAdd(
  BuildContext context, {
  int? noteId,
  int? homeworkId,
  int? eventId,
  int? resourceId,
  int? resourceGroupId,
}) {
  // Try to read existing NoteBloc, or create a new one
  final existingBloc = context.read<NoteBloc?>();

  if (Responsive.isMobile(context)) {
    context.push(
      AppRoute.notebookEditScreen,
      extra: NoteAddArgs(
        noteBloc: existingBloc,
        noteId: noteId,
        homeworkId: homeworkId,
        eventId: eventId,
        resourceId: resourceId,
        resourceGroupId: resourceGroupId,
      ),
    );
  } else {
    final noteScreen = NoteAddScreen(
      noteId: noteId,
      homeworkId: homeworkId,
      eventId: eventId,
      resourceId: resourceId,
      resourceGroupId: resourceGroupId,
    );

    showScreenAsDialog(
      context,
      barrierDismissible: false,
      child: existingBloc != null
          ? BlocProvider<NoteBloc>.value(
              value: existingBloc,
              child: noteScreen,
            )
          : BlocProvider<NoteBloc>(
              create: (_) => NoteBloc(
                noteRepository: NoteRepositoryImpl(
                  remoteDataSource: NoteRemoteDataSourceImpl(
                    dioClient: DioClient(),
                  ),
                ),
              ),
              child: noteScreen,
            ),
      width: double.infinity,
      insetPadding: const EdgeInsets.all(32),
      alignment: Alignment.center,
    );
  }
}

class NoteAddScreen extends StatefulWidget {
  final int? noteId;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final int? resourceGroupId;

  const NoteAddScreen({
    super.key,
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
  NoteLinkModel? _provisionalLink;
  bool _showSearch = false;

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
      if (widget.homeworkId != null || widget.eventId != null ||
          (widget.resourceId != null && widget.resourceGroupId != null)) {
        _fetchLinkedEntity();
      }
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

  Future<void> _fetchLinkedEntity() async {
    try {
      final dioClient = DioClient();
      if (widget.homeworkId != null) {
        final homeworkRepo = HomeworkRepositoryImpl(
          remoteDataSource: HomeworkRemoteDataSourceImpl(dioClient: dioClient),
        );
        final courseRepo = CourseRepositoryImpl(
          remoteDataSource: CourseRemoteDataSourceImpl(dioClient: dioClient),
        );
        final results = await Future.wait([
          homeworkRepo.getHomework(id: widget.homeworkId!),
          courseRepo.getCourses(),
        ]);
        final homework = results[0] as HomeworkModel;
        final courses = results[1] as List<CourseModel>;
        final course = courses.firstWhereOrNull((c) => c.id == homework.course.id);
        if (!mounted) return;
        setState(() {
          _titleController.text = homework.title;
          _provisionalLink = NoteLinkModel(
            id: 0,
            homeworkId: homework.id,
            linkedEntityType: 'homework',
            linkedEntityTitle: homework.title,
            linkedEntityColor: course?.color,
          );
        });
      } else if (widget.eventId != null) {
        final event = await EventRepositoryImpl(
          remoteDataSource: EventRemoteDataSourceImpl(dioClient: dioClient),
        ).getEvent(id: widget.eventId!);
        if (!mounted) return;
        setState(() {
          _titleController.text = event.title;
          _provisionalLink = NoteLinkModel(
            id: 0,
            eventId: event.id,
            linkedEntityType: 'event',
            linkedEntityTitle: event.title,
          );
        });
      } else if (widget.resourceId != null && widget.resourceGroupId != null) {
        final resource = await ResourceRepositoryImpl(
          remoteDataSource: ResourceRemoteDataSourceImpl(dioClient: dioClient),
        ).getResource(
          groupId: widget.resourceGroupId!,
          resourceId: widget.resourceId!,
        );
        if (!mounted) return;
        setState(() {
          _titleController.text = resource.title;
          _provisionalLink = NoteLinkModel(
            id: 0,
            resourceId: resource.id,
            linkedEntityType: 'resource',
            linkedEntityTitle: resource.title,
          );
        });
      }
    } catch (_) {
      // If lookup fails, proceed without link info
    }
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
        resourceId: widget.resourceId,
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
            showSnackBar(context, 'Note created', useRootMessenger: true);
            cancelAction();
          } else if (state is NoteUpdated) {
            cancelAction();
          } else if (state is NoteDeleted) {
            // Note was deleted because content was cleared on a linked note
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: LabelAndTextFormField(
                      hintText: 'Title',
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      autofocus: kIsWeb || widget.noteId == null,
                      validator: BasicFormController.validateRequiredField,
                      fieldKey: _formController.getFieldKey('title'),
                      onFieldSubmitted: (_) => _editorFocusNode.requestFocus(),
                    ),
                  ),
                  if (_note?.link != null || _provisionalLink != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: _buildLinkedEntityBadge(
                        _note?.link ?? _provisionalLink!,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Quill toolbar and editor
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: QuillSimpleToolbar(
                          controller: _quillController,
                          config: QuillSimpleToolbarConfig(
                            showDividers: !isMobile,
                            showFontSize: !isMobile,
                            showHeaderStyle: !isMobile,
                            showStrikeThrough: !isMobile,
                            showInlineCode: !isMobile,
                            showFontFamily: !isMobile,
                            showClearFormat: !isMobile,
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
                                        context.colorScheme.onPrimary.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                  iconButtonUnselectedData: IconButtonData(
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              color: QuillToolbarColorButtonOptions(
                                customOnPressedCallback: (ctrl, isBackground) =>
                                    NotesEditor.showColorPicker(context, ctrl, isBackground),
                              ),
                              backgroundColor: QuillToolbarColorButtonOptions(
                                customOnPressedCallback: (ctrl, isBackground) =>
                                    NotesEditor.showColorPicker(context, ctrl, isBackground),
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
                            customStyles: NotesEditor.buildDefaultStyles(context),
                            // ignore: experimental_member_use
                            onKeyPressed: (event, node) {
                              final isFindShortcut = event.logicalKey == LogicalKeyboardKey.keyF &&
                                  (HardwareKeyboard.instance.isMetaPressed ||
                                   HardwareKeyboard.instance.isControlPressed);
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

  Widget _buildLinkedEntityBadge(NoteLinkModel link) {
    final title = link.linkedEntityTitle ?? 'Linked ${link.linkedEntityType}';

    if (link.linkedEntityType == 'resource') {
      if (userSettings == null) return const SizedBox.shrink();
      return ResourceTitleLabel(title: title, userSettings: userSettings!);
    }

    if (link.linkedEntityType == 'event') {
      return CourseTitleLabel(
        title: title,
        color: userSettings?.eventsColor ?? context.colorScheme.tertiary,
        icon: AppConstants.eventIcon,
        showIconTab: true,
      );
    }

    // homework (and any unknown linked type)
    return CourseTitleLabel(
      title: title,
      color: link.linkedEntityColor ?? context.colorScheme.primary,
      icon: AppConstants.assignmentIcon,
      showIconTab: true,
    );
  }
}
