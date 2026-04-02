// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/attachment_file.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/confirm_delete_dialog.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/multi_step_container.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/feedback/empty_card.dart';
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart' show SnackBarHelper, SnackType;
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('presentation.widgets');

abstract class BaseAttachments extends StatelessWidget {
  final ProviderHelpers _providerHelpers = ProviderHelpers();
  final int entityId;
  final bool isEdit;
  final UserSettingsModel? userSettings;

  BaseAttachments({
    super.key,
    required this.entityId,
    required this.isEdit,
    this.userSettings,
  });

  BaseAttachmentsContent buildContent();

  @override
  Widget build(BuildContext context) {
    AttachmentBloc? existingBloc;
    try {
      final found = context.read<AttachmentBloc>();
      existingBloc = found.isClosed ? null : found;
    } catch (_) {
      _log.info('AttachmentBloc not passed, will create a new one');
    }

    return MultiBlocProvider(
      providers: [
        existingBloc != null
            ? BlocProvider<AttachmentBloc>.value(value: existingBloc)
            : BlocProvider(create: _providerHelpers.createAttachmentBloc()),
      ],
      child: buildContent(),
    );
  }
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

abstract class BaseAttachmentsState<T extends BaseAttachmentsContent>
    extends State<T> {
  List<AttachmentFile> filesToUpload = [];
  List<AttachmentModel> attachments = [];
  bool isLoading = true;
  bool isSubmitting = false;

  @mustBeOverridden
  FetchAttachmentsEvent createFetchAttachmentsEvent({bool forceRefresh = false});

  @mustBeOverridden
  CreateAttachmentEvent createCreateAttachmentsEvent();

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      context.read<AttachmentBloc>().add(createFetchAttachmentsEvent());
    } else {
      setState(() {
        isLoading = false;
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
          SnackBarHelper.show(context, state.message!, type: SnackType.error);
        } else if (state is AttachmentsFetched) {
          setState(() {
            attachments = state.attachments;
            Sort.byTitle(attachments);
            isLoading = false;
          });
        } else if (state is AttachmentsCreated) {
          SnackBarHelper.show(
            context,
            '${state.attachments.length} ${state.attachments.length.plural('attachment')} uploaded',
          );

          final uploadedTitles =
              state.attachments.map((a) => a.title).toSet();
          setState(() {
            filesToUpload.removeWhere(
              (f) => uploadedTitles.contains(f.title),
            );
            attachments.addAll(state.attachments);
            Sort.byTitle(attachments);
          });
        } else if (state is AttachmentDeleted) {
          SnackBarHelper.show(context, 'Attachment deleted');

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
      child: isLoading || widget.userSettings == null
          ? const Center(child: LoadingIndicator(expanded: false))
          : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: AppStyles.featureText(context)),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<AttachmentBloc, AttachmentState>(
            builder: (context, state) {
              if (state is AttachmentsLoading) {
                return const Center(child: LoadingIndicator(expanded: false));
              }

              if (state is AttachmentsError) {
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
    );
  }

  Future<void> _openFileChooserDialog() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final newFiles = <AttachmentFile>[];

        for (var platFile in result.files) {
          if (platFile.bytes == null) {
            if (mounted) {
              SnackBarHelper.show(
                context,
                'An error occurred while reading the file: ${platFile.name}',
                type: SnackType.error,
              );
            }
            continue;
          }

          final fileSize = platFile.bytes!.length;

          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              SnackBarHelper.show(
                context,
                'File size cannot exceed 10mb limit',
                type: SnackType.error,
              );
            }
            continue;
          }

          newFiles.add(
            AttachmentFile(bytes: platFile.bytes!, title: platFile.name),
          );
        }

        if (newFiles.isEmpty && mounted) {
          SnackBarHelper.show(context, 'Nothing selected for upload');
        }

        setState(() {
          filesToUpload = newFiles;
        });
      } else if (mounted) {
        SnackBarHelper.show(context, 'Nothing selected for upload');
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.show(context, 'Error picking file: $e', type: SnackType.error);
    }
  }

  Future<void> _saveAttachments() async {
    if (filesToUpload.length > 4) {
      SnackBarHelper.show(
        context,
        'You can only upload a max of 4 files at a time',
        type: SnackType.error,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
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
    return Card(
      key: ValueKey('file_upload_$index'),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
            const SizedBox(width: 10),
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
            IconButton(
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
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                attachment.title,
                style: AppStyles.standardBodyText(context),
                maxLines: 1,
              ),
            ),
            HeliumIconButton(
              onPressed: () => _downloadAttachment(attachment),
              icon: Icons.download_outlined,
              color: context.semanticColors.success,
            ),
            const SizedBox(width: 8),
            HeliumIconButton(
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
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAttachment(AttachmentModel attachment) async {
    setState(() {
      isLoading = true;
    });

    final success = await HeliumStorage.downloadFile(
      attachment.attachment,
      attachment.title,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
    if (success) {
      SnackBarHelper.show(context, '"${attachment.title}" downloaded');
    } else {
      SnackBarHelper.show(
        context,
        'Failed to download "${attachment.title}"',
        type: SnackType.error,
      );
    }
  }
}
