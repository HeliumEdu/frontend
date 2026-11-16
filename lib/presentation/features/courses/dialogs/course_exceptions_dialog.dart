import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/course_exception_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';

/// Edits a list of exception dates in memory, for both class cancellations and
/// group holidays, and returns the edited list when confirmed.
///
/// [exceptions] is the current editable list. [readOnlyExceptions] are shown
/// as informational context only (e.g. semester holidays when editing
/// course-level exceptions). With [onConfirm], confirming awaits it with the
/// edited list, staying open to show the error it returns.
class CourseExceptionsDialog extends StatefulWidget {
  final String title;
  final List<DateTime> exceptions;
  final List<DateTime> readOnlyExceptions;
  final String? readOnlyLabel;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Future<String?> Function(List<DateTime> exceptions)? onConfirm;

  const CourseExceptionsDialog({
    super.key,
    required this.title,
    required this.exceptions,
    this.onConfirm,
    this.readOnlyExceptions = const [],
    this.readOnlyLabel,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CourseExceptionsDialog> createState() => _CourseExceptionsDialogState();
}

class _CourseExceptionsDialogState
    extends BaseDialogState<CourseExceptionsDialog> {
  static const _datesListHeight = 300.0;

  final BasicFormController _formController = BasicFormController();
  late List<DateTime> _exceptions;

  @override
  String get dialogTitle => widget.title;

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();
    _exceptions = List<DateTime>.from(widget.exceptions);
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _datesListHeight,
          child: _buildEditableSection(context),
        ),
        if (widget.readOnlyExceptions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildReadOnlySection(context),
        ],
      ],
    );
  }

  DateTime? _selectableInitialDate() {
    return CourseExceptionHelpers.firstSelectableDate(
      exceptions: _exceptions,
      today: HeliumDateTime.dateOnly(DateTime.now()),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate ??
          HeliumDateTime.latestPickableDate(),
    );
  }

  Future<void> _addDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectableInitialDate(),
      firstDate: widget.firstDate ??
          HeliumDateTime.earliestPickableDate(),
      lastDate:
          widget.lastDate ?? HeliumDateTime.latestPickableDate(),
      confirmText: 'Select',
      selectableDayPredicate: _isSelectable,
    );
    if (picked == null) return;

    final dateOnly = HeliumDateTime.dateOnly(picked);
    _formController.markChanged();
    setState(() {
      _exceptions = [..._exceptions, dateOnly]..sort();
    });
  }

  bool _isSelectable(DateTime date) =>
      !CourseExceptionHelpers.isExcepted(_exceptions, date);

  void _removeDate(DateTime date) {
    _formController.markChanged();
    setState(() {
      _exceptions = _exceptions
          .where((excepted) => !Sort.isSameDate(excepted, date))
          .toList();
    });
  }

  @override
  Future<void> handleSubmit() async {
    if (!_formController.isChanged) {
      cancelAction();
      return;
    }
    super.handleSubmit();
    if (!isSubmitting) return;
    setState(() => errorMessage = null);

    final edited = List<DateTime>.unmodifiable(_exceptions);
    final onConfirm = widget.onConfirm;
    final error = onConfirm == null ? null : await onConfirm(edited);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        isSubmitting = false;
        errorMessage = error;
      });
      return;
    }
    Navigator.pop(context, edited);
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
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 12),
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
          widget.readOnlyLabel!,
          style: AppStyles.smallSecondaryTextLight(context),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final date in widget.readOnlyExceptions)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 13,
                    color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedIconAlpha),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    HeliumDateTime.formatDate(date),
                    style: AppStyles.standardBodyTextLight(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Shows a [CourseExceptionsDialog] for course-level cancellations, saving
/// them with [onConfirm] when confirmed.
///
/// [courseGroupExceptions] are shown read-only as semester context.
Future<void> showCourseExceptionsDialog({
  required BuildContext context,
  required List<DateTime> courseExceptions,
  required Future<String?> Function(List<DateTime> exceptions) onConfirm,
  List<DateTime> courseGroupExceptions = const [],
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => CourseExceptionsDialog(
      title: 'Cancellations',
      exceptions: courseExceptions,
      onConfirm: onConfirm,
      readOnlyExceptions: courseGroupExceptions,
      readOnlyLabel: 'Also cancelled via class group exceptions',
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

/// Shows a [CourseExceptionsDialog] for course-group holidays, returning the
/// edited dates when confirmed, or null when closed without changes.
Future<List<DateTime>?> showCourseGroupExceptionsDialog({
  required BuildContext context,
  required List<DateTime> exceptions,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<List<DateTime>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CourseExceptionsDialog(
      title: 'Holidays & Breaks',
      exceptions: exceptions,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
