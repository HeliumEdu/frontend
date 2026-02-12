// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:html_editor_enhanced/html_editor.dart';


class LabelAndHtmlEditor extends StatelessWidget {
  final String label;
  final HtmlEditorController controller;
  final String? initialText;

  const LabelAndHtmlEditor({
    super.key,
    required this.label,
    required this.controller,
    this.initialText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.formLabel(context)),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            child: HtmlEditor(
              controller: controller,
              htmlToolbarOptions: const HtmlToolbarOptions(
                toolbarType: ToolbarType.nativeGrid,
                defaultToolbarButtons: [
                  FontButtons(
                    superscript: false,
                    subscript: false,
                    clearAll: false,
                  ),
                  ListButtons(listStyles: false),
                  ParagraphButtons(
                    alignLeft: false,
                    alignCenter: false,
                    alignRight: false,
                    alignJustify: false,
                    textDirection: false,
                    lineHeight: false,
                    caseConverter: false,
                  ),
                ],
              ),
              htmlEditorOptions: HtmlEditorOptions(
                hint: '',
                initialText: initialText,
                autoAdjustHeight: true,
                darkMode: context.isDarkMode,
              ),
              otherOptions: const OtherOptions(
                height: 300,
                decoration: BoxDecoration(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
