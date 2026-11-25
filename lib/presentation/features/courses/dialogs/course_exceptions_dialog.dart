import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
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
/// course-level exceptions). With [scheduleLabels], each date has a scope: all
/// meetings ([exceptions]) or one schedule's ([scheduleExceptions], keyed like
/// [scheduleLabels]), picked within that schedule's [scheduleDateRanges] entry.
/// With [onConfirm], confirming awaits it with the edited lists, staying open
/// to show the error it returns.
class CourseExceptionsDialog extends StatefulWidget {
  final String title;
  final List<DateTime> exceptions;
  final Map<int, String> scheduleLabels;
  final Map<int, List<DateTime>> scheduleExceptions;
  final Map<int, DateTimeRange> scheduleDateRanges;
  final List<DateTime> readOnlyExceptions;
  final String? readOnlyLabel;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Future<String?> Function(
    List<DateTime> exceptions,
    Map<int, List<DateTime>> scheduleExceptions,
  )?
  onConfirm;

  const CourseExceptionsDialog({
    super.key,
    required this.title,
    required this.exceptions,
    this.onConfirm,
    this.scheduleLabels = const {},
    this.scheduleExceptions = const {},
    this.scheduleDateRanges = const {},
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
  late Map<int, List<DateTime>> _scheduleExceptions;

  @override
  String get dialogTitle => widget.title;

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();
    _exceptions = List<DateTime>.from(widget.exceptions);
    _scheduleExceptions = {
      for (final scheduleId in widget.scheduleLabels.keys)
        scheduleId: List<DateTime>.from(
          widget.scheduleExceptions[scheduleId] ?? const [],
        ),
    };
  }

  bool get _showsScopes => widget.scheduleLabels.isNotEmpty;

  List<({DateTime date, int? scheduleId})> get _entries => [
    for (final date in _exceptions) (date: date, scheduleId: null),
    for (final MapEntry(key: scheduleId, value: dates) in _scheduleExceptions.entries)
      for (final date in dates) (date: date, scheduleId: scheduleId),
  ]..sort((a, b) => a.date.compareTo(b.date));

  String _scopeLabel(int? scheduleId) => scheduleId == null
      ? 'All meetings'
      : widget.scheduleLabels[scheduleId]!;

  List<DateTime> _cancelledFor(int? scheduleId) => [
    ..._exceptions,
    if (scheduleId != null) ..._scheduleExceptions[scheduleId]!,
  ];

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

  DateTime? _selectableInitialDate(
    List<DateTime> cancelled,
    DateTime? firstDate,
    DateTime? lastDate,
  ) {
    return CourseExceptionHelpers.firstSelectableDate(
      exceptions: cancelled,
      today: HeliumDateTime.dateOnly(DateTime.now()),
      firstDate: firstDate,
      lastDate: lastDate ?? HeliumDateTime.latestPickableDate(),
    );
  }

  void _addDate(BuildContext anchorContext) {
    if (!_showsScopes) {
      _pickDate(null);
      return;
    }

    showHeliumMenu(
      context: context,
      anchorContext: anchorContext,
      builder: (menuContext, _) => HeliumMenuContent(
        width: HeliumMenuContent.listWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeliumMenuTitle(title: 'Cancel which meetings?'),
            const SizedBox(height: 8),
            for (final option in [null, ...widget.scheduleLabels.keys])
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  _scopeLabel(option),
                  style: AppStyles.formText(menuContext),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(menuContext);
                  _pickDate(option);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(int? scheduleId) async {
    final range = scheduleId == null
        ? null
        : widget.scheduleDateRanges[scheduleId];
    final firstDate = range?.start ?? widget.firstDate;
    final lastDate = range?.end ?? widget.lastDate;
    final cancelled = _cancelledFor(scheduleId);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectableInitialDate(cancelled, firstDate, lastDate),
      firstDate: firstDate ?? HeliumDateTime.earliestPickableDate(),
      lastDate: lastDate ?? HeliumDateTime.latestPickableDate(),
      confirmText: 'Select',
      selectableDayPredicate: (date) => _isSelectable(cancelled, date),
    );
    if (picked == null || !mounted) return;

    final dateOnly = HeliumDateTime.dateOnly(picked);
    _formController.markChanged();
    setState(() {
      if (scheduleId case final scheduleId?) {
        _scheduleExceptions[scheduleId] = [
          ..._scheduleExceptions[scheduleId]!,
          dateOnly,
        ]..sort();
      } else {
        _exceptions = [..._exceptions, dateOnly]..sort();
      }
    });
  }

  bool _isSelectable(List<DateTime> cancelled, DateTime date) =>
      !CourseExceptionHelpers.isExcepted(cancelled, date);

  void _removeDate(DateTime date, int? scheduleId) {
    _formController.markChanged();
    setState(() {
      if (scheduleId case final scheduleId?) {
        _scheduleExceptions[scheduleId] = _without(
          _scheduleExceptions[scheduleId]!,
          date,
        );
      } else {
        _exceptions = _without(_exceptions, date);
      }
    });
  }

  List<DateTime> _without(List<DateTime> dates, DateTime date) =>
      dates.where((excepted) => !Sort.isSameDate(excepted, date)).toList();

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
    final error = onConfirm == null
        ? null
        : await onConfirm(edited, Map.unmodifiable(_scheduleExceptions));
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
    final entries = _entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dates', style: AppStyles.featureText(context)),
            Builder(
              builder: (buttonContext) => HeliumIconButton(
                onPressed: () => _addDate(buttonContext),
                icon: Icons.add,
                showTooltip: false,
                label: 'Add date',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: entries.isEmpty
              ? const EmptyCard(
                  icon: Icons.block_outlined,
                  message: 'Click "+" to add a date',
                  expanded: false,
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _buildEditableRow(
                    context,
                    entries[index].date,
                    entries[index].scheduleId,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(BuildContext context, DateTime date, int? scheduleId) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HeliumDateTime.formatDate(date),
                    style: AppStyles.standardBodyTextLight(context),
                  ),
                  if (_showsScopes)
                    Text(
                      _scopeLabel(scheduleId),
                      style: AppStyles.smallSecondaryTextLight(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            HeliumIconButton(
              onPressed: () => _removeDate(date, scheduleId),
              icon: Icons.delete_outline,
              color: context.colorScheme.error,
              label: 'Remove',
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

/// Shows a [CourseExceptionsDialog] for a class's cancellations, saving them
/// with [onConfirm] when confirmed.
///
/// [scheduleLabels], [scheduleExceptions] and [scheduleDateRanges] give each
/// date a scope (see [CourseExceptionsDialog]). [courseGroupExceptions] are shown read-only as
/// semester context.
Future<void> showCourseExceptionsDialog({
  required BuildContext context,
  required List<DateTime> courseExceptions,
  required Future<String?> Function(
    List<DateTime> exceptions,
    Map<int, List<DateTime>> scheduleExceptions,
  )
  onConfirm,
  Map<int, String> scheduleLabels = const {},
  Map<int, List<DateTime>> scheduleExceptions = const {},
  Map<int, DateTimeRange> scheduleDateRanges = const {},
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
      scheduleLabels: scheduleLabels,
      scheduleExceptions: scheduleExceptions,
      scheduleDateRanges: scheduleDateRanges,
      readOnlyExceptions: courseGroupExceptions,
      readOnlyLabel: 'Also cancelled via Holidays & Breaks',
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
