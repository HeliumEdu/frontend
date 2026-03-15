// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/presentation/ui/components/notes_editor.dart';

class NotesViewer extends StatefulWidget {
  final Map<String, dynamic>? notes;

  const NotesViewer({super.key, required this.notes});

  @override
  State<NotesViewer> createState() => _NotesViewerState();
}

class _NotesViewerState extends State<NotesViewer> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.notes != null) {
      _controller = QuillController(
        document: Document.fromJson(widget.notes!['ops'] as List),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } else {
      _controller = QuillController.basic();
      _controller.readOnly = true;
    }
  }

  @override
  void didUpdateWidget(NotesViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _controller.dispose();
      if (widget.notes != null) {
        _controller = QuillController(
          document: Document.fromJson(widget.notes!['ops'] as List),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } else {
        _controller = QuillController.basic();
        _controller.readOnly = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes == null) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
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
