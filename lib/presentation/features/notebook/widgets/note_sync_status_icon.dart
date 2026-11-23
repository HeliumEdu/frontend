import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/utils/app_style.dart';

enum NoteSaveStatus { unsaved, saving, saved, error }

class NoteSyncStatusIcon extends StatelessWidget {
  final bool isAutoSavePaused;
  final NoteSaveStatus saveStatus;
  final bool willRetrySave;
  final NoteModel? note;
  final VoidCallback onRetry;

  const NoteSyncStatusIcon({
    super.key,
    required this.isAutoSavePaused,
    required this.saveStatus,
    required this.willRetrySave,
    required this.note,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isAutoSavePaused) {
      return HeliumIconButton(
        onPressed: onRetry,
        icon: Icons.cloud_off_outlined,
        color: context.semanticColors.warning,
        filled: false,
        label: saveStatus == NoteSaveStatus.error && willRetrySave
            ? 'Auto-save paused, will retry'
            : 'Auto-save paused',
      );
    }

    final IconData icon;
    final Color color;
    final String tooltip;

    if (note == null) {
      icon = Icons.cloud_outlined;
      color = context.colorScheme.onSurface.withValues(
        alpha: AppStyles.mutedTextAlpha,
      );
      tooltip = 'Auto-save not yet active';
    } else {
      icon = Icons.cloud_done_outlined;
      color = context.colorScheme.primary;
      tooltip = 'Auto-save active';
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: HeliumIconButton.padding,
        child: Icon(
          icon,
          size: HeliumIconButton.defaultIconSize(context),
          color: color,
        ),
      ),
    );
  }
}
