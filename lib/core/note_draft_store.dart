import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

typedef NoteDraft = ({
  String title,
  List<dynamic> ops,
  String? baseVersion,
  int? homeworkId,
  int? eventId,
  int? resourceId,
});

/// A note's edits that the server hasn't confirmed, kept on this device so
/// they survive the app closing. Kept in [PrefService], so logging out clears
/// them.
class NoteDraftStore {
  static const String _key = 'note_drafts';
  static const Duration _maxAge = Duration(days: 90);

  /// The one note being written that the server hasn't created yet.
  static const String newNoteKey = 'new';

  PrefService? _prefServiceOverride;

  PrefService get _prefService => _prefServiceOverride ?? PrefService();

  static final NoteDraftStore _instance = NoteDraftStore._internal();

  factory NoteDraftStore() => _instance;

  NoteDraftStore._internal();

  @visibleForTesting
  NoteDraftStore.forTesting({required PrefService prefService})
    : _prefServiceOverride = prefService;

  static String keyForNote(int noteId) => '$noteId';

  NoteDraft? draftFor(String key) {
    final draft = _readAll()[key];
    if (draft case {
      'title': final String title,
      'ops': final List<dynamic> ops,
    }) {
      return (
        title: title,
        ops: ops,
        baseVersion: draft['base_version'] as String?,
        homeworkId: draft['homework_id'] as int?,
        eventId: draft['event_id'] as int?,
        resourceId: draft['resource_id'] as int?,
      );
    }
    return null;
  }

  DateTime? savedAtFor(String key) => _savedAt(_readAll()[key]);

  void save(String key, NoteDraft draft) {
    final drafts = _readAll()
      ..[key] = {
        'title': draft.title,
        'ops': draft.ops,
        'base_version': draft.baseVersion,
        'homework_id': draft.homeworkId,
        'event_id': draft.eventId,
        'resource_id': draft.resourceId,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      };
    _write(_withoutExpired(drafts));
  }

  void clear(String key) {
    final drafts = _readAll();
    if (drafts.remove(key) == null) return;
    _write(drafts);
  }

  Map<String, dynamic> _readAll() {
    final stored = _prefService.getString(_key);
    if (stored == null) return {};
    try {
      return jsonDecode(stored) as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Discarding unreadable note drafts: ${e.runtimeType}');
      return {};
    }
  }

  Map<String, dynamic> _withoutExpired(Map<String, dynamic> drafts) {
    final cutoff = DateTime.now().subtract(_maxAge);
    return Map.fromEntries(
      drafts.entries.where(
        (entry) => _savedAt(entry.value)?.isAfter(cutoff) ?? false,
      ),
    );
  }

  DateTime? _savedAt(dynamic draft) => switch (draft) {
    {'saved_at': final String savedAt} => DateTime.tryParse(savedAt),
    _ => null,
  };

  void _write(Map<String, dynamic> drafts) {
    final write = drafts.isEmpty
        ? _prefService.removeKeys(const [_key])
        : _prefService.setString(_key, jsonEncode(drafts));
    unawaited(
      write?.catchError((Object e) {
        _log.warning('Saving note drafts failed: ${e.runtimeType}');
      }),
    );
  }
}
