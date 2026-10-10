import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/utils/platform_support_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/platform_support_web.dart'
    as support;
import 'package:heliumapp/utils/responsive_helpers.dart';

/// How the app behaves for the current input and host operating system.
///
/// Every behavior derives from two primitives: whether the device has touch
/// input, and the operating system the user is actually on. Feature code asks
/// for a named behavior here rather than checking `kIsWeb`, touch, or the
/// platform itself, so a new build target only has to report its primitives.
///
/// SDK and plumbing differences (sign-in SDKs, push, downloads, browser-only
/// APIs, store policy) stay on `kIsWeb` / `Platform` checks; only user-facing
/// behavior belongs here.
///
/// The two are independent: a Chromebook or touchscreen laptop is a desktop
/// host with touch input, so it gets touch interactions alongside desktop
/// capabilities such as printing and scrollbars.
///
/// | Runtime                   | Touch input       | Host platform |
/// |---------------------------|-------------------|---------------|
/// | Web                       | browser reports   | browser's OS  |
/// | Native iOS / Android      | yes               | iOS / Android |
/// | Native iPad build on Mac  | no                | macOS         |
/// | Native desktop            | no                | its own OS    |
class PlatformBehavior {
  PlatformBehavior._();

  /// Resolves the primitives that need a native lookup; call once at startup.
  static Future<void> initialize() => support.initialize();

  static TargetPlatform get hostPlatform => support.hostPlatform;

  static bool get isDesktopHost => switch (hostPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    TargetPlatform.iOS ||
    TargetPlatform.android ||
    TargetPlatform.fuchsia => false,
  };

  static bool get reservesStatusBarSpace => !isDesktopHost;

  static bool get usesTouchInteractions => support.hasTouchInput;

  /// Whether hit targets are sized for a finger rather than a pointer.
  static bool get usesTouchTargets => support.hasTouchInput;

  /// Whether an item carries its own action buttons rather than opening when
  /// the item itself is tapped. A finger gets the tap experience at any size;
  /// a pointer needs the room for buttons.
  static bool showItemActions(BuildContext context) =>
      !support.hasTouchInput && !Responsive.isMobile(context);

  static bool get showsHoverTooltips => !support.hasTouchInput;

  /// Touch users opt in to calendar drag and drop, since a drag competes with
  /// scrolling.
  static bool get allowsDragAndDropByDefault => !support.hasTouchInput;

  static TimePickerEntryMode get timePickerEntryMode => support.hasTouchInput
      ? TimePickerEntryMode.dial
      : TimePickerEntryMode.input;

  static bool get dismissesDialogOnBarrierTap => !support.hasTouchInput;

  /// Focusing a field on open raises the on-screen keyboard on native touch
  /// devices, covering the form before the user has chosen to type.
  static bool get autofocusesOnOpen => kIsWeb || !support.hasTouchInput;

  /// Printing is triggered by the Cmd+P / Ctrl+P shortcut.
  static bool get supportsPrintShortcut => kIsWeb || isDesktopHost;

  /// Links to the native apps, offered to pointer users of the web build.
  static bool get showsAppStoreLinks => kIsWeb && !support.hasTouchInput;
}

/// Scrollbars and scroll physics follow the host platform, so an iPad build on
/// a Mac scrolls like a desktop app.
class HeliumScrollBehavior extends MaterialScrollBehavior {
  const HeliumScrollBehavior();

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      PlatformBehavior.hostPlatform;
}
