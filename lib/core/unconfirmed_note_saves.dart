import 'package:flutter_quill/quill_delta.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';

class UnconfirmedNoteSaves {
  static const _maxUnconfirmedSaves = 5;
  final List<({String title, Delta content})> _unconfirmedSaves = [];

  void remember(String title, List<dynamic> ops) {
    final content = Delta.fromJson(ops);
    final last = _unconfirmedSaves.lastOrNull;
    if (last != null && last.title == title && last.content == content) return;

    _unconfirmedSaves.add((title: title, content: content));
    if (_unconfirmedSaves.length > _maxUnconfirmedSaves) {
      // The oldest send is the one in flight when the connection dropped, so
      // it is the likeliest to have reached the server; drop the next oldest.
      _unconfirmedSaves.removeAt(1);
    }
  }

  bool isOwnWrite(NoteModel latest) {
    final ops = latest.content?['ops'];
    if (ops == null) return false;

    final latestContent = Delta.fromJson(ops);
    for (final sent in _unconfirmedSaves) {
      if (sent.title == latest.title && sent.content == latestContent) {
        return true;
      }
    }
    return false;
  }

  void clear() => _unconfirmedSaves.clear();
}
