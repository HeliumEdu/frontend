// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

/// Runtime configuration served by `GET /info/`.
///
/// `/info/` returns additional fields (name, version, token lifetimes, oauth
/// providers) the frontend does not currently consume; only fields with active
/// consumers are modeled here — add more if/when they're used.
class InfoModel {
  final int maxUploadSize;
  final List<String> importFileTypes;
  final String minimumSupportedVersion;

  InfoModel({
    required this.maxUploadSize,
    required this.importFileTypes,
    this.minimumSupportedVersion = '0.0.0',
  });

  factory InfoModel.fromJson(Map<String, dynamic> json) {
    return InfoModel(
      maxUploadSize: json['max_upload_size'],
      importFileTypes: List<String>.from(json['import_file_types']),
      minimumSupportedVersion: json['minimum_supported_version'] ?? '0.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max_upload_size': maxUploadSize,
      'import_file_types': importFileTypes,
      'minimum_supported_version': minimumSupportedVersion,
    };
  }
}
