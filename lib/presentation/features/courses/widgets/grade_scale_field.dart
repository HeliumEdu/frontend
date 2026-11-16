import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/presentation/features/courses/dialogs/grade_scale_dialog.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

/// A grade scale picker: a drop-down of [items], a button showing the
/// selected scale's [bands] titled [bandsTitle], and its top grade beneath.
/// The drop-down is disabled unless [enabled]; [hint], when given, explains
/// why in place of the top grade.
class GradeScaleField extends StatelessWidget {
  final List<DropDownItem<int>> items;
  final int selected;
  final List<GradeScaleBandModel> bands;
  final String bandsTitle;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final String? hint;

  const GradeScaleField({
    super.key,
    required this.items,
    required this.selected,
    required this.bands,
    required this.bandsTitle,
    required this.onChanged,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropDown<int>(
      key: ValueKey(selected),
      label: 'Grade scale',
      initialValue: items.firstWhereOrNull((item) => item.id == selected),
      items: items,
      onChanged: enabled ? _onItemChanged : null,
      trailingIconButton: HeliumIconButton(
        onPressed: () => _showBands(context),
        enabled: bands.isNotEmpty,
        icon: Icons.table_rows_outlined,
        tooltip: 'View grade scale',
      ),
      helperText: hint ?? (bands.isEmpty ? '' : _topBandSummary(bands.last)),
    );
  }

  void _showBands(BuildContext context) {
    showGradeScaleDialog(parentContext: context, title: bandsTitle, bands: bands);
  }

  void _onItemChanged(DropDownItem<int>? item) {
    if (item != null) onChanged(item.id);
  }

  String _topBandSummary(GradeScaleBandModel band) {
    final label = band.label.isEmpty ? '' : '${band.label} at ';
    return 'Top grade: $label${GradeHelper.minGradeForDisplay(band.minGrade)} = '
        '${GradeHelper.gradePointForDisplay(band.gradePoint)}';
  }
}
