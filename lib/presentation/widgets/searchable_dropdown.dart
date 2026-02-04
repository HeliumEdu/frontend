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
  TextEditingController? _fieldController;
  FocusNode? _focusNode;

  // State
  List<DropDownItem<T>> _filteredOptions = [];
  DropDownItem<T>? _selectedItem;

  @override
  void initState() {
    super.initState();

    _selectedItem = widget.initialValue;
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _revertToSelected() {
    if (_fieldController != null && _selectedItem != null) {
      _fieldController!.text = _selectedItem!.value.toString();
    }
  }

  void _onFocusChange() {
    if (_focusNode != null && !_focusNode!.hasFocus) {
      final text = _fieldController!.text;
      final exactMatch = widget.items.where(
        (item) => item.value.toString() == text,
      );
      if (exactMatch.isEmpty) {
        _revertToSelected();
      }
    }
  }

  void _setupFocusListener(FocusNode focusNode) {
    if (_focusNode != focusNode) {
      _focusNode?.removeListener(_onFocusChange);
      _focusNode = focusNode;
      _focusNode!.addListener(_onFocusChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onChanged == null;
    final iconColor = isDisabled
        ? context.colorScheme.onSurface.withValues(alpha: 0.4)
        : context.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) Text(widget.label!, style: AppStyles.formLabel(context)),
        if (widget.label != null) const SizedBox(height: 9),
        Autocomplete<DropDownItem<T>>(
          key: ValueKey(widget.initialValue.value),
          initialValue: TextEditingValue(
            text: widget.initialValue.value.toString(),
          ),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              _filteredOptions = widget.items;
            } else {
              final query = textEditingValue.text.toLowerCase();
              _filteredOptions = widget.items
                  .where(
                    (item) =>
                        item.value.toString().toLowerCase().contains(query),
                  )
                  .toList();
            }
            return _filteredOptions;
          },
          displayStringForOption: (item) => item.value.toString(),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    enabled: !isDisabled,
                    style: AppStyles.formText(context),
                    onFieldSubmitted: (_) {
                      if (_filteredOptions.length == 1) {
                        final item = _filteredOptions.first;
                        _selectedItem = item;
                        textEditingController.text = item.value.toString();
                        widget.onChanged?.call(item);
                      } else {
                        _revertToSelected();
                      }
                    },
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
            return Align(
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
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final item = options.elementAt(index);
                        return ListTile(
                          leading: item.iconData != null
                              ? Icon(
                                  item.iconData,
                                  color: item.iconColor ?? iconColor,
                                )
                              : null,
                          title: Text(
                            item.value.toString(),
                            style: AppStyles.formText(context),
                          ),
                          onTap: () => onSelected(item),
                        );
                      },
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
