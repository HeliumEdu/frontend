// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/info_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class InfoRemoteDataSource extends BaseDataSource {
  Future<InfoModel> getInfo();
}

class InfoRemoteDataSourceImpl extends InfoRemoteDataSource {
  final DioClient dioClient;

  InfoRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<InfoModel> getInfo() async {
    try {
      _log.info('Fetching /info/ ...');

      final response = await dioClient.dio.get(ApiUrl.infoUrl);

      if (response.statusCode == 200) {
        _log.info('... fetched /info/');
        return InfoModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch /info/',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred fetching /info/', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }
}
