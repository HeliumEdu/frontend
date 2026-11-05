import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/shared/widgets/core/base_attachments.dart';

class ResourceAttachments extends BaseAttachments {
  const ResourceAttachments({
    super.key,
    required super.entityId,
    required super.isEdit,
    required super.userSettings,
    super.contentKey,
    super.onUploadsSettled,
  });

  @override
  BaseAttachmentsContent buildContent() {
    return _ResourceAttachmentsContent(
      key: contentKey,
      entityId: entityId,
      isEdit: isEdit,
      userSettings: userSettings,
      onUploadsSettled: onUploadsSettled,
    );
  }
}

class _ResourceAttachmentsContent extends BaseAttachmentsContent {
  const _ResourceAttachmentsContent({
    super.key,
    required super.entityId,
    required super.isEdit,
    required super.userSettings,
    super.onUploadsSettled,
  });

  @override
  BaseAttachmentsState createState() => _ResourceAttachmentsWidgetState();
}

class _ResourceAttachmentsWidgetState extends BaseAttachmentsState {
  @override
  FetchAttachmentsEvent createFetchAttachmentsEvent({bool forceRefresh = false}) {
    return FetchAttachmentsEvent(resourceId: widget.entityId, forceRefresh: forceRefresh);
  }

  @override
  CreateAttachmentEvent createCreateAttachmentsEvent() {
    return CreateAttachmentEvent(
      files: filesToUpload,
      resourceId: widget.entityId,
    );
  }
}
