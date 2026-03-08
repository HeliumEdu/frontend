// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NotesViewer extends StatefulWidget {
  final Map<String, dynamic>? notes;
  // TODO: Once `comments`/`details` are retired, `legacyHtml` can be removed
  //  along with the flutter_html package dependency.
  final String? legacyHtml;

  const NotesViewer({super.key, required this.notes, this.legacyHtml});

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: QuillEditor.basic(
          controller: _controller,
          config: const QuillEditorConfig(
            showCursor: false,
            padding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (widget.legacyHtml != null && widget.legacyHtml!.isNotEmpty) {
      return SelectionArea(child: Html(data: widget.legacyHtml!));
    }

    return const SizedBox.shrink();
  }
}
