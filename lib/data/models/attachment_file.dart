// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

class AttachmentFile {
  final Uint8List bytes;
  final String title;

  AttachmentFile({required this.bytes, required this.title});
}
