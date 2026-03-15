// Copyright (c) 2025 Helium Edu
//
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';

/// A custom search bar for QuillEditor that maintains focus properly.
///
/// Flutter Quill's built-in search dialog has a bug where focus jumps back
/// to the editor when typing in the search field. This component fixes that
/// by managing its own FocusNode and re-requesting focus after selection updates.
class QuillSearchBar extends StatefulWidget {
  final QuillController controller;
  final VoidCallback onClose;

  const QuillSearchBar({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<QuillSearchBar> createState() => _QuillSearchBarState();
}

class _QuillSearchBarState extends State<QuillSearchBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchText = '';
  List<int> _offsets = [];
  int _index = 0;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _searchText = text;
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 300),
      _findText,
    );
  }

  void _findText() {
    if (_searchText.isEmpty) {
      setState(() {
        _offsets = [];
        _index = 0;
        _clearSelection();
      });
      return;
    }

    setState(() {
      final currPos = _offsets.isNotEmpty ? _offsets[_index] : 0;
      _offsets = widget.controller.document.search(
        _searchText,
        caseSensitive: false,
        wholeWord: false,
      );
      _index = 0;

      if (_offsets.isEmpty) {
        _clearSelection();
      } else {
        // Select the next hit position from current
        for (var n = 0; n < _offsets.length; n++) {
          if (_offsets[n] >= currPos) {
            _index = n;
            break;
          }
        }
        _moveToPosition();
      }
    });

    // Re-request focus after selection update
    _searchFocusNode.requestFocus();
  }

  void _clearSelection() {
    widget.controller.updateSelection(
      TextSelection(
        baseOffset: widget.controller.selection.baseOffset,
        extentOffset: widget.controller.selection.baseOffset,
      ),
      ChangeSource.local,
    );
  }

  void _moveToPosition() {
    if (_offsets.isEmpty) return;

    final offset = _offsets[_index];
    var len = _searchText.length;

    // If search hit is within an embed, only select the embed
    final leaf = widget.controller.queryNode(offset);
    if (leaf is Embed) {
      len = 1;
    }

    widget.controller.updateSelection(
      TextSelection(
        baseOffset: offset,
        extentOffset: offset + len,
      ),
      ChangeSource.local,
    );

    // Re-request focus after selection update
    _searchFocusNode.requestFocus();
  }

  void _moveToPrevious() {
    if (_offsets.isEmpty) return;

    setState(() {
      if (_index > 0) {
        _index -= 1;
      } else {
        _index = _offsets.length - 1;
      }
    });
    _moveToPosition();
  }

  void _moveToNext() {
    if (_offsets.isEmpty) return;

    setState(() {
      if (_index < _offsets.length - 1) {
        _index += 1;
      } else {
        _index = 0;
      }
    });
    _moveToPosition();
  }

  void _close() {
    // Clear selection highlight before closing
    _clearSelection();
    widget.onClose();
  }

  String get _matchText {
    if (_searchText.isEmpty) return '';
    if (_offsets.isEmpty) return '0/0';
    return '${_index + 1}/${_offsets.length}';
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
              onPressed: _close,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _textController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Find in note...',
                    hintStyle: TextStyle(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: context.colorScheme.primary,
                      ),
                    ),
                    filled: true,
                    fillColor: context.colorScheme.surface,
                    suffixText: _matchText,
                    suffixStyle: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  onChanged: _onTextChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _moveToNext(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              tooltip: 'Previous',
              visualDensity: VisualDensity.compact,
              onPressed: _offsets.isNotEmpty ? _moveToPrevious : null,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              tooltip: 'Next',
              visualDensity: VisualDensity.compact,
              onPressed: _offsets.isNotEmpty ? _moveToNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
