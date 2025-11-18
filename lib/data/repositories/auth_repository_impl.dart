import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/auth/change_password_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/change_password_response_model.dart';
import 'package:helium_student_flutter/data/models/auth/delete_account_request_model.dart';
import 'package:helium_student_flutter/data/models/auth/delete_account_response_model.dart';
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
import 'package:helium_student_flutter/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    return await remoteDataSource.register(request);
  }

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    return await remoteDataSource.login(request);
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    return await remoteDataSource.refreshToken(request);
  }

  @override
  Future<void> logout() async {
    return await remoteDataSource.logout();
  }

  @override
  Future<void> blacklistToken(String refreshToken) async {
    return await remoteDataSource.blacklistToken(refreshToken);
  }

  @override
  Future<UserProfileModel> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<DeleteAccountResponseModel> deleteAccount(
    DeleteAccountRequestModel request,
  ) async {
    return await remoteDataSource.deleteAccount(request);
  }

  @override
  Future<UpdatePhoneResponseModel> updatePhoneProfile(
    UpdatePhoneRequestModel request,
  ) async {
    return await remoteDataSource.updatePhoneProfile(request);
  }

  @override
  Future<ChangePasswordResponseModel> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    return await remoteDataSource.changePassword(request);
  }

  @override
  Future<UpdateSettingsResponseModel> updateUserSettings(
    UpdateSettingsRequestModel request,
  ) async {
    return await remoteDataSource.updateUserSettings(request);
  }

  @override
  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    return await remoteDataSource.forgotPassword(request);
  }
}
