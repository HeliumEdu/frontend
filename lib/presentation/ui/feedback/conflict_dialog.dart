import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ConflictResolution { keepEditing, loadLatest, overwrite }

class ConflictWording {
  final String title;
  final String message;
  final String overwriteLabel;

  const ConflictWording({
    this.title = 'Changed on Another Device',
    this.message =
        'This was changed on another device after you opened it. Load the '
        'latest version and discard your changes, or overwrite it with your '
        'changes?',
    this.overwriteLabel = 'Overwrite',
  });
}

Future<void> resolveConflict(
  BuildContext context, {
  required VoidCallback onLoadLatest,
  required VoidCallback onOverwrite,
  bool canKeepEditing = false,
  ConflictWording wording = const ConflictWording(),
}) async {
  final resolution = await confirmConflictResolution(
    context,
    canKeepEditing: canKeepEditing,
    wording: wording,
  );
  if (!context.mounted) return;

  switch (resolution) {
    case ConflictResolution.keepEditing:
      return;
    case ConflictResolution.loadLatest:
      onLoadLatest();
    case ConflictResolution.overwrite:
      onOverwrite();
  }
}

mixin ConflictResolvableForm<W extends StatefulWidget> on State<W> {
  bool _isOverwriting = false;

  bool get isOverwriting => _isOverwriting;

  void loadLatest();

  void onSubmit();

  void overwriteNewer() {
    _isOverwriting = true;
    onSubmit();
    _isOverwriting = false;
  }
}

Future<void> resolveFormConflict(
  BuildContext context,
  ConflictResolvableForm? form, {
  bool canKeepEditing = false,
}) async {
  if (form == null) return;
  await resolveConflict(
    context,
    onLoadLatest: form.loadLatest,
    onOverwrite: form.overwriteNewer,
    canKeepEditing: canKeepEditing,
  );
}

@visibleForTesting
Future<ConflictResolution> confirmConflictResolution(
  BuildContext context, {
  bool canKeepEditing = false,
  ConflictWording wording = const ConflictWording(),
}) async {
  final result = await showDialog<ConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          wording.title,
          style: AppStyles.pageTitle(dialogContext),
        ),
        content: SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: Text(
            wording.message,
            style: AppStyles.standardBodyText(dialogContext),
          ),
        ),
        actions: [
          SizedBox(
            width: Responsive.getDialogWidth(dialogContext),
            child: _ConflictActions(
              canKeepEditing: canKeepEditing,
              overwriteLabel: wording.overwriteLabel,
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? ConflictResolution.keepEditing;
}

class _ConflictActions extends StatelessWidget {
  final bool canKeepEditing;
  final String overwriteLabel;

  const _ConflictActions({
    required this.canKeepEditing,
    required this.overwriteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      if (canKeepEditing)
        _ConflictButton(
          text: 'Keep Editing',
          resolution: ConflictResolution.keepEditing,
          backgroundColor: context.colorScheme.outline,
        ),
      const _ConflictButton(
        text: 'Load Latest',
        resolution: ConflictResolution.loadLatest,
      ),
      _ConflictButton(
        text: overwriteLabel,
        resolution: ConflictResolution.overwrite,
        backgroundColor: context.colorScheme.error,
      ),
    ];

    if (canKeepEditing && Responsive.useCompactLayout(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: buttons,
      );
    }
    return Row(
      spacing: 12,
      children: [for (final button in buttons) Expanded(child: button)],
    );
  }
}

class _ConflictButton extends StatelessWidget {
  final String text;
  final ConflictResolution resolution;
  final Color? backgroundColor;

  const _ConflictButton({
    required this.text,
    required this.resolution,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return HeliumElevatedButton(
      buttonText: text,
      backgroundColor: backgroundColor,
      onPressed: () => Navigator.of(context).pop(resolution),
    );
  }
}
