// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:io';

/// Script to update version in web/index.html from pubspec.yaml
///
/// Usage: dart tool/update_version.dart
void main() async {
  print('Updating version in web/index.html from pubspec.yaml...');

  // Read pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  final pubspecContent = await pubspecFile.readAsString();

  // Extract version (format: "version: 1.0.25+25")
  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true)
      .firstMatch(pubspecContent);

  if (versionMatch == null) {
    print('Error: Could not find version in pubspec.yaml');
    exit(1);
  }

  final fullVersion = versionMatch.group(1)!.trim();
  // Extract just the version number before the '+' (e.g., "1.0.25" from "1.0.25+25")
  final version = fullVersion.split('+').first;

  print('Found version: $version');

  // Read index.html
  final indexFile = File('web/index.html');
  if (!indexFile.existsSync()) {
    print('Error: web/index.html not found');
    exit(1);
  }

  var indexContent = await indexFile.readAsString();

  // Replace version placeholder
  final updatedContent = indexContent.replaceAll(
    RegExp(r'<meta name="version" content="[^"]*">'),
    '<meta name="version" content="$version">',
  );

  // Write updated content
  await indexFile.writeAsString(updatedContent);

  print('Successfully updated version to $version in web/index.html');
}
