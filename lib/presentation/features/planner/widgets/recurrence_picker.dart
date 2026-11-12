import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/helium_picker_field.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';
import 'package:heliumapp/presentation/ui/components/weekday_selector.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

/// Edits how a planner item repeats. A null [draft] is a repeat the picker
/// can't represent (e.g. one imported from another calendar), shown as a
/// custom repeat until a preset replaces it.
class RecurrencePicker extends StatefulWidget {
  final RecurrenceDraft? draft;
  final DateTime localStart;
  final bool isEvent;
  final int weekStartsOn;
  final DateTime? lastUntilDate;
  final ValueChanged<RecurrenceDraft> onChanged;

  const RecurrencePicker({
    super.key,
    required this.draft,
    required this.localStart,
    required this.isEvent,
    required this.weekStartsOn,
    required this.onChanged,
    this.lastUntilDate,
  });

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  static const _customId = -1;

  static const _frequencyLabels = {
    RecurrenceFrequency.none: 'Does not repeat',
    RecurrenceFrequency.daily: 'Daily',
    RecurrenceFrequency.weekly: 'Weekly',
    RecurrenceFrequency.monthly: 'Monthly',
    RecurrenceFrequency.yearly: 'Yearly',
  };

  static const _intervalUnits = {
    RecurrenceFrequency.daily: 'day',
    RecurrenceFrequency.weekly: 'week',
    RecurrenceFrequency.monthly: 'month',
    RecurrenceFrequency.yearly: 'year',
  };

  static const _gap = 12.0;
  static const _countFieldWidth = 104.0;
  static const _unitGap = 8.0;

  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(RecurrencePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft?.interval != widget.draft?.interval ||
        oldWidget.draft?.count != widget.draft?.count) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildForConstraints);
  }

  Widget _buildForConstraints(BuildContext context, BoxConstraints constraints) {
    return _buildPicker(context, _intervalFitsBesideRepeat(context, constraints.maxWidth));
  }

  Widget _buildPicker(BuildContext context, bool intervalBesideRepeat) {
    final draft = widget.draft;
    final frequencyItems = _frequencyItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DropDown<RecurrenceFrequency>(
                label: 'Repeat',
                initialValue: frequencyItems.firstWhere(
                  (item) => item.id == (draft == null ? _customId : draft.frequency.index),
                ),
                items: frequencyItems,
                onChanged: _onFrequencyChanged,
              ),
            ),
            if (draft != null && draft.repeats && intervalBesideRepeat) ...[
              const SizedBox(width: _gap),
              Expanded(child: _buildIntervalField(context, draft)),
            ],
          ],
        ),
        if (draft == null) ...[
          const SizedBox(height: 8),
          Text(
            'This repeat was set up elsewhere and can\'t be edited here. Choose a repeat to replace it.',
            style: AppStyles.smallSecondaryTextLight(context),
          ),
        ],
        if (draft != null && draft.repeats) ..._buildRepeatOptions(context, draft, intervalBesideRepeat),
      ],
    );
  }

  void _syncControllers() {
    final draft = widget.draft;
    final interval = '${draft?.interval ?? 1}';
    final count = '${draft?.count ?? 10}';
    if (_intervalController.text != interval) _intervalController.text = interval;
    if (_countController.text != count) _countController.text = count;
  }

  List<DropDownItem<RecurrenceFrequency>> get _frequencyItems => [
        if (widget.draft == null) DropDownItem(id: _customId, label: 'Custom repeat'),
        for (final frequency in RecurrenceFrequency.values)
          DropDownItem(id: frequency.index, value: frequency, label: _frequencyLabels[frequency]),
      ];

  List<DropDownItem<RecurrenceEnd>> get _endItems => [
        DropDownItem(
          id: RecurrenceEnd.defaultEnd.index,
          value: RecurrenceEnd.defaultEnd,
          label: widget.isEvent ? 'Never' : 'End of class',
        ),
        DropDownItem(id: RecurrenceEnd.onDate.index, value: RecurrenceEnd.onDate, label: 'On date'),
        DropDownItem(id: RecurrenceEnd.afterCount.index, value: RecurrenceEnd.afterCount, label: 'After'),
      ];

  bool _intervalFitsBesideRepeat(BuildContext context, double width) {
    final widestUnit = _intervalUnits.values.map((unit) => _textWidth(context, '${unit}s')).reduce(math.max);
    return (width - _gap) / 2 >= _countFieldWidth + _unitGap + widestUnit;
  }

  double _textWidth(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppStyles.formText(context)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _buildIntervalField(BuildContext context, RecurrenceDraft draft) {
    final unit = _intervalUnits[draft.frequency]!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: SpinnerField(
            label: 'Every',
            controller: _intervalController,
            minValue: 1,
            maxValue: 99,
            maxSpinnerWidth: _countFieldWidth,
            onChanged: _onIntervalChanged,
          ),
        ),
        const SizedBox(width: _unitGap),
        Padding(
          padding: EdgeInsets.only(bottom: AppStyles.formFieldVerticalPadding(context) + AppStyles.formFieldBorderWidth),
          child: Stack(
            children: [
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text('${unit}s', style: AppStyles.formText(context)),
              ),
              Text(draft.interval == 1 ? unit : '${unit}s', style: AppStyles.formText(context)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRepeatOptions(BuildContext context, RecurrenceDraft draft, bool intervalBesideRepeat) {
    return [
      if (!intervalBesideRepeat) ...[
        const SizedBox(height: 14),
        _buildIntervalField(context, draft),
      ],
      if (draft.frequency == RecurrenceFrequency.weekly)
        Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _buildLastDayOfMonthTile(context, draft),
            ),
            WeekdaySelector(
              selected: draft.weekdays,
              weekStartsOn: widget.weekStartsOn,
              onChanged: _onWeekdaysChanged,
            ),
          ],
        ),
      if (draft.frequency == RecurrenceFrequency.monthly &&
          HeliumRecurrence.offersLastDayOfMonth(widget.localStart))
        _buildLastDayOfMonthTile(context, draft),
      const SizedBox(height: 14),
      _buildEndRow(context, draft),
    ];
  }

  Widget _buildLastDayOfMonthTile(BuildContext context, RecurrenceDraft draft) {
    return HeliumCheckboxListTile(
      title: Text('On the last day of the month', style: AppStyles.formLabel(context)),
      subtitle: Text(
        'Otherwise, months without day ${widget.localStart.day} are skipped.',
        style: AppStyles.smallSecondaryTextLight(context),
      ),
      value: draft.lastDayOfMonth,
      onChanged: _onLastDayOfMonthChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEndRow(BuildContext context, RecurrenceDraft draft) {
    final endItems = _endItems;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DropDown<RecurrenceEnd>(
            label: 'Ends',
            initialValue: endItems.firstWhere((item) => item.value == draft.end),
            items: endItems,
            onChanged: _onEndChanged,
          ),
        ),
        if (draft.end == RecurrenceEnd.onDate) ...[
          const SizedBox(width: _gap),
          Expanded(
            child: HeliumDateField(
              label: 'End date',
              date: draft.until ?? widget.localStart,
              onTap: _selectUntilDate,
            ),
          ),
        ],
        if (draft.end == RecurrenceEnd.afterCount) ...[
          const SizedBox(width: _gap),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: _countFieldWidth,
                child: SpinnerField(
                  label: 'Occurrences',
                  controller: _countController,
                  minValue: 1,
                  maxValue: 366,
                  onChanged: _onCountChanged,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

    RecurrenceDraft get _current => widget.draft ?? const RecurrenceDraft();

  void _onFrequencyChanged(DropDownItem<RecurrenceFrequency>? item) {
    final frequency = item?.value;
    if (frequency == null) return;
    final current = widget.draft;
    if (current != null && current.repeats && frequency != RecurrenceFrequency.none) {
      widget.onChanged(current.copyWith(
        frequency: frequency,
        weekdays: current.weekdays.isEmpty ? {HeliumDateTime.getDayIndex(widget.localStart)} : null,
      ));
    } else {
      widget.onChanged(HeliumRecurrence.defaultFor(frequency, widget.localStart));
    }
  }

  void _onIntervalChanged(String value) {
    final interval = int.tryParse(value);
    if (interval == null || interval < 1) return;
    widget.onChanged(_current.copyWith(interval: interval));
  }

  void _onWeekdaysChanged(Set<int> weekdays) {
    widget.onChanged(_current.copyWith(weekdays: weekdays));
  }

  void _onLastDayOfMonthChanged(bool? value) {
    widget.onChanged(_current.copyWith(lastDayOfMonth: value ?? false));
  }

  void _onEndChanged(DropDownItem<RecurrenceEnd>? item) {
    final end = item?.value;
    if (end == null) return;
    widget.onChanged(_current.copyWith(
      end: end,
      until: end == RecurrenceEnd.onDate ? (_current.until ?? _defaultUntil) : null,
      count: end == RecurrenceEnd.afterCount ? (_current.count ?? 10) : null,
    ));
  }

  DateTime get _defaultUntil {
    final start = widget.localStart;
    final suggested = DateTime(start.year, start.month + 1, start.day);
    final last = widget.lastUntilDate;
    return last != null && suggested.isAfter(last) ? last : suggested;
  }

  void _onCountChanged(String value) {
    final count = int.tryParse(value);
    if (count == null || count < 1) return;
    widget.onChanged(_current.copyWith(count: count));
  }

  Future<void> _selectUntilDate() async {
    final start = DateTime(widget.localStart.year, widget.localStart.month, widget.localStart.day);
    final current = _current.until ?? _defaultUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(start) ? start : current,
      firstDate: start,
      lastDate: DateTime(start.year + 5, start.month, start.day),
      confirmText: 'Select',
    );
    if (picked == null) return;
    widget.onChanged(_current.copyWith(until: picked));
  }
}
