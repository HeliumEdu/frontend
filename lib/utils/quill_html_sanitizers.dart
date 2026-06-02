// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

typedef HtmlSanitizer = String Function(String html);

final List<HtmlSanitizer> _sanitizers = [
  _sanitizeGoogleDocs,
  _sanitizeWordOnline,
];

/// Runs all registered [HtmlSanitizer]s on [html] in order.
/// To support additional clipboard sources, add a private sanitizer function
/// and include it in [_sanitizers].
String sanitizeClipboardHtml(String html) =>
    _sanitizers.fold(html, (current, sanitize) => sanitize(current));

/// Google Docs wraps all clipboard content in an outer
/// `<b style="font-weight:normal;" id="docs-internal-guid-...">` element.
/// [HtmlToDelta] treats this as a semantic bold wrapper, applying bold to all
/// content and collapsing block structure (paragraph breaks). Stripping the
/// wrapper restores correct formatting and line breaks.
String _sanitizeGoogleDocs(String html) {
  final re = RegExp(
    r'<b\b[^>]*docs-internal-guid[^>]*>([\s\S]*)<\/b>\s*$',
    caseSensitive: false,
  );
  final match = re.firstMatch(html);
  if (match == null) return html;
  return html.substring(0, match.start) + match.group(1)!;
}

/// Word Online (Word for the Web) produces a substantially different HTML
/// format from desktop Word. Key problems [HtmlToDelta] cannot handle:
///
/// - Each list item is wrapped in its own `<div class="ListContainerWrapper">`
///   with its own `<ul>`/`<ol>`, so items appear as separate single-item lists.
///   Numbered lists each restart at 1.
/// - Each `<li>` contains a nested `<p>`, causing HtmlToDelta to emit a line
///   break between the bullet marker and its text content.
/// - Headings are `<p role="heading" aria-level="N">` rather than `<hN>`,
///   which HtmlToDelta does not recognise as headings.
///
/// This sanitizer:
/// 1. Converts heading paragraphs to proper `<hN>` tags.
/// 2. Unwraps `ListContainerWrapper` divs so their lists become adjacent.
/// 3. Merges consecutive `<ul>` and `<ol>` elements into single lists.
/// 4. Strips `<p>` wrappers inside `<li>` elements.
String _sanitizeWordOnline(String html) {
  // data-ccp-props is a Word Online-specific data attribute.
  if (!html.contains('data-ccp-props')) return html;

  // Step 1: Convert <p role="heading" aria-level="N"> to <hN>.
  // The lookahead ensures role="heading" is present regardless of attribute order.
  html = html.replaceAllMapped(
    RegExp(
      r'<p\b(?=[^>]*\brole="heading")[^>]*\baria-level="(\d+)"[^>]*>([\s\S]*?)<\/p>',
      caseSensitive: false,
    ),
    (match) => '<h${match.group(1)!}>${match.group(2)!}</h${match.group(1)!}>',
  );

  // Step 2: Unwrap ListContainerWrapper divs. Each list item lives in its own
  // wrapper div; stripping those makes the <ul>/<ol> elements adjacent.
  html = html.replaceAllMapped(
    RegExp(
      r'<div\b[^>]*\bListContainerWrapper\b[^>]*>([\s\S]*?)<\/div>',
      caseSensitive: false,
    ),
    (match) => match.group(1)!,
  );

  // Step 3: Merge consecutive <ul> and <ol> elements.
  html = html.replaceAll(
    RegExp(r'<\/ul>\s*<ul\b[^>]*>', caseSensitive: false),
    '',
  );
  html = html.replaceAll(
    RegExp(r'<\/ol>\s*<ol\b[^>]*>', caseSensitive: false),
    '',
  );

  // Step 4: Strip <p> wrappers inside <li> elements, keeping their content.
  html = html.replaceAllMapped(
    RegExp(
      r'(<li\b[^>]*>)\s*<p\b[^>]*>([\s\S]*?)<\/p>\s*(<\/li>)',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)!}${match.group(2)!}${match.group(3)!}',
  );

  return html;
}
