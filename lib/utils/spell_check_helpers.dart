import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spell-check configuration for prose fields — free text a user writes in
/// sentences, rather than a name, title, address or credential. Resolves to the
/// platform checker: `UITextChecker` on iOS, the system checker on Android.
///
/// Null wherever the engine defines no checker — always web, and an Android
/// device with no checker installed. Gating on the engine flag rather than the
/// platform needs no conditional import.
///
/// The system checker goes over the whole text on the main thread, so checking
/// after every edit makes long entries lag (flutter/flutter#152205); a check
/// runs once typing pauses instead. A request superseded by a newer one answers
/// null, which [EditableText] takes as "no new results" and keeps shifting the
/// last ones along with the edits.
SpellCheckConfiguration? get proseSpellCheck =>
    WidgetsBinding.instance.platformDispatcher.nativeSpellCheckServiceDefined
    ? _proseSpellCheck
    : null;

final _proseSpellCheck = SpellCheckConfiguration(
  spellCheckService: _DebouncedSpellCheckService(),
);

class _DebouncedSpellCheckService implements SpellCheckService {
  static const _quietPeriod = Duration(milliseconds: 1500);

  final _system = DefaultSpellCheckService();
  Timer? _timer;
  Completer<List<SuggestionSpan>?>? _waiting;

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) {
    _timer?.cancel();
    _waiting?.complete(null);
    final waiting = _waiting = Completer<List<SuggestionSpan>?>();
    _timer = Timer(_quietPeriod, () {
      _waiting = null;
      waiting.complete(_system.fetchSpellCheckSuggestions(locale, text));
    });
    return waiting.future;
  }
}
