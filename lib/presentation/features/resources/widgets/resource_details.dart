// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_request_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/resources/controllers/resource_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/select_field.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/presentation/ui/components/course_title_label.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/features/resources/constants/resource_constants.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/quill_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';

class ResourceDetails extends StatefulWidget {
  final int resourceGroupId;
  final int? resourceId;
  final bool isEdit;
  final VoidCallback? onSubmitRequested;
  final VoidCallback? onActionStarted;

  const ResourceDetails({
    super.key,
    required this.resourceGroupId,
    this.resourceId,
    required this.isEdit,
    this.onSubmitRequested,
    this.onActionStarted,
  });

  @override
  State<ResourceDetails> createState() => ResourceDetailsState();
}

class ResourceDetailsState extends State<ResourceDetails> {
  final ResourceFormController formController = ResourceFormController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  StreamSubscription<DocChange>? _notesSubscription;

  List<CourseModel> _courses = [];
  bool isLoading = true;
  bool _isSubmitting = false;
  bool _hasRequestedInitialFocus = false;

  @override
  void initState() {
    super.initState();

    if (!widget.isEdit) formController.markChanged();

    formController.urlFocusNode.addListener(_onUrlFocusChange);

    context.read<ResourceBloc>().add(
      FetchResourceScreenDataEvent(
        origin: EventOrigin.subScreen,
        resourceGroupId: widget.resourceGroupId,
        resourceId: widget.resourceId,
      ),
    );
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _titleFocusNode.dispose();
    _notesFocusNode.dispose();
    formController.urlFocusNode.removeListener(_onUrlFocusChange);
    formController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResourceBloc, ResourceState>(
      listener: (context, state) {
        if (state is ResourceScreenDataFetched) {
          _populateInitialStateData(state);
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: LoadingIndicator(expanded: false));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: formController.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabelAndTextFormField(
                    label: 'Title',
                    autofocus: kIsWeb,
                    focusNode: _titleFocusNode,
                    controller: formController.titleController,
                    validator: BasicFormController.validateRequiredField,
                    fieldKey: formController.getFieldKey('title'),
                    onChanged: (_) => formController.markChanged(),
                    onFieldSubmitted: (value) => (widget.onSubmitRequested ?? onSubmit).call(),
                  ),
                  const SizedBox(height: 14),
                  Text('Classes', style: AppStyles.formLabel(context)),
                  const SizedBox(height: 9),
                  SelectField<CourseModel>(
                    items: _courses,
                    selectedIds: formController.selectedCourses,
                    onChanged: (selected) {
                      formController.markChanged();
                      setState(() {
                        formController.selectedCourses = selected;
                      });
                    },
                    enabled: _courses.isNotEmpty,
                    buttonLabel: 'Select classes',
                    labelBuilder: (course, onDelete) => CourseTitleLabel(
                      title: course.title,
                      color: course.color,
                      onDelete: onDelete,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropDown(
                    label: 'Status',
                    initialValue: ResourceConstants.statusItems.firstWhere(
                      (mc) => mc.id == formController.selectedStatus,
                    ),
                    items: ResourceConstants.statusItems,
                    onChanged: (value) {
                      formController.markChanged();
                      setState(() {
                        formController.selectedStatus = value!.id;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropDown(
                    label: 'Condition',
                    initialValue: ResourceConstants.conditionItems.firstWhere(
                      (mc) => mc.id == formController.selectedCondition,
                    ),
                    items: ResourceConstants.conditionItems,
                    onChanged: (value) {
                      formController.markChanged();
                      setState(() {
                        formController.selectedCondition = value!.id;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Website',
                    controller: formController.urlController,
                    validator: BasicFormController.validateUrl,
                    fieldKey: formController.getFieldKey('url'),
                    focusNode: formController.urlFocusNode,
                    onChanged: (_) => formController.markChanged(),
                    trailingIconButton: HeliumIconButton(
                      onPressed: () {
                        UrlHelpers.launchWebUrl(
                          formController.urlController.text,
                        );
                      },
                      icon: Icons.launch_outlined,
                      tooltip: "Launch resource's website",
                      color: context.semanticColors.success,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabelAndTextFormField(
                    label: 'Price',
                    controller: formController.priceController,
                    onChanged: (_) => formController.markChanged(),
                  ),
                  const SizedBox(height: 14),
                  NotesEditor(
                    key: ObjectKey(formController.notesController),
                    controller: formController.notesController,
                    focusNode: _notesFocusNode,
                    onOpenInNotes: widget.isEdit ? () => onSubmit(redirectToNotebook: true) : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? get noteContent =>
      buildNotesDelta(formController.notesController);

  int? get linkedNoteId => formController.linkedNoteId;

  void resetSubmitting() {
    setState(() => _isSubmitting = false);
  }

  Future<void> onSubmit({bool redirectToNotebook = false}) async {
    if (isLoading || _isSubmitting) return;
    if (formController.validateAndScrollToError()) {
      // Notify parent that action is starting (validation passed)
      setState(() => _isSubmitting = true);
      widget.onActionStarted?.call();

      final request = ResourceRequestModel(
        title: formController.titleController.text.trim(),
        status: formController.selectedStatus,
        condition: formController.selectedCondition,
        website: formController.urlController.text.trim().isEmpty
            ? ''
            : formController.urlController.text.trim(),
        price: formController.priceController.text.trim().isEmpty
            ? ''
            : formController.priceController.text.trim(),
        details: widget.isEdit ? formController.initialNotes : '',
        courses: formController.selectedCourses,
        resourceGroup: widget.resourceGroupId,
      );

      if (!mounted) return;
      if (widget.isEdit && widget.resourceId != null) {
        // Dispatch note operations to NoteBloc directly; resource.id is known
        final content = noteContent;
        final existingNoteId = formController.linkedNoteId;
        if (existingNoteId != null) {
          // Update with current content; empty content triggers deletion on backend
          context.read<NoteBloc>().add(UpdateNoteEvent(
            origin: EventOrigin.subScreen,
            noteId: existingNoteId,
            request: NoteRequestModel(content: content ?? {}),
          ));
        } else if (content != null) {
          context.read<NoteBloc>().add(CreateNoteEvent(
            origin: EventOrigin.subScreen,
            request: NoteRequestModel(
              content: content,
              resourceId: widget.resourceId!,
            ),
          ));
        }

        context.read<ResourceBloc>().add(
          UpdateResourceEvent(
            origin: EventOrigin.subScreen,
            resourceGroupId: widget.resourceGroupId,
            resourceId: widget.resourceId!,
            request: request,
            redirectToNotebook: redirectToNotebook,
          ),
        );
      } else {
        // For CREATE, note content is dispatched by the parent after getting resource.id
        context.read<ResourceBloc>().add(
          CreateResourceEvent(
            origin: EventOrigin.subScreen,
            resourceGroupId: widget.resourceGroupId,
            request: request,
            redirectToNotebook: redirectToNotebook,
          ),
        );
      }
    } else {
      SnackBarHelper.show(
        context,
        'Fix the highlighted fields, then try again.',
        type: SnackType.error,
      );
    }
  }

  void _populateInitialStateData(ResourceScreenDataFetched state) {
    _courses = state.courses;
    Sort.byTitle(_courses);

    if (widget.isEdit) {
      formController.titleController.text = state.resource!.title;
      formController.urlController.text = state.resource!.website?.toString() ?? '';
      formController.priceController.text = state.resource!.price ?? '';
      formController.initialNotes = state.resource!.details ?? '';
      formController.selectedStatus = state.resource!.status;
      formController.selectedCondition = state.resource!.condition;
      formController.selectedCourses = List<int>.from(
        state.resource!.courses,
      );

      formController.notesController.dispose();
      if (state.linkedNote != null) {
        formController.linkedNoteId = state.linkedNote!.id;
        formController.notesController = state.linkedNote!.content != null
            ? QuillController(
                document: Document.fromJson(state.linkedNote!.content!['ops'] as List),
                selection: const TextSelection.collapsed(offset: 0),
              )
            : QuillController.basic();
      } else {
        formController.notesController = QuillController.basic();
      }
    }

    setState(() {
      isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupNotesListener();
    });

    // Request focus once on mobile for create mode
    if (!_hasRequestedInitialFocus && !kIsWeb && !widget.isEdit) {
      _hasRequestedInitialFocus = true;
      // Defer focus request so the text field is attached to the tree before
      // requestFocus is called; BLoC listeners fire during the build pipeline
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocusNode.requestFocus();
      });
    }
  }

  void _setupNotesListener() {
    _notesSubscription?.cancel();
    _notesSubscription = formController.notesController.document.changes.listen((change) {
      if (isNoteEdited(change)) formController.markChanged();
    });
  }

  void _onUrlFocusChange() {
    if (!formController.urlFocusNode.hasFocus) {
      formController.urlController.text = BasicFormController.cleanUrl(
        formController.urlController.text.trim(),
      );
    }
  }

}
