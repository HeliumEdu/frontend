// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class _SelectWidget<T extends BaseModel> extends StatefulWidget {
  final List<T> items;
  final Set<int> initialSelected;
  final Function(Set<int>) onConfirm;
  final Color? color;

  const _SelectWidget({
    required this.items,
    required this.initialSelected,
    required this.onConfirm,
    this.color,
  });

  @override
  State<_SelectWidget<T>> createState() => _SelectWidgetState<T>();
}

class _SelectWidgetState<T extends BaseModel> extends State<_SelectWidget<T>> {
  // State
  final Set<int> selected = <int>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    selected.addAll(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final checked = selected.contains(item.id);

            Color? itemColor;
            if (item is CourseModel) {
              itemColor = item.color;
            }

            return CheckboxListTile(
              title: Row(
                children: [
                  if (itemColor != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(item.title, style: context.formText)),
                ],
              ),
              value: checked,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selected.add(item.id);
                  } else {
                    selected.remove(item.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Cancel',
                  backgroundColor: context.colorScheme.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: 'Confirm',
                  isLoading: _isSubmitting,
                  onPressed: () {
                    setState(() {
                      _isSubmitting = true;
                    });

                    Navigator.pop(context);
                    widget.onConfirm(selected);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showSelectDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required List<T> items,
  required Function(Set<int>) onConfirm,
  Set<int> initialSelected = const <int>{},
}) {
  return showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return _SelectWidget(
        items: items,
        initialSelected: initialSelected,
        onConfirm: onConfirm,
      );
    },
  );
}
