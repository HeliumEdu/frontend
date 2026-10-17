import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/presentation/ui/feedback/discard_changes_scope.dart';
import 'package:heliumapp/presentation/ui/feedback/error_container.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseDialogState<T extends StatefulWidget> extends State<T> {
  static const _dialogBorderRadius = 12.0;

  @mustBeOverridden
  String get dialogTitle;

  @mustBeOverridden
  BasicFormController get formController;

  bool isSubmitting = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final listeners = buildListeners(context);
    final dialog = listeners.isNotEmpty
        ? MultiBlocListener(listeners: listeners, child: buildDialog(context))
        : buildDialog(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: dialog,
    );
  }

  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [];
  }

  Widget buildDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.isMobile(context)
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: Responsive.getDialogWidth(context),
        child: Material(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(_dialogBorderRadius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildDialogHeader(),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: AppConstants.dialogContentPadding,
                  child: Form(
                    key: formController.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          _buildLoadingArea(context)
                        else
                          buildMainArea(context),

                        ?buildSecondaryActions(),

                        if (errorMessage != null) buildErrorArea(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDialogHeader() {
    return PageHeader(
      title: dialogTitle,
      screenType: ScreenType.entityPage,
      isDialog: true,
      isLoading: isSubmitting,
      cancelAction: handleClose,
      saveAction: _onSavePressed,
      additionalLeftButtons: additionalHeaderButtons,
      additionalRightButtons: additionalRightHeaderButtons,
    );
  }

  @mustBeOverridden
  Widget buildMainArea(BuildContext context);

  /// Lays the form out unseen beneath the spinner so the dialog opens at its
  /// final size; the form remounts, and autofocuses, once loading ends.
  Widget _buildLoadingArea(BuildContext context) {
    return Stack(
      children: [
        ExcludeFocus(
          child: Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: buildMainArea(context),
          ),
        ),
        const Positioned.fill(
          child: Center(child: LoadingIndicator(expanded: false)),
        ),
      ],
    );
  }

  Widget buildErrorArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ErrorContainer(
        text: errorMessage!,
        onDismiss: () {
          setState(() {
            errorMessage = null;
          });
        },
      ),
    );
  }

  /// Closes without saving or asking.
  void cancelAction() => Navigator.pop(context);

  /// The user's close (header close, back, Escape): asks before discarding
  /// edits they made.
  Future<void> handleClose() async {
    if (formController.isUserDirty && !await confirmDiscardChanges(context)) {
      return;
    }
    if (mounted) cancelAction();
  }

  List<Widget> get additionalHeaderButtons => const [];

  List<Widget> get additionalRightHeaderButtons => const [];

  /// Actions shown beneath the form that stay visible while it loads.
  Widget? buildSecondaryActions() => null;

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop || isSubmitting) return;
    handleClose();
  }

  void _onSavePressed() {
    if (!isLoading) handleSubmit();
  }

  @mustBeOverridden
  @mustCallSuper
  void handleSubmit() {
    if (formController.formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        isSubmitting = true;
      });
    }
  }
}
