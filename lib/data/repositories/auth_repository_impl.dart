// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/auth/request/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/request/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/request/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/private_feed_model.dart';
import 'package:heliumapp/data/models/auth/request/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/no_content_response_model.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<NoContentResponseModel> register(RegisterRequestModel request) async {
    return await remoteDataSource.register(request);
  }

  @override
  Future<TokenResponseModel> verifyEmail(
    String username,
    String code,
  ) async {
    return await remoteDataSource.verifyEmail(username, code);
  }

  @override
  Future<NoContentResponseModel> resendVerificationEmail(String username) async {
    return await remoteDataSource.resendVerificationEmail(username);
  }

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    return await remoteDataSource.login(request);
  }

  @override
  Future<TokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    return await remoteDataSource.refreshToken(request);
  }

  @override
  Future<void> logout() async {
    return await remoteDataSource.logout();
  }

  @override
  Future<UserModel> getUser() async {
    return await remoteDataSource.getUser();
  }

  @override
  Future<NoContentResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  ) async {
    return await remoteDataSource.deleteAccount(request);
  }

  @override
  Future<UserModel> changePassword(ChangePasswordRequestModel request) async {
    return await remoteDataSource.changePassword(request);
  }

  @override
  Future<UserSettingsModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  ) async {
    return await remoteDataSource.updateUserSettings(request);
  }

  @override
  Future<PrivateFeedModel> enablePrivateFeeds() async {
    return await remoteDataSource.enablePrivateFeeds();
  }

  @override
  Future<void> disablePrivateFeeds() async {
    return await remoteDataSource.disablePrivateFeeds();
  }

  @override
  Future<NoContentResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    return await remoteDataSource.forgotPassword(request);
  }
}
