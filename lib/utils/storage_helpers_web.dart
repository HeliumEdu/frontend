// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

final _log = Logger('utils');

Future<bool> downloadFilePlatform(String url, String filename) async {
  try {
    // Download the file to memory first
    final response = await Dio().get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      _log.warning('No data received from download URL');
      return false;
    }

    final jsUint8Array = response.data!.toJS;
    final blob = web.Blob(
      [jsUint8Array].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final blobUrl = web.URL.createObjectURL(blob);

    // Create anchor element and trigger download
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = blobUrl
      ..download = filename
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();

    anchor.remove();
    web.URL.revokeObjectURL(blobUrl);

    _log.info('Web download triggered for: $filename');
    return true;
  } catch (e) {
    _log.severe('Web download failed', e);
    return false;
  }
}
