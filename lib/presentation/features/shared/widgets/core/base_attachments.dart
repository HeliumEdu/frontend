// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/attachment_file.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_state.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart'
    show SnackBarHelper, SnackType;
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:meta/meta.dart';

abstract class BaseAttachments extends StatelessWidget {
  final int entityId;
  final bool isEdit;
  final UserSettingsModel? userSettings;

  /// Optional key forwarded to the inner [BaseAttachmentsContent] so a parent
  /// can query the live [BaseAttachmentsState] (e.g. for `hasUnsavedFiles`).
  final GlobalKey<BaseAttachmentsState>? contentKey;

  const BaseAttachments({
    super.key,
    required this.entityId,
    required this.isEdit,
    this.userSettings,
    this.contentKey,
  });

  BaseAttachmentsContent buildContent();

  @override
  Widget build(BuildContext context) => buildContent();
}

abstract class BaseAttachmentsContent extends StatefulWidget {
  final int entityId;
  final bool isEdit;
  final UserSettingsModel? userSettings;

  const BaseAttachmentsContent({
    super.key,
    required this.entityId,
    required this.isEdit,
    this.userSettings,
  });

  @override
  BaseAttachmentsState createState();
}

abstract class BaseAttachmentsState extends State<BaseAttachmentsContent> {
  final int maxConcurrentUploads = 4;

  List<AttachmentFile> filesToUpload = [];
  List<AttachmentModel> attachments = [];
  Set<String> _failedFileTitles = {};
  bool isLoading = true;
  bool isSubmitting = false;
  bool _initialFetchComplete = false;

  @mustBeOverridden
  FetchAttachmentsEvent createFetchAttachmentsEvent({
    bool forceRefresh = false,
  });

  @mustBeOverridden
  CreateAttachmentEvent createCreateAttachmentsEvent();

  /// True when the user has staged files for upload but not yet uploaded.
  /// Used by multi-step parents to drive the unsaved-changes prompt.
  bool get hasUnsavedFiles => filesToUpload.isNotEmpty;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      context.read<AttachmentBloc>().add(createFetchAttachmentsEvent());
    } else {
      setState(() {
        isLoading = false;
        _initialFetchComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return BlocListener<AttachmentBloc, AttachmentState>(
      listener: (context, state) {
        if (state is AttachmentsError) {
          if (!_initialFetchComplete) {
            setState(() => isLoading = false);
          } else {
            setState(() => _failedFileTitles = state.failedFilenames);
            SnackBarHelper.show(context, state.message!, type: SnackType.error, seconds: 4);
          }
        } else if (state is AttachmentsFetched) {
          setState(() {
            attachments = state.attachments;
            Sort.byTitle(attachments);
            isLoading = false;
            _initialFetchComplete = true;
          });
        } else if (state is AttachmentsCreated) {
          SnackBarHelper.show(
            context,
            '${state.attachments.length} ${state.attachments.length.plural('attachment')} uploaded.',
          );

          final uploadedTitles = state.attachments.map((a) => a.title).toSet();
          setState(() {
            filesToUpload.removeWhere((f) => uploadedTitles.contains(f.title));
            attachments.addAll(state.attachments);
            Sort.byTitle(attachments);
          });
        } else if (state is AttachmentDeleted) {
          SnackBarHelper.show(context, 'Attachment deleted.');

          setState(() {
            attachments.removeWhere((a) => a.id == state.id);
          });
        }

        if (state is! AttachmentsLoading) {
          setState(() {
            isSubmitting = false;
          });
        }
      },
      // Bottom-pin the buttons clear of the home indicator: the enclosing
      // full-screen dialog does not reserve the bottom safe area, and these
      // buttons sit below the scroll, so they'd otherwise render under it.
      child: isLoading || widget.userSettings == null
          ? const Center(child: LoadingIndicator(expanded: false))
          : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attachments', style: AppStyles.featureText(context)),
                const SizedBox(height: 12),
                Expanded(
                  child: BlocBuilder<AttachmentBloc, AttachmentState>(
                    builder: (context, state) {
                      if (state is AttachmentsLoading) {
                        return const Center(
                          child: LoadingIndicator(expanded: false),
                        );
                      }

                      if (state is AttachmentsError && !_initialFetchComplete) {
                        return ErrorCard(
                          message: state.message!,
                          source: 'attachments_widget',
                          onReload: () {
                            context.read<AttachmentBloc>().add(
                              createFetchAttachmentsEvent(forceRefresh: true),
                            );
                          },
                          expanded: false,
                        );
                      }

                      if (attachments.isEmpty) {
                        return const EmptyCard(
                          icon: Icons.attachment_outlined,
                          message: 'Click "Choose Files" to add attachments',
                          expanded: false,
                        );
                      }

                      return _buildAttachmentsList();
                    },
                  ),
                ),
                HeliumElevatedButton(
                  onPressed: _openFileChooserDialog,
                  icon: Icons.cloud_upload_outlined,
                  buttonText: 'Choose Files',
                ),
                const SizedBox(height: 12),
                if (filesToUpload.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: _buildFilesToUploadList(),
                  ),
                const SizedBox(height: 12),
                HeliumElevatedButton(
                  buttonText: 'Upload',
                  isLoading: isSubmitting,
                  enabled: filesToUpload.isNotEmpty && !isSubmitting,
                  onPressed: _saveAttachments,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  Future<void> _openFileChooserDialog() async {
    // BasePageScreenState gates render on InfoLoaded, so this read is safe.
    final info = (context.read<InfoBloc>().state as InfoLoaded).info;
    final result = await HeliumStorage.pickFiles(
      maxUploadSize: info.maxUploadSize,
      allowMultiple: true,
    );

    if (!mounted) return;

    if (result.cancelled) {
      SnackBarHelper.show(
        context,
        'Nothing selected for upload.',
        type: SnackType.info,
      );
      return;
    }

    for (final error in result.errors) {
      if (mounted) {
        SnackBarHelper.show(context, error.userMessage, type: SnackType.error, seconds: 4);
      }
    }

    if (result.files.isEmpty) {
      if (result.errors.isEmpty && mounted) {
        SnackBarHelper.show(
          context,
          'Nothing selected for upload.',
          type: SnackType.info,
        );
      }
      return;
    }

    setState(() {
      filesToUpload = result.files
          .map((f) => AttachmentFile(bytes: f.bytes, title: f.name))
          .toList();
      _failedFileTitles = {};
    });
  }

  Future<void> _saveAttachments() async {
    if (filesToUpload.length > maxConcurrentUploads) {
      SnackBarHelper.show(
        context,
        "You can't upload more than $maxConcurrentUploads files at a time.",
        type: SnackType.error,
        seconds: 4
      );
      return;
    }

    setState(() {
      isSubmitting = true;
      _failedFileTitles = {};
    });

    context.read<AttachmentBloc>().add(createCreateAttachmentsEvent());
  }

  Widget _buildFilesToUploadList() {
    return ListView.builder(
      key: ValueKey(filesToUpload.length),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: filesToUpload.length,
      itemBuilder: (context, index) {
        final file = filesToUpload[index];
        return _buildFileToUploadCard(context, file, index);
      },
    );
  }

  Widget _buildFileToUploadCard(
    BuildContext context,
    AttachmentFile file,
    int index,
  ) {
    final hasFailed = _failedFileTitles.contains(file.title);
    return Card(
      key: ValueKey('file_upload_$index'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              hasFailed ? Icons.error_outline : Icons.insert_drive_file_outlined,
              color: hasFailed ? context.colorScheme.error : context.colorScheme.primary,
              size: Responsive.getIconSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    file.title,
                    style: AppStyles.standardBodyText(context),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Remove from upload',
              button: true,
              child: IconButton(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  if (index < filesToUpload.length) {
                    // Defer setState so any in-progress frame caused by the tap
                    // gesture completes before the list is mutated and rebuilt
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      setState(() {
                        filesToUpload.removeAt(index);
                      });
                    });
                  }
                },
                icon: Icon(
                  Icons.close,
                  color: context.colorScheme.error,
                  size: Responsive.getIconSize(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return ListView.builder(
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        return _buildAttachmentCard(context, attachments[index]);
      },
    );
  }

  Widget _buildAttachmentCard(
    BuildContext context,
    AttachmentModel attachment,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              color: context.colorScheme.primary,
              size: Responsive.getIconSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                attachment.title,
                style: AppStyles.standardBodyText(context),
                maxLines: 1,
              ),
            ),
            Semantics(
              label: 'Download',
              button: true,
              child: HeliumIconButton(
                onPressed: () => _downloadAttachment(attachment),
                icon: Icons.download_outlined,
                color: context.semanticColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Delete',
              button: true,
              child: HeliumIconButton(
                onPressed: () {
                  showConfirmDeleteDialog(
                    parentContext: context,
                    item: attachment,
                    onDelete: (a) {
                      context.read<AttachmentBloc>().add(
                        DeleteAttachmentEvent(
                          id: a.id,
                          courseId: a.course,
                          eventId: a.event,
                          homeworkId: a.homework,
                        ),
                      );
                    },
                  );
                },
                icon: Icons.delete_outline,
                color: context.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAttachment(AttachmentModel attachment) async {
    setState(() {
      isLoading = true;
    });

    final errorMessage = await HeliumStorage.downloadFile(
      attachment.attachment,
      attachment.title,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (errorMessage == null) {
      SnackBarHelper.show(context, '"${attachment.title}" downloaded.');
    } else {
      SnackBarHelper.show(context, errorMessage, type: SnackType.error);
    }
  }
}
