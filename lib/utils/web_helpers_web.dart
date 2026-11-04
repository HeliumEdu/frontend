import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Calls the browser's native print dialog synchronously.
/// Must be called within a user-activation window (e.g. directly in a key handler).
void triggerBrowserPrint() => web.window.print();

bool getSystemReduceMotion() =>
    web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

bool getSystemIncreaseContrast() =>
    web.window.matchMedia('(prefers-contrast: more)').matches;

/// Reloads the page to pull the latest web build (the web equivalent of an
/// app-store update).
void reloadPage() => web.window.location.reload();

/// Has the browser confirm closing or reloading the page while
/// [hasUnsavedChanges].
void warnBeforeUnloadWhile(bool Function() hasUnsavedChanges) {
  web.window.addEventListener(
    'beforeunload',
    (web.BeforeUnloadEvent event) {
      if (!hasUnsavedChanges()) return;
      event.preventDefault();
      event.returnValue = '';
    }.toJS,
  );
}
