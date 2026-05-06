// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:diacritic/diacritic.dart';

/// Search utilities for filter-style search fields (planner, notebook,
/// dropdown). Provides case-insensitive, diacritic-insensitive,
/// whitespace-tokenized AND matching: every whitespace-delimited token in
/// the query must appear somewhere in the haystack.
class SearchHelper {
  static final RegExp _whitespace = RegExp(r'\s+');
  // Strips leading/trailing non-alphanumeric from each token. Defends against
  // stray punctuation (e.g. macOS double-space-period substitution leaving
  // "weekend." after a fast-typed trailing space). Internal punctuation is
  // preserved so identifiers like "p.42-50" still match exactly.
  static final RegExp _tokenEdgePunct = RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$');

  /// Lowercase + fold diacritics (Latin, Cyrillic, Vietnamese, etc.) via the
  /// `diacritic` package.
  static String normalize(String s) => removeDiacritics(s.toLowerCase());

  /// True iff every whitespace-delimited token in [query] appears in
  /// [haystack] after normalization. Empty/whitespace-only query → true.
  static bool matches(String haystack, String query) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return true;
    final normalizedHaystack = normalize(haystack);
    return tokens.every(normalizedHaystack.contains);
  }

  /// True iff every token in [query] appears in at least one of [haystacks]
  /// (tokens may span fields — the row is searched as a unit). Null entries
  /// are skipped.
  static bool matchesAny(Iterable<String?> haystacks, String query) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return true;
    final combined = haystacks
        .where((h) => h != null && h.isNotEmpty)
        .cast<String>()
        .map(normalize)
        .join(' ');
    return tokens.every(combined.contains);
  }

  static List<String> _tokenize(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return normalize(trimmed)
        .split(_whitespace)
        .map((t) => t.replaceAll(_tokenEdgePunct, ''))
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
