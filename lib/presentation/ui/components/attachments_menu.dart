import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/hover_tap_target.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/attachment_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:heliumapp/utils/storage_helpers.dart';

/// Opens [groups] as a list of attachments to download, anchored to
/// [anchorContext] on larger screens or as a bottom sheet on phones.
Future<void> showAttachmentsMenu(
  BuildContext context, {
  required BuildContext anchorContext,
  required List<AttachmentGroup> groups,
}) {
  return showHeliumMenu(
    context: context,
    anchorContext: anchorContext,
    builder: (_, _) => AttachmentsMenuContent(groups: groups),
  );
}

/// Saves attachments to the device, reporting the outcome the same way
/// wherever a download starts.
class AttachmentDownloads {
  AttachmentDownloads._();

  /// Downloads [attachment] from a freshly fetched link, since the link it was
  /// listed with may have expired.
  static Future<void> download(
    BuildContext context,
    AttachmentModel attachment,
  ) async {
    final repository = context.read<AttachmentBloc>().attachmentRepository;
    final AttachmentModel? latest;
    try {
      latest = (await repository.getAttachments(
        courseId: attachment.course,
        eventId: attachment.event,
        homeworkId: attachment.homework,
        resourceId: attachment.resource,
        forceRefresh: true,
      )).firstWhereOrNull((a) => a.id == attachment.id);
    } on HeliumException catch (e) {
      if (context.mounted) {
        SnackBarHelper.show(context, e.message, type: SnackType.error);
      }
      return;
    }
    if (!context.mounted) return;
    if (latest == null) {
      SnackBarHelper.show(
        context,
        '"${attachment.title}" was deleted.',
        type: SnackType.error,
      );
      return;
    }

    final result = await HeliumStorage.downloadFile(
      latest.attachment,
      latest.title,
    );
    if (!context.mounted || result.cancelled) return;

    if (result.saved) {
      SnackBarHelper.show(context, '"${latest.title}" downloaded.');
    } else {
      SnackBarHelper.show(
        context,
        result.errorMessage!,
        type: SnackType.error,
      );
    }
  }
}

@visibleForTesting
class AttachmentsMenuContent extends StatefulWidget {
  final List<AttachmentGroup> groups;

  const AttachmentsMenuContent({super.key, required this.groups});

  @override
  State<AttachmentsMenuContent> createState() => _AttachmentsMenuContentState();
}

class _AttachmentsMenuContentState extends State<AttachmentsMenuContent> {
  final Set<int> _downloading = {};

  Future<void> _download(AttachmentModel attachment) async {
    setState(() => _downloading.add(attachment.id));
    await AttachmentDownloads.download(context, attachment);
    if (!mounted) return;
    setState(() => _downloading.remove(attachment.id));
  }

  @override
  Widget build(BuildContext context) {
    return HeliumMenuContent(
      width: HeliumMenuContent.listWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeliumMenuTitle(title: 'Attachments'),
          if (widget.groups.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'No attachments',
              style: AppStyles.standardBodyTextLight(context),
            ),
          ],
          for (final group in widget.groups) ...[
            if (group.title case final title?)
              HeliumMenuSectionHeader(title: title.toUpperCase())
            else
              const SizedBox(height: 8),
            for (final attachment in group.attachments)
              _buildAttachmentRow(context, attachment),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(BuildContext context, AttachmentModel attachment) {
    return HeliumMenuItemRow(
      icon: Icons.insert_drive_file_outlined,
      title: attachment.title,
      action: HeliumIconButton(
        onPressed: () => _download(attachment),
        enabled: !_downloading.contains(attachment.id),
        icon: Icons.download_outlined,
        semanticLabel: 'Download',
        color: context.semanticColors.success,
      ),
    );
  }
}

/// A paperclip and attachment count that opens the attachments, passing its own
/// context as the menu's anchor. Takes the tap, so a tappable card around it
/// doesn't open.
class AttachmentCountButton extends StatelessWidget {
  static const hitPadding = EdgeInsets.fromLTRB(8, 6, 0, 6);

  final int count;
  final void Function(BuildContext anchorContext) onPressed;

  const AttachmentCountButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.semanticColors.success.withValues(alpha: 0.9);
    return HoverTapTarget(
      onTap: onPressed,
      color: color,
      tooltip: 'Show attachments',
      hitPadding: hitPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attachment,
            size: Responsive.getIconSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 16,
            ),
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppStyles.smallSecondaryText(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
