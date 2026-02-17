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

abstract class AuthRepository {
  Future<NoContentResponseModel> register(RegisterRequestModel request);

  Future<TokenResponseModel> verifyEmail(String email, String code);

  Future<NoContentResponseModel> resendVerificationEmail(String email);

  Future<TokenResponseModel> login(LoginRequestModel request);

  Future<TokenResponseModel> loginWithGoogle(String firebaseIdToken);

  Future<TokenResponseModel> loginWithApple(String firebaseIdToken);

  Future<TokenResponseModel> refreshToken(RefreshTokenRequestModel request);

  Future<void> logout();

  Future<UserModel> getUser();

  Future<NoContentResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  );

  Future<UserModel> changePassword(ChangePasswordRequestModel request);

  Future<UserSettingsModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  );

  Future<PrivateFeedModel> enablePrivateFeeds();

  Future<void> disablePrivateFeeds();

  Future<NoContentResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  );

  Future<void> deleteExampleSchedule();
}
