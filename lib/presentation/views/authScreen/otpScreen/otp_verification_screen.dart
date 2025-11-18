import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_event.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_state.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    return BlocProvider(
      create: (context) => AuthBloc(
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
        ),
        dioClient: dioClient,
      ),
      child: OtpVerificationView(phoneNumber: phoneNumber),
    );
  }
}

class OtpVerificationView extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationView({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _verifyOtp() {
    final otpCode = _getOtpCode();
    if (otpCode.length != 6) {
      _showSnackBar('Please enter complete OTP code', isError: true);
      return;
    }

    context.read<AuthBloc>().add(
      UpdatePhoneEvent(
        phone: widget.phoneNumber,
        verificationCode: int.tryParse(otpCode),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? redColor : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPhoneUpdateSuccess) {
          _showSnackBar('Phone number verified successfully!', isError: false);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true); // Return true to indicate success
            }
          });
        } else if (state is AuthError) {
          _showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: softGrey,
        appBar: AppBar(
          backgroundColor: whiteColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Verify Phone Number',
            style: AppTextStyle.aTextStyle.copyWith(
              color: blackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40.v),
                  Icon(
                    Icons.phone_android_rounded,
                    size: 80.adaptSize,
                    color: primaryColor,
                  ),
                  SizedBox(height: 32.v),
                  Text(
                    'Enter Verification Code',
                    style: AppTextStyle.aTextStyle.copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.v),
                  Text(
                    'We sent a 6-digit code to',
                    style: AppTextStyle.eTextStyle.copyWith(color: textColor),
                  ),
                  SizedBox(height: 4.v),
                  Text(
                    widget.phoneNumber,
                    style: AppTextStyle.eTextStyle.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 40.v),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => _buildOtpField(index),
                    ),
                  ),
                  SizedBox(height: 40.v),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 56.v,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.adaptSize),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Verify',
                                  style: AppTextStyle.bTextStyle.copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.v),
                  TextButton(
                    onPressed: () {
                      // Clear and resend code logic
                      for (var controller in _otpControllers) {
                        controller.clear();
                      }
                      _focusNodes[0].requestFocus();
                      _showSnackBar('Code resent successfully');
                    },
                    child: Text(
                      'Resend Code',
                      style: AppTextStyle.eTextStyle.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 50.h,
      height: 60.v,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(
          color: _otpControllers[index].text.isEmpty
              ? Colors.grey.withOpacity(0.3)
              : primaryColor,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: AppTextStyle.aTextStyle.copyWith(
          color: blackColor,
          fontWeight: FontWeight.w700,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {}); // Update border color
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          } else if (value.isNotEmpty && index == 5) {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }
}
