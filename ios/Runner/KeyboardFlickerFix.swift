import Foundation
import UIKit

/// Works around flutter/flutter#180842: moving focus between text fields
/// dismisses the keyboard and immediately reopens it. Fixed upstream in Flutter
/// 3.44 — delete this file, and its call in AppDelegate, with that upgrade.
///
/// Swizzles `FlutterTextInputPlugin`, so it depends on private engine
/// internals. Every lookup is gated on `responds(to:)` first: if a future
/// engine renames one, the flicker returns rather than the app crashing.
enum KeyboardFlickerFix {
  private typealias VoidMethod = @convention(c) (AnyObject, Selector) -> Void
  private typealias SetClientMethod = @convention(c) (
    AnyObject, Selector, Int32, NSDictionary
  ) -> Void

  private static let clearSelector = NSSelectorFromString("clearTextInputClient")
  private static let hideSelector = NSSelectorFromString("hideTextInput")
  private static let setClientSelector = NSSelectorFromString(
    "setTextInputClient:withConfiguration:"
  )

  private static var originalClear: IMP?
  private static var originalHide: IMP?
  private static var originalSetClient: IMP?
  private static var pendingRemovalKey: UInt8 = 0

  static func install() {
    guard let plugin = NSClassFromString("FlutterTextInputPlugin") else { return }

    if let method = class_getInstanceMethod(plugin, clearSelector) {
      let block: @convention(block) (AnyObject) -> Void = { instance in
        onClearTextInputClient(instance)
      }
      originalClear = method_setImplementation(method, imp_implementationWithBlock(block))
    }

    if let method = class_getInstanceMethod(plugin, hideSelector) {
      let block: @convention(block) (AnyObject) -> Void = { instance in
        onHideTextInput(instance)
      }
      originalHide = method_setImplementation(method, imp_implementationWithBlock(block))
    }

    if let method = class_getInstanceMethod(plugin, setClientSelector) {
      let block: @convention(block) (AnyObject, Int32, NSDictionary) -> Void = {
        instance, client, configuration in
        setPendingRemoval(instance, false)
        if let original = originalSetClient {
          unsafeBitCast(original, to: SetClientMethod.self)(
            instance, setClientSelector, client, configuration
          )
        }
      }
      originalSetClient = method_setImplementation(method, imp_implementationWithBlock(block))
    }
  }

  /// Keeps the active view first responder when nothing else wants the
  /// keyboard, which is what stops the dismiss/reopen cycle. Autofill sessions
  /// still take the original path — they rely on the client being cleared.
  private static func onClearTextInputClient(_ instance: AnyObject) {
    let autofillContext = value(instance, "autofillContext") as? NSDictionary
    let activeView = value(instance, "activeView") as? UIView

    guard autofillContext?.count == 0, activeView?.isFirstResponder == true else {
      callOriginal(originalClear, instance, clearSelector)
      setPendingRemoval(instance, false)
      return
    }

    let timerSelector = NSSelectorFromString(
      "removeEnableFlutterTextInputViewAccessibilityTimer"
    )
    if instance.responds(to: timerSelector) {
      _ = instance.perform(timerSelector)
    }
    if let activeView, canRead(activeView, "accessibilityEnabled") {
      activeView.setValue(false, forKey: "accessibilityEnabled")
    }
    setPendingRemoval(instance, true)
  }

  /// Deferred teardown for the views [onClearTextInputClient] left in place.
  private static func onHideTextInput(_ instance: AnyObject) {
    callOriginal(originalHide, instance, hideSelector)

    guard
      (objc_getAssociatedObject(instance, &pendingRemovalKey) as? NSNumber)?.boolValue == true
    else {
      return
    }

    (value(instance, "activeView") as? UIView)?.removeFromSuperview()
    (value(instance, "inputHider") as? UIView)?.removeFromSuperview()
    setPendingRemoval(instance, false)
  }

  /// Mirrors how KVC resolves a key — accessor first, then ivar — so the fix
  /// is skipped only when the engine genuinely no longer exposes it.
  private static func canRead(_ instance: AnyObject, _ key: String) -> Bool {
    if instance.responds(to: NSSelectorFromString(key)) { return true }
    let cls: AnyClass = type(of: instance)
    return class_getInstanceVariable(cls, key) != nil
      || class_getInstanceVariable(cls, "_" + key) != nil
  }

  private static func value(_ instance: AnyObject, _ key: String) -> Any? {
    guard canRead(instance, key) else { return nil }
    return instance.value(forKey: key)
  }

  private static func callOriginal(_ imp: IMP?, _ instance: AnyObject, _ selector: Selector) {
    guard let imp else { return }
    unsafeBitCast(imp, to: VoidMethod.self)(instance, selector)
  }

  private static func setPendingRemoval(_ instance: AnyObject, _ pending: Bool) {
    objc_setAssociatedObject(
      instance, &pendingRemovalKey, NSNumber(value: pending), .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }
}
