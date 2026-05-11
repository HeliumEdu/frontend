// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/info_model.dart';
import 'package:heliumapp/data/sources/info_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/info_repository.dart';

class InfoRepositoryImpl implements InfoRepository {
  final InfoRemoteDataSource remoteDataSource;

  InfoModel? _cached;

  InfoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<InfoModel> getInfo({bool forceRefresh = false}) async {
    final cached = _cached;
    if (cached != null && !forceRefresh) {
      return cached;
    }

    final info = await remoteDataSource.getInfo();
    _cached = info;
    return info;
  }
}
