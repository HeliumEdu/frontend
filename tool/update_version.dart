// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

/// Script to update version placeholder in build/web/index.html from pubspec.yaml
///
/// This should be run AFTER `flutter build web` to substitute the {{VERSION}}
/// placeholder in the built output. The source web/index.html should always
/// keep the {{VERSION}} placeholder.
///
/// Usage: dart tool/update_version.dart
void main() async {
  // ignore: avoid_print
  print('Updating version in build/web/index.html from pubspec.yaml...');

  // Read pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    // ignore: avoid_print
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  final pubspecContent = await pubspecFile.readAsString();

  // Extract version (format: "version: 1.0.25+25")
  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true)
      .firstMatch(pubspecContent);

  if (versionMatch == null) {
    // ignore: avoid_print
    print('Error: Could not find version in pubspec.yaml');
    exit(1);
  }

  final fullVersion = versionMatch.group(1)!.trim();
  // Extract just the version number before the '+' (e.g., "1.0.25" from "1.0.25+25")
  final version = fullVersion.split('+').first;

  // ignore: avoid_print
  print('Found version: $version');

  // Read built index.html
  final indexFile = File('build/web/index.html');
  if (!indexFile.existsSync()) {
    // ignore: avoid_print
    print('Error: build/web/index.html not found. Run `flutter build web` first.');
    exit(1);
  }

  final indexContent = await indexFile.readAsString();

  // Replace {{VERSION}} placeholder with actual version
  final updatedContent = indexContent.replaceAll('{{VERSION}}', version);

  // Write updated content
  await indexFile.writeAsString(updatedContent);

  // ignore: avoid_print
  print('Successfully updated version to $version in build/web/index.html');
}
