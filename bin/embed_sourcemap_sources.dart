import 'dart:convert';
import 'dart:io';

/// Embeds original source text into the web build's source map.
///
/// dart2js emits `sources` but no `sourcesContent`, and it anchors relative
/// source paths at the compiler's output directory
/// (`.dart_tool/flutter_build/<hash>/`) rather than at `build/web/`, where the
/// map is copied. sentry-cli resolves relative paths against the map's own
/// directory, so it can never find a single source on its own and uploads a
/// map Sentry can map frames with but cannot show code for.
///
/// Usage: dart bin/embed_sourcemap_sources.dart [path/to/main.dart.js.map]
const _mapPath = 'build/web/main.dart.js.map';

/// Depth of the dart2js output directory below the project root.
const _anchor = ['.dart_tool', 'flutter_build', 'hash'];

/// Sources behind this scheme live in the SDK and have no file on disk.
const _sdkScheme = 'org-dartlang-sdk:';

/// A run resolving less than this is treated as a layout change, not a build
/// with unusual sources.
const _minimumResolvedRatio = 0.5;

void main(List<String> args) {
  final mapFile = File(args.isNotEmpty ? args.first : _mapPath);
  if (!mapFile.existsSync()) {
    stderr.writeln('Source map not found: ${mapFile.path}');
    exit(1);
  }

  final sourceMap =
      jsonDecode(mapFile.readAsStringSync()) as Map<String, dynamic>;
  final sources = (sourceMap['sources'] as List).cast<String>();
  final anchor = Directory.current.uri.resolveUri(
    Uri(pathSegments: [..._anchor, '']),
  );

  var resolved = 0;
  var skippedSdk = 0;
  final contents = <String?>[];
  for (final source in sources) {
    if (source.startsWith(_sdkScheme)) {
      skippedSdk++;
      contents.add(null);
      continue;
    }
    final file = File.fromUri(anchor.resolve(source));
    if (!file.existsSync()) {
      contents.add(null);
      continue;
    }
    contents.add(file.readAsStringSync());
    resolved++;
  }

  final resolvable = sources.length - skippedSdk;
  if (resolvable == 0 || resolved / resolvable < _minimumResolvedRatio) {
    stderr.writeln(
      'Resolved only $resolved of $resolvable sources, which means the paths in '
      'the map no longer line up with ${_anchor.join('/')}. Refusing to upload a '
      'map Sentry cannot show code for.',
    );
    exit(1);
  }

  sourceMap['sourcesContent'] = contents;
  mapFile.writeAsStringSync(jsonEncode(sourceMap));

  stdout.writeln(
    'Embedded $resolved of $resolvable sources into ${mapFile.path} '
    '($skippedSdk SDK sources have no file on disk).',
  );
}
