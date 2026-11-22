typedef PrintHandler = Future<void> Function();

/// Singleton that allows screens to register a print handler invoked when
/// the user triggers the platform print shortcut (Cmd+P / Ctrl+P).
///
/// Handlers are managed as stacks so dialogs/overlays can push their own
/// handler on top and pop it on dispose, automatically restoring the
/// underlying screen's handler. Overlay handlers always win over screen
/// handlers, whichever registered last: a screen that finishes loading
/// behind an open overlay must not take over its shortcut.
class PrintService {
  static final PrintService _instance = PrintService._internal();

  factory PrintService() => _instance;

  PrintService._internal();

  final List<PrintHandler> _screenStack = [];
  final List<PrintHandler> _overlayStack = [];

  bool get hasHandler => _screenStack.isNotEmpty || _overlayStack.isNotEmpty;

  void register(PrintHandler handler, {bool isOverlay = false}) {
    (isOverlay ? _overlayStack : _screenStack).add(handler);
  }

  /// Removes [handler] from the stacks by identity. If [handler] is null,
  /// removes the most recently registered overlay handler, or else screen
  /// handler.
  void unregister([PrintHandler? handler]) {
    if (handler != null) {
      _overlayStack.removeWhere((h) => identical(h, handler));
      _screenStack.removeWhere((h) => identical(h, handler));
    } else if (_overlayStack.isNotEmpty) {
      _overlayStack.removeLast();
    } else if (_screenStack.isNotEmpty) {
      _screenStack.removeLast();
    }
  }

  /// Returns true if a handler was registered and invoked, false otherwise
  Future<bool> printCurrent() async {
    final handler = _overlayStack.lastOrNull ?? _screenStack.lastOrNull;
    if (handler == null) return false;
    await handler.call();
    return true;
  }
}
