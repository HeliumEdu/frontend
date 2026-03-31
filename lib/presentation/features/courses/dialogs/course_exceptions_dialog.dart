// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_container.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Reusable dialog for managing a list of exception dates.
///
/// Used for both course-level cancellations and course-group holidays.
/// [exceptions] is the current editable list. [readOnlyExceptions] are shown
/// as informational context only (e.g. semester holidays when editing
/// course-level exceptions).
class CourseExceptionsDialog extends StatefulWidget {
  final String title;
  final List<DateTime> exceptions;
  final Future<void> Function(List<DateTime>) onSave;
  final List<DateTime> readOnlyExceptions;
  final String? readOnlyLabel;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CourseExceptionsDialog({
    super.key,
    required this.title,
    required this.exceptions,
    required this.onSave,
    this.readOnlyExceptions = const [],
    this.readOnlyLabel,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CourseExceptionsDialog> createState() => _CourseExceptionsDialogState();
}

class _CourseExceptionsDialogState extends State<CourseExceptionsDialog> {
  late List<DateTime> _exceptions;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _exceptions = List<DateTime>.from(widget.exceptions);
  }

  Future<void> _addDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.firstDate ??
          DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate:
          widget.lastDate ?? DateTime.now().add(const Duration(days: 365 * 10)),
      confirmText: 'Select',
    );
    if (picked == null) return;

    final dateOnly = DateTime(picked.year, picked.month, picked.day);
    final alreadyExists = _exceptions.any(
      (d) =>
          d.year == dateOnly.year &&
          d.month == dateOnly.month &&
          d.day == dateOnly.day,
    );
    if (!alreadyExists) {
      setState(() {
        _exceptions = [..._exceptions, dateOnly]..sort();
      });
    }
  }

  void _removeDate(DateTime date) {
    setState(() {
      _exceptions =
          _exceptions
              .where(
                (d) =>
                    d.year != date.year ||
                    d.month != date.month ||
                    d.day != date.day,
              )
              .toList();
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_exceptions);
      if (mounted) Navigator.pop(context);
    } on HeliumException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.displayMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.isMobile(context)
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: Responsive.getDialogWidth(context),
        height: 480,
        child: Material(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.title,
                    style: AppStyles.pageTitle(context),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(child: _buildEditableSection(context)),

                if (widget.readOnlyExceptions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildReadOnlySection(context),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  ErrorContainer(
                    text: _errorMessage!,
                    onDismiss: () =>
                        setState(() => _errorMessage = null),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
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
                        buttonText: 'Save',
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dates', style: AppStyles.featureText(context)),
            HeliumIconButton(
              onPressed: _addDate,
              icon: Icons.add,
              tooltip: 'Add date',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _exceptions.isEmpty
              ? const EmptyCard(
                  icon: Icons.block_outlined,
                  message: 'Click "+" to add a date',
                  expanded: false,
                )
              : ListView.builder(
                  itemCount: _exceptions.length,
                  itemBuilder: (context, index) =>
                      _buildEditableRow(context, _exceptions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(BuildContext context, DateTime date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                HeliumDateTime.formatDate(date),
                style: AppStyles.standardBodyTextLight(context),
              ),
            ),
            HeliumIconButton(
              onPressed: () => _removeDate(date),
              icon: Icons.delete_outline,
              color: context.colorScheme.error,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: context.colorScheme.outline.withValues(alpha: 0.3)),
        const SizedBox(height: 4),
        Text(
          widget.readOnlyLabel ?? 'Also cancelled',
          style: AppStyles.smallSecondaryTextLight(context),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.readOnlyExceptions.length,
          itemBuilder: (context, index) =>
              _buildReadOnlyRow(context, widget.readOnlyExceptions[index]),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(BuildContext context, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.block_outlined,
            size: 14,
            color: context.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Text(
            HeliumDateTime.formatDate(date),
            style: AppStyles.standardBodyTextLight(context).copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a [CourseExceptionsDialog] for course-level cancellations.
///
/// [courseGroupId] and [courseId] are used to build the save callback.
/// [courseGroupExceptions] are shown read-only as semester context.
Future<void> showCourseExceptionsDialog({
  required BuildContext context,
  required String courseTitle,
  required List<DateTime> courseExceptions,
  required Future<void> Function(List<DateTime>) onSave,
  List<DateTime> courseGroupExceptions = const [],
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CourseExceptionsDialog(
      title: 'Class Cancellations',
      exceptions: courseExceptions,
      onSave: onSave,
      readOnlyExceptions: courseGroupExceptions,
      readOnlyLabel: 'Also cancelled via semester holidays',
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

/// Shows a [CourseExceptionsDialog] for course-group holidays.
Future<void> showCourseGroupExceptionsDialog({
  required BuildContext context,
  required List<DateTime> exceptions,
  required Future<void> Function(List<DateTime>) onSave,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CourseExceptionsDialog(
      title: 'Holidays & Breaks',
      exceptions: exceptions,
      onSave: onSave,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
