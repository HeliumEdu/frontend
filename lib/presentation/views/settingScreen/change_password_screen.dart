// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumedu/core/dio_client.dart';
import 'package:heliumedu/data/datasources/auth_remote_data_source.dart';
import 'package:heliumedu/data/repositories/auth_repository_impl.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_event.dart';
import 'package:heliumedu/presentation/bloc/authBloc/auth_state.dart';
import 'package:heliumedu/presentation/views/settingScreen/change_password_controller.dart';
import 'package:heliumedu/presentation/widgets/custom_text_field.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ChangePasswordController _controller = ChangePasswordController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final DioClient dioClient = DioClient();
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        ),
        dioClient: dioClient,
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.v,
                    horizontal: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    boxShadow: [
                      BoxShadow(
                        color: blackColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: textColor,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      Text(
                        'Change Password',
                        style: AppTextStyle.bTextStyle.copyWith(
                          color: blackColor,
                        ),
                      ),
                      Icon(Icons.abc, color: transparentColor),
                    ],
                  ),
                ),
                SizedBox(height: 22.v),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Password',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 12.v),

                        CustomTextField(
                          hintText: '',
                          prefixIcon: Icons.lock,
                          controller: _controller.changePasswordController,
                          validator: _controller.validateChangePassword,
                          obscureText: !_controller.isCurrentPasswordVisible,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _controller.toggleCurrentPasswordVisibility();
                              });
                            },
                            icon: Icon(
                              _controller.isCurrentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 18.v),
                        Text(
                          'New Password',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 12.v),

                        CustomTextField(
                          hintText: '',
                          prefixIcon: Icons.lock,
                          controller: _controller.changeNewPasswordController,
                          validator: _controller.validateChangePassword,
                          obscureText: !_controller.isNewPasswordVisible,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _controller.toggleNewPasswordVisibility();
                              });
                            },
                            icon: Icon(
                              _controller.isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textColor,
                            ),
                          ),
                        ),

                        Text(
                          'Confirm Password',
                          style: AppTextStyle.cTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 12.v),

                        CustomTextField(
                          hintText: '',
                          prefixIcon: Icons.lock,
                          controller:
                              _controller.changeConfirmPasswordController,
                          validator: _controller.validateConfirmPassword,
                          obscureText: !_controller.isConfirmPasswordVisible,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _controller.toggleConfirmPasswordVisibility();
                              });
                            },
                            icon: Icon(
                              _controller.isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 44.v),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state is AuthPasswordChangeSuccess) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: redColor,
                                    content: Text(state.message),
                                  ),
                                );
                                Navigator.pop(context);
                              } else if (state is AuthError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: redColor,
                                    content: Text(state.message),
                                  ),
                                );
                              }
                            },
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              return ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          if (_controller
                                                  .changeNewPasswordController
                                                  .text ==
                                              _controller
                                                  .changePasswordController
                                                  .text) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                backgroundColor: redColor,
                                                content: Text(
                                                  'New password same like current password',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (_controller
                                                  .changeNewPasswordController
                                                  .text !=
                                              _controller
                                                  .changeConfirmPasswordController
                                                  .text) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                backgroundColor: redColor,
                                                content: Text(
                                                  'New and confirm passwords do not match',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          context.read<AuthBloc>().add(
                                            ChangePasswordEvent(
                                              oldPassword: _controller
                                                  .changePasswordController
                                                  .text,
                                              newPassword: _controller
                                                  .changeNewPasswordController
                                                  .text,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  minimumSize: Size(77.v, 50.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.h),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: whiteColor,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: AppTextStyle.mTextStyle.copyWith(
                                          color: whiteColor,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
