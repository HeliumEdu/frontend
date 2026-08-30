import 'package:flutter/material.dart';

/// Spell-check configuration for prose fields — free text a user writes in
/// sentences, rather than a name, title, address or credential. Resolves to the
/// platform checker: `UITextChecker` on iOS, the system checker on Android.
///
/// Null wherever the engine defines no checker — always web, and an Android
/// device with no checker installed. [EditableText] disables itself under the
/// same condition but asserts on the way, so a configuration passed
/// unconditionally spams debug builds with a `FlutterError`. Gating on the
/// engine flag rather than the platform needs no conditional import.
SpellCheckConfiguration? get proseSpellCheck =>
    WidgetsBinding.instance.platformDispatcher.nativeSpellCheckServiceDefined
    ? const SpellCheckConfiguration()
    : null;
