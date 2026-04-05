// Copyright (c) 2025 Helium Edu
//
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

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
  bool _caseSensitive = false;
  bool _wholeWord = false;

  @override
  void initState() {
    super.initState();
    // Defer focus request until after initState so the FocusNode is attached
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
    _searchTimer = Timer(const Duration(milliseconds: 300), _findText);
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
        caseSensitive: _caseSensitive,
        wholeWord: _wholeWord,
      );
      _index = 0;

      if (_offsets.isEmpty) {
        _clearSelection();
      } else {
        for (var n = 0; n < _offsets.length; n++) {
          if (_offsets[n] >= currPos) {
            _index = n;
            break;
          }
        }
        _moveToPosition();
      }
    });

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

    final leaf = widget.controller.queryNode(offset);
    if (leaf is Embed) {
      len = 1;
    }

    widget.controller.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + len),
      ChangeSource.local,
    );

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
          _clearSelection();
          widget.onClose();
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
              icon: Icon(
                Icons.close,
                size: 20,
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _clearSelection();
                widget.onClose();
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 40,
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
                    child: TextField(
                      controller: _textController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      style: AppStyles.formText(context),
                      decoration: InputDecoration(
                        hintText: 'Search ...',
                        hintStyle: AppStyles.formHint(context),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixText: _matchText,
                        suffixStyle: AppStyles.formHint(
                          context,
                        ).copyWith(fontSize: 12),
                      ),
                      onChanged: _onTextChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _moveToNext(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_up,
                size: 20,
                color: _offsets.isNotEmpty
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              tooltip: 'Previous',
              visualDensity: VisualDensity.compact,
              onPressed: _offsets.isNotEmpty ? _moveToPrevious : null,
            ),
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: _offsets.isNotEmpty
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              tooltip: 'Next',
              visualDensity: VisualDensity.compact,
              onPressed: _offsets.isNotEmpty ? _moveToNext : null,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.text_fields,
                size: 18,
                color: _caseSensitive
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              tooltip: 'Match case',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _caseSensitive = !_caseSensitive;
                });
                if (_searchText.isNotEmpty) {
                  _findText();
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.border_outer,
                size: 18,
                color: _wholeWord
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              tooltip: 'Match whole word',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _wholeWord = !_wholeWord;
                });
                if (_searchText.isNotEmpty) {
                  _findText();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
