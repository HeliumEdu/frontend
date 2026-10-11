import 'package:flutter/widgets.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';

mixin ConflictResolvingDialog<W extends StatefulWidget, T extends BaseModel>
    on BaseDialogState<W> {
  String? _version;
  T? _conflictLatest;
  bool _isOverwriting = false;

  String? get versionToSend => _isOverwriting ? null : _version;

  void trackVersion(T item) => _version = item.version;

  void applyLatest(T latest);

  void resolveDialogConflict(T latest) {
    _conflictLatest = latest;
    resolveConflict(
      context,
      onLoadLatest: _loadLatest,
      onOverwrite: _overwrite,
    );
  }

  void _loadLatest() => setState(() => applyLatest(_conflictLatest!));

  void _overwrite() {
    _isOverwriting = true;
    handleSubmit();
    _isOverwriting = false;
  }
}
