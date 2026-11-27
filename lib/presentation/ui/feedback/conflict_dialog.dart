import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heliumapp/config/analytics_event.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:timezone/standalone.dart' as tz;

enum ConflictResolution { keepEditing, loadLatest, overwrite }

/// A conflict's text. [body] ends in one question that [saveLabel]
/// answers yes to; [discardLabel] answers no.
class ConflictMessage {
  final String title;
  final String body;
  final String discardLabel;
  final String saveLabel;
  final bool isSaveDestructive;

  const ConflictMessage({
    required this.title,
    required this.body,
    required this.discardLabel,
    required this.saveLabel,
    this.isSaveDestructive = false,
  });

  /// The default message, saying when the other device saved [latestVersion].
  /// [item] names what changed: assignment, event, class, resource or note,
  /// and anything else reads "This".
  factory ConflictMessage.changedAt(
    AppLocalizations l10n,
    String? latestVersion, {
    String item = 'other',
  }) {
    final when = describeVersionSaved(latestVersion);
    return ConflictMessage(
      title: l10n.conflictChangedTitle,
      body: when == null ? l10n.conflictChangedMessage(item) : l10n.conflictChangedAtMessage(item, when),
      discardLabel: l10n.conflictDiscardChangesButton,
      saveLabel: l10n.conflictSaveChangesButton,
    );
  }
}

/// When [version], an item's `updated_at`, was saved, in the user's time
/// zone; null when it isn't a time or the zone isn't loaded.
String? describeVersionSaved(String? version) {
  final savedAt = version == null ? null : DateTime.tryParse(version);
  final timeZoneName = LocaleNotifier().timeZone;
  final timeZone = timeZoneName == null
      ? null
      : tz.timeZoneDatabase.locations[timeZoneName];
  if (savedAt == null || timeZone == null) return null;
  return HeliumDateTime.describeWhen(savedAt, timeZone);
}

Future<void> resolveConflict(
  BuildContext context, {
  required VoidCallback onLoadLatest,
  required VoidCallback onOverwrite,
  bool canKeepEditing = false,
  required ConflictMessage message,
}) async {
  final resolution = await confirmConflictResolution(
    context,
    canKeepEditing: canKeepEditing,
    message: message,
  );
  unawaited(
    AnalyticsService().logEvent(
      name: AnalyticsEvent.conflictResolve,
      parameters: {
        'category': AnalyticsCategory.edgeCase.value,
        'resolution': resolution.name,
      },
    ),
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

  FutureOr<void> onSubmit();

  Future<void> overwriteNewer() async {
    _isOverwriting = true;
    try {
      await onSubmit();
    } finally {
      _isOverwriting = false;
    }
  }
}

Future<void> resolveFormConflict(
  BuildContext context,
  ConflictResolvableForm? form, {
  required String? latestVersion,
  bool canKeepEditing = false,
}) async {
  if (form == null) return;
  await resolveConflict(
    context,
    onLoadLatest: form.loadLatest,
    onOverwrite: form.overwriteNewer,
    canKeepEditing: canKeepEditing,
    message: ConflictMessage.changedAt(AppLocalizations.of(context), latestVersion),
  );
}

@visibleForTesting
Future<ConflictResolution> confirmConflictResolution(
  BuildContext context, {
  bool canKeepEditing = false,
  required ConflictMessage message,
}) async {
  final result = await showDialog<ConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          message.title,
          style: AppStyles.pageTitle(dialogContext),
        ),
        content: SizedBox(
          width: Responsive.getDialogWidth(dialogContext),
          child: Text(
            message.body,
            style: AppStyles.standardBodyText(dialogContext),
          ),
        ),
        actions: [
          SizedBox(
            width: Responsive.getDialogWidth(dialogContext),
            child: _ConflictActions(
              canKeepEditing: canKeepEditing,
              message: message,
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
  final ConflictMessage message;

  const _ConflictActions({
    required this.canKeepEditing,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final discard = _ConflictButton(
      text: message.discardLabel,
      resolution: ConflictResolution.loadLatest,
      backgroundColor: context.colorScheme.outline,
    );
    final save = _ConflictButton(
      text: message.saveLabel,
      resolution: ConflictResolution.overwrite,
      backgroundColor:
          message.isSaveDestructive ? context.colorScheme.error : null,
    );
    if (!canKeepEditing) {
      return Row(
        spacing: 12,
        children: [Expanded(child: discard), Expanded(child: save)],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton(
                style: HeliumElevatedButton.outlinedStyle(context.colorScheme),
                onPressed: () =>
                    Navigator.of(context).pop(ConflictResolution.keepEditing),
                child: Text(AppLocalizations.of(context).commonKeepEditingButton),
              ),
            ),
            Expanded(child: discard),
          ],
        ),
        save,
      ],
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
