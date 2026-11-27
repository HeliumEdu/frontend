import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum RecurrenceScope { thisOccurrence, all }

enum RecurrenceScopeAction { edit, move, delete }

/// Resolves null when the user cancels.
Future<RecurrenceScope?> showRecurrenceScopeDialog({
  required BuildContext context,
  required RecurrenceScopeAction action,
  required bool isEvent,
  String? thisDetail,
  String? allDetail,
}) {
  return showDialog<RecurrenceScope>(
    context: context,
    builder: (dialogContext) => _RecurrenceScopeDialog(
      action: action,
      isEvent: isEvent,
      thisDetail: thisDetail,
      allDetail: allDetail,
    ),
  );
}

class _RecurrenceScopeDialog extends StatefulWidget {
  final RecurrenceScopeAction action;
  final bool isEvent;
  final String? thisDetail;
  final String? allDetail;

  const _RecurrenceScopeDialog({
    required this.action,
    required this.isEvent,
    this.thisDetail,
    this.allDetail,
  });

  @override
  State<_RecurrenceScopeDialog> createState() => _RecurrenceScopeDialogState();
}

class _RecurrenceScopeDialogState extends State<_RecurrenceScopeDialog> {
  RecurrenceScope _scope = RecurrenceScope.thisOccurrence;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title, style: AppStyles.pageTitle(context)),
      content: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: RadioGroup<RecurrenceScope>(
          groupValue: _scope,
          onChanged: _onScopeChanged,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(context, RecurrenceScope.thisOccurrence, AppLocalizations.of(context).recurrenceScopeThisOption, widget.thisDetail),
              _buildOption(context, RecurrenceScope.all, AppLocalizations.of(context).recurrenceScopeAllOption, widget.allDetail),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: Responsive.getDialogWidth(context),
          child: Row(
            children: [
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: AppLocalizations.of(context).commonCancelButton,
                  backgroundColor: context.colorScheme.outline,
                  onPressed: _cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeliumElevatedButton(
                  buttonText: switch (widget.action) {
                    RecurrenceScopeAction.edit => AppLocalizations.of(context).recurrenceScopeSaveButton,
                    RecurrenceScopeAction.move => AppLocalizations.of(context).recurrenceScopeMoveButton,
                    RecurrenceScopeAction.delete => AppLocalizations.of(context).commonDeleteButton,
                  },
                  backgroundColor: widget.action == RecurrenceScopeAction.delete
                      ? context.colorScheme.error
                      : null,
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _title {
    final l10n = AppLocalizations.of(context);
    if (widget.isEvent) {
      return switch (widget.action) {
        RecurrenceScopeAction.edit => l10n.recurrenceScopeEditEventTitle,
        RecurrenceScopeAction.move => l10n.recurrenceScopeMoveEventTitle,
        RecurrenceScopeAction.delete => l10n.recurrenceScopeDeleteEventTitle,
      };
    }
    return switch (widget.action) {
      RecurrenceScopeAction.edit => l10n.recurrenceScopeEditAssignmentTitle,
      RecurrenceScopeAction.move => l10n.recurrenceScopeMoveAssignmentTitle,
      RecurrenceScopeAction.delete => l10n.recurrenceScopeDeleteAssignmentTitle,
    };
  }

  Widget _buildOption(BuildContext context, RecurrenceScope scope, String label, String? detail) {
    return RadioListTile<RecurrenceScope>(
      value: scope,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppStyles.formLabel(context)),
      subtitle: detail == null
          ? null
          : Text(detail, style: AppStyles.standardBodyTextLight(context)),
    );
  }

  void _onScopeChanged(RecurrenceScope? scope) {
    if (scope == null) return;
    setState(() => _scope = scope);
  }

  void _cancel() => Navigator.of(context).pop();

  void _confirm() => Navigator.of(context).pop(_scope);
}
