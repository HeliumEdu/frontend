import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class MobileGestureDetector extends StatelessWidget {
  final GestureTapCallback onTap;
  final Widget child;

  const MobileGestureDetector({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final opensOnTap = !Responsive.showItemActions(context);
    return MouseRegion(
      cursor: opensOnTap ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: opensOnTap
            ? () {
                Feedback.forTap(context);
                onTap();
              }
            : null,
        child: child,
      ),
    );
  }
}
