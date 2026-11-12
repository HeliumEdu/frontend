import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class _GradeScaleDialog extends StatelessWidget {
  final String title;
  final List<GradeScaleBandModel> bands;

  const _GradeScaleDialog({required this.title, required this.bands});

  @override
  Widget build(BuildContext context) {
    final hasLabels = bands.any((band) => band.label.isNotEmpty);

    return AlertDialog(
      backgroundColor: context.colorScheme.surface,
      title: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: Text('$title Grade Scale', style: AppStyles.headingText(context)),
      ),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: {
              0: const FlexColumnWidth(),
              if (hasLabels) 1: const FlexColumnWidth(),
              (hasLabels ? 2 : 1): const FlexColumnWidth(),
            },
            children: [
              _buildRow(context, [
                'Grade',
                if (hasLabels) 'Letter',
                'Points',
              ], isHeader: true),
              for (final band in bands.reversed)
                _buildRow(context, [
                  GradeHelper.minGradeForDisplay(band.minGrade),
                  if (hasLabels) band.label,
                  GradeHelper.gradePointForDisplay(band.gradePoint),
                ]),
            ],
          ),
        ),
      ),
      actions: [
        HeliumElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          buttonText: 'Close',
        ),
      ],
    );
  }

  TableRow _buildRow(
    BuildContext context,
    List<String> cells, {
    bool isHeader = false,
  }) {
    final style = isHeader
        ? AppStyles.standardBodyTextEmphasis(context)
        : AppStyles.standardBodyText(context);

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant,
            width: isHeader ? 1.5 : 0.5,
          ),
        ),
      ),
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(cell, style: style),
          ),
      ],
    );
  }
}

Future<void> showGradeScaleDialog({
  required BuildContext parentContext,
  required String title,
  required List<GradeScaleBandModel> bands,
}) {
  return showDialog(
    context: parentContext,
    builder: (_) => _GradeScaleDialog(title: title, bands: bands),
  );
}
