// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/info_model.dart';

abstract class InfoRepository {
  /// Returns runtime configuration from `GET /info/`. The first successful
  /// response is cached in-memory for the app session; pass [forceRefresh] to
  /// bypass the cache.
  Future<InfoModel> getInfo({bool forceRefresh = false});
}
