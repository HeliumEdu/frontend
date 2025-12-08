// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/auth/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/change_password_response_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_response_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_response_model.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/login_response_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_response_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/register_response_model.dart';
import 'package:heliumapp/data/models/auth/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/update_settings_response_model.dart';
import 'package:heliumapp/data/models/auth/user_profile_model.dart';

abstract class AuthRepository {
  Future<RegisterResponseModel> register(RegisterRequestModel request);

  Future<LoginResponseModel> login(LoginRequestModel request);

  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  );

  Future<void> logout();

  Future<void> blacklistToken(String refreshToken);

  Future<UserProfileModel> getProfile();

  Future<DeleteAccountResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  );

  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  );

  Future<UpdateSettingsResponseModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  );

  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  );
}
