import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';
import 'package:heliumapp/presentation/ui/components/resource_title_label.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_menu.dart';
import 'package:heliumapp/utils/url_helpers.dart';

/// Opens [resources] as a list with each one's website, anchored to
/// [anchorContext] on larger screens or as a bottom sheet on phones.
Future<void> showResourcesMenu(
  BuildContext context, {
  required BuildContext anchorContext,
  required List<ResourceModel> resources,
  required UserSettingsModel userSettings,
}) {
  return showHeliumMenu(
    context: context,
    anchorContext: anchorContext,
    builder: (_, _) =>
        ResourcesMenuContent(resources: resources, userSettings: userSettings),
  );
}

@visibleForTesting
class ResourcesMenuContent extends StatelessWidget {
  final List<ResourceModel> resources;
  final UserSettingsModel userSettings;

  const ResourcesMenuContent({
    super.key,
    required this.resources,
    required this.userSettings,
  });

  @override
  Widget build(BuildContext context) {
    return HeliumMenuContent(
      width: HeliumMenuContent.listWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeliumMenuTitle(title: 'Resources'),
          const SizedBox(height: 8),
          for (final resource in resources) _buildResourceRow(context, resource),
        ],
      ),
    );
  }

  Widget _buildResourceRow(BuildContext context, ResourceModel resource) {
    final website = resource.website;
    return HeliumMenuItemRow.label(
      label: ResourceTitleLabel(
        title: resource.title,
        userSettings: userSettings,
      ),
      action: website == null
          ? null
          : HeliumIconButton(
              onPressed: () => UrlHelpers.launchWebUrl(website.toString()),
              icon: Icons.launch_outlined,
              tooltip: "Launch resource's website",
              color: context.semanticColors.success,
            ),
    );
  }
}
