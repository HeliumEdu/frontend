Map<String, dynamic> givenNoteJson({
  int id = 1,
  String title = 'Note',
  String updatedAt = '2026-10-07T12:00:00.123456Z',
  List<int> homework = const [],
}) {
  return {
    'id': id,
    'title': title,
    'content': {
      'ops': [
        {'insert': '$title body\n'},
      ],
    },
    'updated_at': updatedAt,
    'homework': homework,
    'events': <int>[],
    'resources': <int>[],
    'linked_entity_type': homework.isEmpty ? '' : 'homework',
  };
}
