import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/config/app_route.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_event.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_state.dart';
import 'package:helium_student_flutter/presentation/views/authScreen/signupScreen/sign_up_controller.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_drop_down.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_text_field.dart';
import 'package:helium_student_flutter/presentation/widgets/custom_text_button.dart';
import 'package:helium_student_flutter/utils/app_assets.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
      child: const SignUpScreenView(),
    );
  }
}

class SignUpScreenView extends StatefulWidget {
  const SignUpScreenView({super.key});

  @override
  State<SignUpScreenView> createState() => _SignUpScreenViewState();
}

class _SignUpScreenViewState extends State<SignUpScreenView> {
  final SignUpController _controller = SignUpController();
  String? _usernameApiError;

  @override
  void initState() {
    super.initState();
    _controller.initializeTimezones();
    // Rebuild to reflect loaded timezones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  void _handleSignUp() {
    if (_usernameApiError != null) {
      setState(() {
        _usernameApiError = null;
      });
    }
    if (_controller.formKey.currentState!.validate()) {
      if (!_controller.agreeToTerms) {
        _showSnackBar(
          'Please agree to Terms of Service and Privacy Policy',
          isError: true,
        );
        return;
      }

      // Dispatch register event
      context.read<AuthBloc>().add(
        RegisterEvent(
          username: _controller.usernameController.text.trim(),
          email: _controller.emailController.text.trim(),
          password: _controller.passwordController.text,
          timezone: _controller.selectedTimezone,
        ),
      );
    }
  }

  bool _handleFieldLevelErrors(AuthError state) {
    final message = state.message;
    if (message.toLowerCase().contains('username')) {
      setState(() {
        _usernameApiError = message;
      });
      return true;
    }
    return false;
  }

  // URL launcher functions
  Future<void> _launchTermsOfService() async {
    final Uri url = Uri.parse('https://www.heliumedu.com/terms');
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      // Fallback: try with platformDefault mode
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (fallbackError) {
        _showErrorDialog(
          'Could not open Terms of Service. Please visit: https://www.heliumedu.com/terms',
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.heliumedu.com/privacy');
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      // Fallback: try with platformDefault mode
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (fallbackError) {
        _showErrorDialog(
          'Could not open Privacy Policy. Please visit: https://www.heliumedu.com/privacy',
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // Show loading indicator - handled by the button state
        } else if (state is AuthRegistrationSuccess) {
          setState(() {
            _usernameApiError = null;
          });
          _showSnackBar(
            'Registration successful! Please check your email for verification.',
            isError: false,
          );
          // Clear the form
          _controller.clearForm();
          setState(() {});
          // Optionally navigate to login screen after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.signInScreen);
            }
          });
        } else if (state is AuthError) {
          final handled = _handleFieldLevelErrors(state);
          if (!handled) {
            _showSnackBar(state.message, isError: true);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            child: Form(
              key: _controller.formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 55.v),

                    Center(
                      child: Image.asset(
                        AppAssets.welcomeImagePath,
                        height: 88.v,
                        width: 600.h,
                      ),
                    ),
                    SizedBox(height: 28.v),

                    Text(
                      'Create your account',
                      style: AppTextStyle.hTextStyle.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 14.v),

                    Text(
                      'Let\'s get started',
                      style: AppTextStyle.fTextStyle.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 44.v),

                    CustomTextField(
                      hintText: 'Username',
                      prefixIcon: Icons.person_outline,
                      controller: _controller.usernameController,
                      validator: _controller.validateUsername,
                      errorText: _usernameApiError,
                      onChanged: (_) {
                        if (_usernameApiError != null) {
                          setState(() {
                            _usernameApiError = null;
                          });
                        }
                      },
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 22.v),

                    CustomTextField(
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      controller: _controller.emailController,
                      validator: _controller.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 22.v),

                    CustomTextField(
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      controller: _controller.passwordController,
                      validator: _controller.validatePassword,
                      obscureText: !_controller.isPasswordVisible,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.togglePasswordVisibility();
                          });
                        },
                        icon: Icon(
                          _controller.isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 22.v),

                    CustomTextField(
                      hintText: 'Confirm password',
                      prefixIcon: Icons.lock_outline,
                      controller: _controller.confirmPasswordController,
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
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 22.v),

                    CustomDropdown(
                      hintText: 'Select Timezone',
                      prefixIcon: Icons.access_time_outlined,
                      value: _controller.selectedTimezone,
                      items: _controller.timezones,
                      onChanged: (value) {
                        setState(() {
                          _controller.updateTimezone(value);
                        });
                      },
                    ),
                    SizedBox(height: 22.v),

                    Row(
                      children: [
                        Checkbox(
                          value: _controller.agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _controller.toggleTermsAgreement();
                            });
                          },
                          activeColor: primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to Helium\'s ',
                              style: AppTextStyle.fTextStyle.copyWith(
                                color: Colors.grey[600],
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: _launchTermsOfService,
                                    child: Text(
                                      'Terms of Service',
                                      style: AppTextStyle.fTextStyle.copyWith(
                                        color: primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: AppTextStyle.fTextStyle.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: _launchPrivacyPolicy,
                                    child: Text(
                                      'Privacy Policy',
                                      style: AppTextStyle.fTextStyle.copyWith(
                                        color: primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 55.v),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return CustomTextButton(
                          buttonText: 'Sign Up',
                          onPressed: _handleSignUp,
                          isLoading: isLoading,
                        );
                      },
                    ),
                    SizedBox(height: 22.v),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyle.fTextStyle.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.signInScreen,
                            );
                          },
                          child: Text(
                            'Login',
                            style: AppTextStyle.fTextStyle.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.v),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
