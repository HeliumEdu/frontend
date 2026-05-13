// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

class NotesViewer extends StatefulWidget {
  final Map<String, dynamic>? notes;

  const NotesViewer({super.key, required this.notes});

  @override
  State<NotesViewer> createState() => _NotesViewerState();
}

class _NotesViewerState extends State<NotesViewer> {
  late QuillController _controller;
  bool _renderable = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(NotesViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _controller.dispose();
      _initController();
    }
  }

  void _initController() {
    final document = tryParseNotesDocument(widget.notes);
    if (document == null) {
      _controller = QuillController.basic()..readOnly = true;
      _renderable = false;
      return;
    }
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _renderable = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_renderable) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
      child: QuillEditor.basic(
        controller: _controller,
        config: QuillEditorConfig(
          showCursor: false,
          padding: EdgeInsets.zero,
          customStyles: NotesEditor.buildDefaultStyles(context),
        ),
      ),
    );
  }
}
