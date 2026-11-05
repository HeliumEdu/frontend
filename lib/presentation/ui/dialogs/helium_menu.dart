import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/dialogs/helium_bottom_sheet.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Opens [builder]'s content as a bottom sheet on phones, or as a menu anchored
/// below [anchorContext] otherwise.
Future<void> showHeliumMenu({
  required BuildContext context,
  required BuildContext anchorContext,
  required StatefulWidgetBuilder builder,
}) async {
  if (Responsive.isMobile(context)) {
    await showHeliumBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(builder: builder),
    );
    return;
  }

  final RenderBox anchor = anchorContext.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()
          as RenderBox;
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      anchor.localToGlobal(Offset.zero, ancestor: overlay),
      anchor.localToGlobal(
        anchor.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );

  await showMenu(
    context: context,
    position: position,
    color: context.colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    // Open on the root navigator so the popup's tap-outside barrier covers the
    // page chrome (header, nav rail): tapping anywhere dismisses the menu.
    useRootNavigator: true,
    items: [
      PopupMenuItem(
        enabled: false,
        padding: EdgeInsets.zero,
        child: StatefulBuilder(builder: builder),
      ),
    ],
  );
}

/// The scrolling, height-capped frame a menu's content sits in. [width] fixes
/// an anchored menu's width; on phones the bottom sheet spans the screen.
class HeliumMenuContent extends StatelessWidget {
  static const listWidth = 280.0;

  final Widget child;
  final double? width;

  const HeliumMenuContent({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final frame = _buildFrame(context);
    final width = this.width;
    if (width == null || Responsive.isMobile(context)) return frame;
    return SizedBox(width: width, child: frame);
  }

  Widget _buildFrame(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              AppConstants.bottomSheetMaxHeightFactor,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: Responsive.sheetContentPadding(context),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A heading between groups of a menu's options.
class HeliumMenuSectionHeader extends StatelessWidget {
  final String title;

  const HeliumMenuSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(title, style: AppStyles.smallSecondaryTextLight(context)),
    );
  }
}

/// A menu's title, above its options.
class HeliumMenuTitle extends StatelessWidget {
  final String title;

  const HeliumMenuTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppStyles.headingText(context));
  }
}

/// One item in a menu that lists items by name, with an optional [action]
/// button after it: an icon and title, or, for items the app shows as a label
/// (like resources), that label.
class HeliumMenuItemRow extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final Widget? label;
  final Widget? action;

  const HeliumMenuItemRow({
    super.key,
    required IconData this.icon,
    required String this.title,
    this.action,
  }) : label = null;

  const HeliumMenuItemRow.label({
    super.key,
    required Widget this.label,
    this.action,
  }) : icon = null,
       title = null;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ..._buildItem(context),
          if (action != null) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }

  List<Widget> _buildItem(BuildContext context) {
    if (label case final label?) {
      return [Expanded(child: Align(alignment: Alignment.centerLeft, child: label))];
    }
    return [
      Icon(icon, color: context.colorScheme.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title!,
          style: AppStyles.standardBodyText(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }
}
