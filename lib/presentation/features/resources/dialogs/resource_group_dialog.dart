import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/request/resource_group_request_model.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_state.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';
import 'package:heliumapp/presentation/ui/dialogs/base_dialog_state.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/features/resources/controllers/resource_group_form_controller.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

class _ResourceGroupProvidedWidget extends StatefulWidget {
  final bool isEdit;
  final ResourceGroupModel? group;

  const _ResourceGroupProvidedWidget({required this.isEdit, this.group});

  @override
  State<_ResourceGroupProvidedWidget> createState() =>
      _ResourceGroupWidgetState();
}

class _ResourceGroupWidgetState
    extends BaseDialogState<_ResourceGroupProvidedWidget> {
  final ResourceGroupFormController _formController =
      ResourceGroupFormController();
  String? _version;

  /// Set when the user picks Overwrite, so the next save is unconditional.
  bool _overwriteNewer = false;

  @override
  String get dialogTitle => 'Group';

  @override
  BasicFormController get formController => _formController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _populateInitialStateData(widget.group!);
      isLoading = true;
      context.read<ResourceBloc>().add(
        FetchResourcesScreenDataEvent(
          origin: EventOrigin.dialog,
          forceRefresh: true,
          passive: true,
        ),
      );
    } else {
      _formController.markChanged();
      _formController.titleController.clear();
      _formController.shownOnCalendar = true;
    }
  }

  void _populateInitialStateData(ResourceGroupModel group) {
    _formController.titleController.text = group.title;
    _formController.shownOnCalendar = group.shownOnCalendar!;
    _version = group.version;
  }

  Future<void> _resolveConflict(ResourceGroupModel latest) async {
    final resolution = await confirmConflictResolution(context);
    if (!mounted) return;
    switch (resolution) {
      case ConflictResolution.loadLatest:
        setState(() {
          _populateInitialStateData(latest);
          _formController.isChanged = false;
          _formController.isUserDirty = false;
        });
      case ConflictResolution.overwrite:
        _overwriteNewer = true;
        handleSubmit();
    }
  }

  @override
  void dispose() {
    _formController.dispose();

    super.dispose();
  }

  @override
  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [
      BlocListener<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourcesError) {
            setState(() {
              errorMessage = state.message;
              isLoading = false;
            });
          } else if (state is ResourcesScreenDataFetched &&
              state.origin == EventOrigin.dialog &&
              isLoading) {
            final group = state.resourceGroups
                .firstWhereOrNull((g) => g.id == widget.group!.id);
            setState(() {
              if (group == null) errorMessage = 'Group not found.';
              _populateInitialStateData(group ?? widget.group!);
              isLoading = false;
            });
          } else if (state is ResourceGroupConflict) {
            _resolveConflict(state.latest);
          } else if (state is ResourceGroupCreated ||
              state is ResourceGroupUpdated ||
              state is ResourceGroupDeleted) {
            Navigator.pop(context);
          }

          if (state is! ResourcesLoading) {
            setState(() {
              isSubmitting = false;
            });
          }
        },
      ),
    ];
  }

  @override
  Widget? buildLeadingAction() {
    if (!widget.isEdit) return null;
    return Semantics(
      label: 'Delete',
      button: true,
      child: HeliumIconButton(
        enabled: !isSubmitting,
        onPressed: () {
          showConfirmDeleteDialog(
            parentContext: context,
            item: widget.group!,
            label: widget.group!.title,
            additionalWarning:
                'Anything in this group, including resources, will also be deleted.',
            onDelete: (value) {
              setState(() => isSubmitting = true);
              context.read<ResourceBloc>().add(
                DeleteResourceGroupEvent(
                  origin: EventOrigin.dialog,
                  resourceGroupId: value.id,
                ),
              );
            },
          );
        },
        icon: Icons.delete_outlined,
        color: context.colorScheme.error,
        minimumSize: actionButtonSize,
      ),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelAndTextFormField(
          label: 'Title',
          autofocus: PlatformBehavior.autofocusesOnOpen || !widget.isEdit,
          controller: _formController.titleController,
          validator: BasicFormController.validateRequiredField,
          onChanged: (_) => _formController.markChanged(),
          onFieldSubmitted: (value) => handleSubmit(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: HeliumCheckboxListTile(
                title: Text(
                  "Hide this group's resources from the Planner",
                  style: AppStyles.formLabel(context),
                ),
                value: !_formController.shownOnCalendar,
                onChanged: (value) {
                  _formController.markChanged();
                  setState(() {
                    _formController.shownOnCalendar = !value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void handleSubmit() {
    if (!_formController.isChanged) {
      cancelAction();
      return;
    }
    super.handleSubmit();

    if (_formController.formKey.currentState!.validate()) {
      final request = ResourceGroupRequestModel(
        title: _formController.titleController.text.trim(),
        shownOnCalendar: _formController.shownOnCalendar,
      );

      if (widget.isEdit) {
        context.read<ResourceBloc>().add(
          UpdateResourceGroupEvent(
            origin: EventOrigin.dialog,
            resourceGroupId: widget.group!.id,
            request: request,
            version: _overwriteNewer ? null : _version,
          ),
        );
        _overwriteNewer = false;
      } else {
        context.read<ResourceBloc>().add(
          CreateResourceGroupEvent(
            origin: EventOrigin.dialog,
            request: request,
          ),
        );
      }
    }
  }
}

Future<void> showResourceGroupDialog<T extends BaseModel>({
  required BuildContext parentContext,
  required bool isEdit,
  ResourceGroupModel? group,
}) {
  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) =>
        _ResourceGroupProvidedWidget(isEdit: isEdit, group: group),
  );
}
