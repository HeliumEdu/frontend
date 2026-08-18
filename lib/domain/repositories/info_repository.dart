// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/info_model.dart';

abstract class InfoRepository {
  /// Returns runtime configuration from `GET /info/`. The first successful
  /// response is cached in-memory for the app session; pass [forceRefresh] to
  /// bypass the cache.
  Future<InfoModel> getInfo({bool forceRefresh = false});
}
