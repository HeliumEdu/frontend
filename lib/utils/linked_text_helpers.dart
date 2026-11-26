import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

class LinkedText {
  LinkedText._();

  /// [text] as spans, with each of [links]' texts inside it tappable and in
  /// [linkStyle]. Lets a translated sentence place its links anywhere.
  static List<TextSpan> spans(
    String text, {
    required Map<String, GestureRecognizer> links,
    required TextStyle linkStyle,
  }) {
    final linkPattern = RegExp(links.keys.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var start = 0;
    for (final match in linkPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(text: match[0], style: linkStyle, recognizer: links[match[0]]));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}
