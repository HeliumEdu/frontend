import 'package:flutter/material.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Slides between top-level tabs along the navigation's axis: left and right
/// beside the bottom bar, up and down beside the rail.
///
/// Only the tab just left slides out, so a branch is never mounted twice. A tab
/// returned to while it is still sliding out is mounted a frame later, after
/// its old instance is gone, so it loads fresh like any other tab switch.
class ShellBranchTransition extends StatefulWidget {
  final int index;
  final Widget child;

  const ShellBranchTransition({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<ShellBranchTransition> createState() => _ShellBranchTransitionState();
}

class _ShellBranchTransitionState extends State<ShellBranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Widget? _outgoing;
  int? _outgoingIndex;
  bool _isForward = true;
  bool _isIncomingDeferred = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1)
      ..addStatusListener(_onStatusChanged);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(ShellBranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) return;

    final duration = MotionService().effectiveDuration(
      AppConstants.uiAnimationDuration,
    );
    if (duration == Duration.zero) {
      _outgoing = null;
      _outgoingIndex = null;
      return;
    }

    _isForward = widget.index > oldWidget.index;
    if (widget.index == _outgoingIndex) {
      _isIncomingDeferred = true;
      WidgetsBinding.instance.addPostFrameCallback(_mountDeferredIncoming);
    }
    _outgoing = oldWidget.child;
    _outgoingIndex = oldWidget.index;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mountDeferredIncoming(Duration _) {
    if (mounted) setState(() => _isIncomingDeferred = false);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null) {
      setState(() {
        _outgoing = null;
        _outgoingIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = Responsive.isMobile(context);
    final enterFrom = _isForward ? 1.0 : -1.0;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_outgoing != null)
            KeyedSubtree(
              key: ValueKey(_outgoingIndex),
              child: _slide(
                _outgoing!,
                from: Offset.zero,
                to: _axisOffset(-enterFrom, isHorizontal),
              ),
            ),
          if (!_isIncomingDeferred)
            KeyedSubtree(
              key: ValueKey(widget.index),
              child: _slide(
                widget.child,
                from: _axisOffset(enterFrom, isHorizontal),
                to: Offset.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _slide(Widget child, {required Offset from, required Offset to}) {
    return SlideTransition(
      position: Tween<Offset>(begin: from, end: to).animate(_progress),
      child: child,
    );
  }

  Offset _axisOffset(double value, bool isHorizontal) {
    return isHorizontal ? Offset(value, 0) : Offset(0, value);
  }
}
