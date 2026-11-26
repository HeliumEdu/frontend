import 'dart:io';

/// Replaces the {{VERSION}} placeholder in build/web/index.html with pubspec.yaml's version, build number included.
/// Run after `flutter build web`; web/index.html keeps the placeholder.
///
/// Usage: dart bin/update_version.dart
void main() {
  stdout.writeln('Updating version in build/web/index.html from pubspec.yaml ...');

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found');
    exit(1);
  }

  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspecFile.readAsStringSync());
  if (versionMatch == null) {
    stderr.writeln('Error: Could not find version in pubspec.yaml');
    exit(1);
  }
  final version = versionMatch.group(1)!.trim();
  stdout.writeln('Found version: $version');

  final indexFile = File('build/web/index.html');
  if (!indexFile.existsSync()) {
    stderr.writeln('Error: build/web/index.html not found. Run `flutter build web` first.');
    exit(1);
  }
  indexFile.writeAsStringSync(indexFile.readAsStringSync().replaceAll('{{VERSION}}', version));

  stdout.writeln('Successfully updated version to $version in build/web/index.html');
}
