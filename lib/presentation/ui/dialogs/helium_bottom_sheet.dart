import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';

/// Scrolling content pads itself with `Responsive.sheetContentPadding`;
/// fixed content wraps in `SafeArea(top: false)`.
Future<T?> showHeliumBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: builder,
  );
}
