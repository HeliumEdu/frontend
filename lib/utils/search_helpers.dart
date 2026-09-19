// Mirrors the platform's `helium/common/utils/searchutils.py`, the two should be kept in parity.

import 'package:diacritic/diacritic.dart';

/// Search utilities for filter-style search fields (planner, notebook,
/// dropdown). Provides case-insensitive, diacritic-insensitive,
/// whitespace-tokenized AND matching: every whitespace-delimited token in
/// the query must appear somewhere in the haystack. A double-quoted span is
/// one token, matched as a contiguous phrase.
class SearchHelper {
  static final RegExp _term = RegExp(r'"([^"]*)"|(\S+)');
  // Keyboards on iOS/macOS substitute typographic quotes; treat them as the
  // phrase delimiter so a quoted search behaves the same on every platform.
  static final RegExp _typographicDoubleQuote = RegExp('[\u201C\u201D\u201E\u201F\uFF02]');
  static final RegExp _whitespace = RegExp(r'\s+');
  // Strips leading/trailing non-alphanumeric from each token. Defends against
  // stray punctuation (e.g. macOS double-space-period substitution leaving
  // "weekend." after a fast-typed trailing space). Internal punctuation is
  // preserved so identifiers like "p.42-50" still match exactly.
  static final RegExp _tokenEdgePunct = RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$');

  /// Fold typographic double quotes to `"`, then lowercase + fold diacritics
  /// (Latin, Cyrillic, Vietnamese, etc.) via the `diacritic` package. Applied
  /// identically to queries and haystacks, and mirrored by the API.
  static String normalize(String s) => removeDiacritics(
        s.replaceAll(_typographicDoubleQuote, '"').toLowerCase(),
      );

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

  static bool hasTerms(String query) => _tokenize(query).isNotEmpty;

  /// The form of [query] the phrase parser and the API's `?search=` both
  /// understand: trimmed and [normalize]d.
  static String normalizeQuery(String query) => normalize(query.trim());

  static List<String> _tokenize(String query) {
    return _term
        .allMatches(normalizeQuery(query))
        .map((m) {
          final phrase = m.group(1);
          final raw = phrase != null
              ? phrase.trim().replaceAll(_whitespace, ' ')
              : m.group(2)!;
          return raw.replaceAll(_tokenEdgePunct, '');
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
