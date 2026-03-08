// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_quill/flutter_quill.dart';
// html (html5lib Dart port) is a transitive dep via flutter_html.
// TODO: Remove the html import below once `comments`/`details` are retired
//  and flutter_html is removed (at which point htmlToQuillDocument goes too).
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<IdOrEntity<T>> idOrEntityListFrom<T extends BaseModel>(
  List<dynamic> data,
  Function fromJson,
) {
  return data.map((item) => IdOrEntity<T>.from(item, fromJson)).toList();
}

IdOrEntity<T> idOrEntityFrom<T extends BaseModel>(
  dynamic data,
  Function fromJson,
) {
  return IdOrEntity<T>.from(data, fromJson);
}

/// Converts legacy HTML to a Quill [Document], preserving inline formatting
/// (bold, italic, underline, strikethrough, links) and block structure
/// (paragraphs, headings, bullet/ordered lists). Used during the migration
/// period while `comments`/`details` fields still exist; the html package
/// (html5lib) handles entity decoding and malformed markup automatically.
// TODO: Remove once `comments`/`details` are retired (and remove the html
//  package imports above — they are only transitive via flutter_html).
Document htmlToQuillDocument(String html) {
  final fragment = html_parser.parseFragment(html);
  final ops = <Map<String, dynamic>>[];
  _htmlNodesToOps(fragment.nodes, ops, {});
  if (ops.isEmpty) return Document();
  // Quill requires the document to end with a bare newline.
  if (ops.last['insert'] != '\n') ops.add({'insert': '\n'});
  return Document.fromJson(ops);
}

/// Parses a CSS inline style string and merges recognised properties into
/// [attrs]. Handles `color`, `background-color`, and `font-family`.
void _applyInlineStyles(String? style, Map<String, dynamic> attrs) {
  if (style == null || style.isEmpty) return;
  for (final declaration in style.split(';')) {
    final colon = declaration.indexOf(':');
    if (colon == -1) continue;
    final property = declaration.substring(0, colon).trim().toLowerCase();
    final value = declaration.substring(colon + 1).trim();
    switch (property) {
      case 'color':
        attrs['color'] = _normalizeColor(value);
      case 'background-color':
        attrs['background'] = _normalizeColor(value);
      case 'font-family':
        attrs['font'] = _normalizeFontName(value);
    }
  }
}

/// Converts `rgb(r, g, b)` to `#rrggbb`; passes hex/named values through.
String _normalizeColor(String value) {
  final m = RegExp(
    r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
  ).firstMatch(value);
  if (m != null) {
    final r = int.parse(m.group(1)!).toRadixString(16).padLeft(2, '0');
    final g = int.parse(m.group(2)!).toRadixString(16).padLeft(2, '0');
    final b = int.parse(m.group(3)!).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
  return value;
}

/// Normalises a font-family string (strips quotes, takes first family,
/// lowercases) to match Quill's font attribute format.
String _normalizeFontName(String value) {
  return value
      .split(',')
      .first
      .trim()
      .replaceAll('"', '')
      .replaceAll("'", '')
      .toLowerCase();
}

void _htmlNodesToOps(
  List<html_dom.Node> nodes,
  List<Map<String, dynamic>> ops,
  Map<String, dynamic> attrs,
) {
  for (final node in nodes) {
    _htmlNodeToOps(node, ops, attrs);
  }
}

void _htmlNodeToOps(
  html_dom.Node node,
  List<Map<String, dynamic>> ops,
  Map<String, dynamic> attrs,
) {
  if (node is html_dom.Text) {
    final text = node.text;
    if (text.isNotEmpty) {
      final op = <String, dynamic>{'insert': text};
      if (attrs.isNotEmpty) op['attributes'] = Map<String, dynamic>.from(attrs);
      ops.add(op);
    }
    return;
  }

  if (node is html_dom.Element) {
    final tag = node.localName;
    final inlineAttrs = Map<String, dynamic>.from(attrs);
    bool isBlock = false;
    Map<String, dynamic>? blockAttrs;

    switch (tag) {
      case 'strong':
      case 'b':
        inlineAttrs['bold'] = true;
      case 'em':
      case 'i':
        inlineAttrs['italic'] = true;
      case 'u':
        inlineAttrs['underline'] = true;
      case 's':
      case 'strike':
      case 'del':
        inlineAttrs['strike'] = true;
      case 'a':
        final href = node.attributes['href'];
        if (href != null && href.isNotEmpty) inlineAttrs['link'] = href;
      case 'br':
        ops.add({'insert': '\n'});
        return;
      // <font> is produced by execCommand('foreColor') and execCommand('fontName')
      // in older browsers and Firefox.
      case 'font':
        final color = node.attributes['color'];
        if (color != null && color.isNotEmpty) {
          inlineAttrs['color'] = _normalizeColor(color);
        }
        final face = node.attributes['face'];
        if (face != null && face.isNotEmpty) {
          inlineAttrs['font'] = _normalizeFontName(face);
        }
      // <span style="..."> is produced by execCommand('foreColor') and
      // execCommand('fontName') in Chrome/modern browsers.
      case 'span':
        _applyInlineStyles(node.attributes['style'], inlineAttrs);
      case 'p':
      case 'div':
        isBlock = true;
      case 'h1':
        isBlock = true;
        blockAttrs = {'header': 1};
      case 'h2':
        isBlock = true;
        blockAttrs = {'header': 2};
      case 'h3':
        isBlock = true;
        blockAttrs = {'header': 3};
      case 'h4':
        isBlock = true;
        blockAttrs = {'header': 4};
      // <blockquote> is produced by execCommand('indent') in Firefox.
      case 'blockquote':
        isBlock = true;
        blockAttrs = {'blockquote': true};
      case 'ul':
      case 'ol':
        // Block marker is added per <li>, not for the list container itself.
        _htmlNodesToOps(node.nodes, ops, inlineAttrs);
        return;
      case 'li':
        isBlock = true;
        blockAttrs = switch (node.parent?.localName) {
          'ol' => {'list': 'ordered'},
          _ => {'list': 'bullet'},
        };
    }

    _htmlNodesToOps(node.nodes, ops, inlineAttrs);

    if (isBlock) {
      final blockOp = <String, dynamic>{'insert': '\n'};
      if (blockAttrs != null) blockOp['attributes'] = blockAttrs;
      ops.add(blockOp);
    }
  }
}
