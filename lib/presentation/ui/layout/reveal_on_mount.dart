import 'package:flutter/material.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/utils/app_globals.dart';

/// Scrolls [child] into view when it first appears, such as an error or result
/// shown at the bottom of a scrolling form. Key it by what it shows, so a new
/// message mounts it again and is revealed too.
class RevealOnMount extends StatefulWidget {
  final Widget child;

  const RevealOnMount({super.key, required this.child});

  /// Uses the app's motion setting; a zero duration jumps.
  static Future<void> ensureVisible(
    BuildContext context, {
    double alignment = 0.0,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
  }) {
    return Scrollable.ensureVisible(
      context,
      duration: MotionService().effectiveDuration(AppConstants.uiAnimationDuration),
      curve: Curves.easeInOut,
      alignment: alignment,
      alignmentPolicy: alignmentPolicy,
    );
  }

  @override
  State<RevealOnMount> createState() => _RevealOnMountState();
}

class _RevealOnMountState extends State<RevealOnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_reveal);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _reveal(Duration _) {
    if (!mounted) return;
    RevealOnMount.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }
}
