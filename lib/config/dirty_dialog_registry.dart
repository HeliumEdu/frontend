// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/ui/feedback/discard_changes_scope.dart';

/// Tracks the currently-mounted path-based dialog and whether its content has
/// unsaved changes so the router can intercept URL-driven dismissals
/// (browser back, address-bar edits) that would otherwise drop user data.
///
/// The dialog widget calls [register] on mount, [updateFullPath] whenever the
/// in-dialog URL changes (e.g., step transitions), and [unregister] on
/// dispose. The router consults [guard] on every navigation; if a URL change
/// would leave the registered dialog's prefix while the dialog reports
/// dirty, [guard] reverts the navigation to the dialog's current URL and
/// queues the "Unsaved Changes" prompt. Clicking Discard releases the
/// registration and replays the original navigation; Keep Editing leaves
/// the user on the dialog.
class DirtyDialogRegistry {
  static String? _activePrefix;
  static String? _activeFullPath;
  static bool Function()? _dirtyCheck;
  static String? _pendingTargetPath;
  static bool _promptInFlight = false;

  /// Registers [dirtyCheck] for the dialog rooted at [prefix] (e.g.
  /// `/classes/5`), with the dialog currently displaying [fullPath]
  /// (e.g. `/classes/5/schedule`). Replaces any prior registration.
  static void register({
    required String prefix,
    required String fullPath,
    required bool Function() isDirty,
  }) {
    _activePrefix = prefix;
    _activeFullPath = fullPath;
    _dirtyCheck = isDirty;
  }

  /// Updates the tracked full URL — call from the dialog's router listener
  /// when in-dialog navigation (step changes) updates the URL while still
  /// within [prefix]. No-ops when [prefix] doesn't own the active slot.
  static void updateFullPath({
    required String prefix,
    required String fullPath,
  }) {
    if (_activePrefix != prefix) return;
    _activeFullPath = fullPath;
  }

  /// Releases the slot if [prefix] still owns it. Call from dispose so a
  /// rapidly-replaced dialog can't accidentally tear down its successor's
  /// registration.
  static void unregister(String prefix) {
    if (_activePrefix != prefix) return;
    _activePrefix = null;
    _activeFullPath = null;
    _dirtyCheck = null;
  }

  /// Releases the slot unconditionally. Call from the dialog's intentional
  /// close path (confirmed discard → `context.pop`) so the router doesn't
  /// double-block the dismissal it explicitly asked for.
  static void releaseActive() {
    _activePrefix = null;
    _activeFullPath = null;
    _dirtyCheck = null;
  }

  /// Returns the URL to revert [targetPath] to when the navigation would
  /// silently drop dirty data, or null to allow the navigation.
  static String? guard(String targetPath) {
    final prefix = _activePrefix;
    final fullPath = _activeFullPath;
    if (prefix == null || fullPath == null) return null;
    if (targetPath.startsWith(prefix)) return null;
    if (_dirtyCheck?.call() != true) return null;
    if (!_promptInFlight) {
      _promptInFlight = true;
      _pendingTargetPath = targetPath;
      // Defer the prompt to a microtask so the redirect can complete
      // synchronously. Showing the prompt mid-redirect can fight the
      // navigator's in-progress transition.
      scheduleMicrotask(_runPrompt);
    }
    return fullPath;
  }

  static Future<void> _runPrompt() async {
    final target = _pendingTargetPath;
    _pendingTargetPath = null;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || target == null) {
      _promptInFlight = false;
      return;
    }
    final shouldDiscard = await confirmDiscardChanges(ctx);
    _promptInFlight = false;
    if (!shouldDiscard) return;
    // User confirmed discard — release the slot so the guard doesn't
    // block our replay, then complete the navigation the user originally
    // attempted.
    releaseActive();
    router.go(target);
  }
}
