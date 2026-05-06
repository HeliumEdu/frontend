// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/app_style.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final DropDownItem<T> initialValue;
  final List<DropDownItem<T>> items;
  final void Function(DropDownItem<T>?)? onChanged;

  const SearchableDropdown({
    super.key,
    this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  // ASCII-only: stripping non-[a-z0-9] also removes diacritics. Fine for the
  // current timezone labels; revisit if reused for non-ASCII content.
  static final _nonAlphanumeric = RegExp(r'[^a-z0-9]');

  static const double _optionItemExtent = 56.0;

  TextEditingController? _fieldController;
  FocusNode? _focusNode;
  final ScrollController _optionsScrollController = ScrollController();

  List<DropDownItem<T>> _filteredOptions = [];
  DropDownItem<T>? _selectedItem;
  bool _scrollToSelectedPending = false;

  @override
  void initState() {
    super.initState();

    _selectedItem = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue.value != widget.initialValue.value) {
      _selectedItem = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    _optionsScrollController.dispose();
    super.dispose();
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(_nonAlphanumeric, '');

  void _revertToSelected() {
    if (_fieldController != null && _selectedItem != null) {
      _fieldController!.text = _selectedItem!.label;
    }
  }

  void _commitSingleMatchOrRevert() {
    if (_filteredOptions.length == 1) {
      final item = _filteredOptions.first;
      _selectedItem = item;
      _fieldController?.text = item.label;
      widget.onChanged?.call(item);
    } else {
      _revertToSelected();
    }
  }

  void _onFocusChange() {
    if (_focusNode == null) return;
    if (_focusNode!.hasFocus) {
      _onFocusGained();
    } else {
      _onFocusLost();
    }
  }

  void _onFocusGained() {
    final text = _fieldController?.text;
    if (text == null || text.isEmpty) return;
    _fieldController!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
    _scrollToSelectedPending = true;
  }

  void _onFocusLost() {
    final text = _fieldController!.text;
    final exactMatches = widget.items.where((item) => item.label == text);
    if (exactMatches.isNotEmpty) {
      final match = exactMatches.first;
      if (match != _selectedItem) {
        _selectedItem = match;
        widget.onChanged?.call(match);
      }
      return;
    }

    // Setting controller text synchronously inside a focus-change event
    // triggers RawAutocomplete to rebuild mid-traversal, which pulls focus back
    // to this field. Defer until the focus event has fully settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_focusNode?.hasFocus ?? false) return;
      _commitSingleMatchOrRevert();
    });
  }

  void _setupFocusListener(FocusNode focusNode) {
    if (_focusNode != focusNode) {
      _focusNode?.removeListener(_onFocusChange);
      _focusNode = focusNode;
      _focusNode!.addListener(_onFocusChange);
    }
  }

  void _maybeScrollToSelected() {
    if (!_scrollToSelectedPending) return;
    _scrollToSelectedPending = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedValue = _selectedItem?.value;
      if (selectedValue == null) return;
      final index = _filteredOptions
          .indexWhere((item) => item.value == selectedValue);
      if (index < 0) return;
      if (!_optionsScrollController.hasClients) return;

      final maxOffset = _optionsScrollController.position.maxScrollExtent;
      final target = (index * _optionItemExtent).clamp(0.0, maxOffset);
      _optionsScrollController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onChanged == null;
    final iconColor = isDisabled
        ? context.colorScheme.primary.withValues(alpha: 0.4)
        : context.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) Text(widget.label!, style: AppStyles.formLabel(context)),
        if (widget.label != null) const SizedBox(height: 9),
        Autocomplete<DropDownItem<T>>(
          key: ValueKey(widget.initialValue.value),
          initialValue: TextEditingValue(
            text: widget.initialValue.label,
          ),
          optionsBuilder: (textEditingValue) {
            // After fresh focus, text equals the current selection (it was just
            // select-all'd, not modified). Return the full list so the user can
            // browse, not just the single matching item.
            final selectedLabel = _selectedItem?.label;
            if (selectedLabel != null &&
                textEditingValue.text == selectedLabel) {
              _filteredOptions = widget.items;
              return _filteredOptions;
            }
            final query = _normalize(textEditingValue.text);
            if (query.isEmpty) {
              _filteredOptions = widget.items;
            } else {
              _filteredOptions = widget.items
                  .where((item) => _normalize(item.label).contains(query))
                  .toList();
            }
            return _filteredOptions;
          },
          displayStringForOption: (item) => item.label,
          onSelected: (item) {
            _selectedItem = item;
            widget.onChanged?.call(item);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                _fieldController = textEditingController;
                _setupFocusListener(focusNode);
                return Container(
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? context.theme.scaffoldBackgroundColor
                        : context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    enabled: !isDisabled,
                    style: AppStyles.formText(context),
                    onFieldSubmitted: (_) => _commitSingleMatchOrRevert(),
                    decoration: InputDecoration(
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: iconColor,
                      ),
                      contentPadding: const EdgeInsets.only(top: 0, left: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            _maybeScrollToSelected();
            return ExcludeFocus(
              child: Align(
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        right: BorderSide(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        bottom: BorderSide(
                          color: context.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        controller: _optionsScrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemExtent: _optionItemExtent,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final item = options.elementAt(index);
                          final isSelected =
                              item.value == _selectedItem?.value;
                          return ListTile(
                            leading: item.iconData != null
                                ? Icon(
                                    item.iconData,
                                    color: item.iconColor ?? iconColor,
                                  )
                                : null,
                            title: Text(
                              item.label,
                              style: AppStyles.formText(context).copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.bold : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: context.colorScheme.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => onSelected(item),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
