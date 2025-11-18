class ExternalCalendarModel {
  final int id;
  final String title;
  final String url;
  final String color;
  final bool shownOnCalendar;
  final String? comments;
  final int userId;

  const ExternalCalendarModel({
    required this.id,
    required this.title,
    required this.url,
    required this.color,
    required this.shownOnCalendar,
    this.comments,
    required this.userId,
  });

  /// Backwards-compatible getter for existing usages that expect `enabled`.
  bool get enabled => shownOnCalendar;

  factory ExternalCalendarModel.fromJson(Map<String, dynamic> json) {
    final bool shown = (json['shown_on_calendar'] ??
            json['enabled'] ??
            json['is_enabled'] ??
            false) as bool;

    return ExternalCalendarModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      color: _normalizeColor(json['color']?.toString()),
      shownOnCalendar: shown,
      comments: json['comments']?.toString(),
      userId: json['user'] is int
          ? json['user'] as int
          : int.tryParse('${json['user']}') ?? 0,
    );
  }

  ExternalCalendarModel copyWith({
    int? id,
    String? title,
    String? url,
    String? color,
    bool? shownOnCalendar,
    String? comments,
    int? userId,
  }) {
    return ExternalCalendarModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      color: color != null ? _normalizeColor(color) : this.color,
      shownOnCalendar: shownOnCalendar ?? this.shownOnCalendar,
      comments: comments ?? this.comments,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'url': url,
      'color': color,
      'shown_on_calendar': shownOnCalendar,
      'user': userId,
    };

    if (comments != null && comments!.isNotEmpty) {
      data['comments'] = comments;
    }

    return data;
  }

  static String _normalizeColor(String? value) {
    if (value == null || value.isEmpty) {
      return '#16a765';
    }
    String hex = value.trim().toLowerCase();
    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }
    if (hex.length == 9) {
      // Strip alpha channel if provided (#aarrggbb)
      hex = '#${hex.substring(3)}';
    } else if (hex.length == 4) {
      // Expand shorthand (#rgb) to (#rrggbb)
      final r = hex[1], g = hex[2], b = hex[3];
      hex = '#$r$r$g$g$b$b';
    }
    return hex;
  }
}
