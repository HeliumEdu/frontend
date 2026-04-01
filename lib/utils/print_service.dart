// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

typedef PrintHandler = Future<void> Function();

/// Singleton that allows screens to register a print handler invoked when
/// the user triggers the platform print shortcut (Cmd+P / Ctrl+P).
///
/// Handlers are managed as a stack so dialogs/overlays can push their own
/// handler on top and pop it on dispose, automatically restoring the
/// underlying screen's handler.
class PrintService {
  static final PrintService _instance = PrintService._internal();

  factory PrintService() => _instance;

  PrintService._internal();

  final List<PrintHandler> _stack = [];

  bool get hasHandler => _stack.isNotEmpty;

  void register(PrintHandler handler) {
    _stack.add(handler);
  }

  /// Removes [handler] from the stack by identity. If [handler] is null,
  /// removes the most recently registered handler.
  void unregister([PrintHandler? handler]) {
    if (handler != null) {
      _stack.removeWhere((h) => identical(h, handler));
    } else if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// Returns true if a handler was registered and invoked, false otherwise.
  Future<bool> printCurrent() async {
    if (_stack.isEmpty) return false;
    await _stack.last.call();
    return true;
  }
}
