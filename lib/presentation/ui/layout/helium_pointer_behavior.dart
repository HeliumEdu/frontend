import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

/// How a pointer behaves across the whole app: where
/// [PlatformBehavior.unfocusesOnBackgroundTap], a tap outside a field
/// dismisses the keyboard; elsewhere the field keeps focus, as in a desktop app,
/// which also overrides Flutter's rule that a mouse click outside a text field
/// drops its focus on iOS builds.
///
/// In the iPad build on a Mac, a palm brushing the trackpad mid-typing arrives
/// as a tap-to-click at the resting pointer: a trackpad contact, then a click a
/// few milliseconds later. A pointer that goes down right after a trackpad
/// contact starts, while typing, is ignored so the caret stays put.
class HeliumPointerBehavior extends StatefulWidget {
  final Widget? child;

  const HeliumPointerBehavior({super.key, this.child});

  @override
  State<HeliumPointerBehavior> createState() => _HeliumPointerBehaviorState();
}

class _HeliumPointerBehaviorState extends State<HeliumPointerBehavior> {
  static const _typingWindow = Duration(seconds: 1);
  static const _tapToClickWindow = Duration(milliseconds: 50);

  final Stopwatch _clock = Stopwatch()..start();
  Duration? _lastKeyDown;
  Duration? _lastTrackpadContact;

  @override
  void initState() {
    super.initState();
    if (PlatformBehavior.rejectsTrackpadTapsWhileTyping) {
      HardwareKeyboard.instance.addHandler(_onKey);
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    }
  }

  @override
  void dispose() {
    if (PlatformBehavior.rejectsTrackpadTapsWhileTyping) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    }
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event.logicalKey.synonyms.isNotEmpty) return false;
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _lastKeyDown = _clock.elapsed;
    }
    return false;
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerPanZoomStartEvent) {
      _lastTrackpadContact = _clock.elapsed;
    }
  }

  bool _within(Duration? since, Duration window) =>
      since != null && _clock.elapsed - since <= window;

  bool _rejecting() =>
      _within(_lastKeyDown, _typingWindow) &&
      _within(_lastTrackpadContact, _tapToClickWindow);

  @override
  Widget build(BuildContext context) {
    return _HitTestGate(
      rejecting: _rejecting,
      child: PlatformBehavior.unfocusesOnBackgroundTap
          ? GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: widget.child,
            )
          : Actions(
              actions: _keepFocusOnTapOutside,
              child: widget.child!,
            ),
    );
  }
}

final _keepFocusOnTapOutside = <Type, Action<Intent>>{
  EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
    onInvoke: (_) => null,
  ),
};

class _HitTestGate extends SingleChildRenderObjectWidget {
  final bool Function() rejecting;

  const _HitTestGate({required this.rejecting, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTestGate(rejecting);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHitTestGate renderObject,
  ) {
    renderObject.rejecting = rejecting;
  }
}

class _RenderHitTestGate extends RenderProxyBox {
  bool Function() rejecting;

  _RenderHitTestGate(this.rejecting);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (rejecting()) return false;
    return super.hitTest(result, position: position);
  }
}
