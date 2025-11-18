import 'package:helium_student_flutter/data/models/auth/delete_account_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/delete_account_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/change_password_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/change_password_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/login_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/login_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/refresh_token_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/refresh_token_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/register_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/register_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/update_phone_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/update_phone_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/update_settings_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/update_settings_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/forgot_password_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/forgot_password_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/user_profile_model.dart';

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
  Future<UpdatePhoneResponseModel> updatePhoneProfile(
    UpdatePhoneRequestModel request,
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
