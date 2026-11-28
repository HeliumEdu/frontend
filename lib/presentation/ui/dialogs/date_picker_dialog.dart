import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/components/helium_text.dart';

const _landscapeHelpTextWidth = 120.0;

const _landscapeHelpMaxTextScale = 1.4;

Future<DateTime?> showHeliumDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  SelectableDayPredicate? selectableDayPredicate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: selectableDayPredicate,
    builder: _fitLandscapeHelpText,
  );
}

Widget _fitLandscapeHelpText(BuildContext context, Widget? child) {
  if (MediaQuery.orientationOf(context) != Orientation.landscape) {
    return child!;
  }

  final datePickerTheme = DatePickerTheme.of(context);
  final helpStyle =
      datePickerTheme.headerHelpStyle ??
      DatePickerTheme.defaults(context).headerHelpStyle!;
  final (:fontSize, fits: _) = HeliumText.fit(
    text: MaterialLocalizations.of(context).datePickerHelpText,
    style: Theme.of(context).textTheme.bodyMedium!.merge(helpStyle),
    textScaler: MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: _landscapeHelpMaxTextScale),
    maxWidth: _landscapeHelpTextWidth,
    textDirection: Directionality.of(context),
  );
  if (fontSize == helpStyle.fontSize) {
    return child!;
  }

  return DatePickerTheme(
    data: datePickerTheme.copyWith(
      headerHelpStyle: helpStyle.copyWith(fontSize: fontSize),
    ),
    child: child!,
  );
}
