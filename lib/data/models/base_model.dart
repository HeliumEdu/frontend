abstract class BaseModel {
  final int id;

  /// The raw `updated_at`, sent back as `If-Match` so a stale save is
  /// rejected. Kept as a string because a [DateTime] round trip loses
  /// precision on web.
  final String? version;

  BaseModel({required this.id, this.version});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

abstract class BaseTitledModel extends BaseModel {
  final String title;
  final bool? shownOnCalendar;

  BaseTitledModel({
    required super.id,
    required this.title,
    super.version,
    this.shownOnCalendar,
  });

  @override
  String toString() {
    return title;
  }
}
