// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Client-side semver comparison for the force-update gate. Mirrors the
/// backend's `versionutils` contract (3-segment `major.minor.patch` with an
/// optional `+build` suffix, e.g. `3.6.18+336`), but with the OPPOSITE
/// fail-direction: where the server treats an unparseable version as
/// unsupported, the client fails OPEN — a parse failure must never lock a user
/// out — so [isBelow] returns false unless the version is unambiguously older.
class VersionHelpers {
  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$');

  /// Whether [version] is older than [minimum] — the force-update condition.
  /// Returns false (do not gate) if either value is malformed.
  static bool isBelow(String version, String minimum) {
    final current = _parse(version);
    final floor = _parse(minimum);
    if (current == null || floor == null) return false;

    for (var i = 0; i < 3; i++) {
      if (current[i] != floor[i]) return current[i] < floor[i];
    }
    return false;
  }

  static List<int>? _parse(String version) {
    final match = _pattern.firstMatch(version.trim());
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }
}
