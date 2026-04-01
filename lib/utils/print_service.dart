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
/// The most recently registered handler wins, so dialogs/overlays can
/// temporarily override the underlying screen's handler and restore it
/// on dispose.
class PrintService {
  static final PrintService _instance = PrintService._internal();

  factory PrintService() => _instance;

  PrintService._internal();

  PrintHandler? _handler;

  void register(PrintHandler handler) {
    _handler = handler;
  }

  void unregister() {
    _handler = null;
  }

  /// Returns true if a handler was registered and invoked, false otherwise.
  Future<bool> printCurrent() async {
    if (_handler == null) return false;
    await _handler!.call();
    return true;
  }
}
