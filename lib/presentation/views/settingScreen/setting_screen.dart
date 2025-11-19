import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/config/app_route.dart';
import 'package:helium_student_flutter/core/dio_client.dart';
import 'package:helium_student_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:helium_student_flutter/data/repositories/auth_repository_impl.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_bloc.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_event.dart';
import 'package:helium_student_flutter/presentation/bloc/authBloc/auth_state.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

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
      child: const SettingScreenView(),
    );
  }
}

class SettingScreenView extends StatefulWidget {
  const SettingScreenView({super.key});

  @override
  State<SettingScreenView> createState() => _SettingScreenViewState();
}

class _SettingScreenViewState extends State<SettingScreenView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  TextEditingController? _deletePasswordController;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: redColor, size: 24),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: AppTextStyle.bTextStyle.copyWith(
                color: blackColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyle.eTextStyle.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyle.eTextStyle.copyWith(color: textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: AppTextStyle.eTextStyle.copyWith(
                color: whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fetch profile data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const GetProfileEvent());
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _deletePasswordController?.dispose();
    super.dispose();
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    // Create a new controller for this dialog
    _deletePasswordController?.dispose();
    _deletePasswordController = TextEditingController();
    bool obscurePassword = true;

    // Capture the parent context that has access to AuthBloc
    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: redColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: AppTextStyle.bTextStyle.copyWith(
                    color: redColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: AppTextStyle.eTextStyle.copyWith(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20.v),
                Text(
                  'Enter your password to confirm:',
                  style: AppTextStyle.cTextStyle.copyWith(
                    color: textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 12.v),
                Container(
                  decoration: BoxDecoration(
                    color: softGrey,
                    borderRadius: BorderRadius.circular(12.adaptSize),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.h),
                        child: Icon(
                          Icons.lock_outline,
                          color: textColor.withOpacity(0.4),
                          size: 20.adaptSize,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _deletePasswordController,
                          obscureText: obscurePassword,
                          style: AppTextStyle.eTextStyle.copyWith(
                            color: blackColor,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: AppTextStyle.eTextStyle.copyWith(
                              color: textColor.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.h,
                              vertical: 14.v,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textColor.withOpacity(0.4),
                          size: 20.adaptSize,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: AppTextStyle.eTextStyle.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final password = _deletePasswordController?.text.trim() ?? '';
                if (password.isEmpty) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your password'),
                      backgroundColor: redColor,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                // Close dialog first
                Navigator.of(dialogContext).pop();

                // Dispatch delete account event using the parent context
                parentContext.read<AuthBloc>().add(
                  DeleteAccountEvent(password: password),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.v),
              ),
              child: Text(
                'Delete Account',
                style: AppTextStyle.eTextStyle.copyWith(
                  color: whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileLoaded) {
          setState(() {
            _usernameController.text = state.username;
            _emailController.text = state.email;
          });
        } else if (state is AuthLogoutSuccess) {
          _showSnackBar(context, 'Logged out successfully', isError: false);
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.signInScreen, (route) => false);
          });
        } else if (state is AuthAccountDeletedSuccess) {
          _showSnackBar(context, state.message, isError: false);
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.signInScreen, (route) => false);
          });
        } else if (state is AuthPhoneUpdateSuccess) {
          if (state.phoneChanging != null && !state.phoneVerified) {
            _showSnackBar(
              context,
              'Verification code sent to ${state.phoneChanging}',
              isError: false,
            );
          } else if (state.phoneVerified) {
            _showSnackBar(
              context,
              'Phone number verified successfully!',
              isError: false,
            );
          }
        } else if (state is AuthError) {
          _showSnackBar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: softGrey,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: 16.v,
                    horizontal: 16.h),
                decoration: BoxDecoration(
                  color: whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: blackColor.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                      'Settings',
                      style: AppTextStyle.bTextStyle.copyWith(
                        color: blackColor
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: Icon(Icons.logout_outlined, color: redColor),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          if (isLoading) {
                            return Container(
                              padding: EdgeInsets.all(40.adaptSize),
                              decoration: BoxDecoration(
                                color: whiteColor,
                                borderRadius: BorderRadius.circular(
                                  16.adaptSize,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        whiteColor,
                                      ),
                                    ),
                                    SizedBox(height: 16.v),
                                    Text(
                                      'Loading profile...',
                                      style: AppTextStyle.eTextStyle.copyWith(
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: EdgeInsets.all(20.adaptSize),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(16.adaptSize),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Username',
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: textColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: softGrey,
                                        borderRadius: BorderRadius.circular(
                                          12.adaptSize,
                                        ),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.h,
                                            ),
                                            child: Icon(
                                              Icons.person_outline,
                                              color: textColor.withOpacity(0.4),
                                              size: 20.adaptSize,
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _usernameController,
                                              enabled: false,
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              decoration: InputDecoration(
                                                hintText: 'Username',
                                                hintStyle: AppTextStyle
                                                    .eTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.4),
                                                    ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12.h,
                                                      vertical: 14.v,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.v),

                                // Email Input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email Address',
                                      style: AppTextStyle.cTextStyle.copyWith(
                                        color: textColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 8.v),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: softGrey,
                                        borderRadius: BorderRadius.circular(
                                          12.adaptSize,
                                        ),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.h,
                                            ),
                                            child: Icon(
                                              Icons.email_outlined,
                                              color: textColor.withOpacity(0.4),
                                              size: 20.adaptSize,
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              enabled: false,
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: blackColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              decoration: InputDecoration(
                                                hintText: 'Email Address',
                                                hintStyle: AppTextStyle
                                                    .eTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.4),
                                                    ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12.h,
                                                      vertical: 14.v,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.v),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24.v),

                      // Padding(
                      //   padding: EdgeInsets.only(left: 4.h, bottom: 16.v),
                      //   child: Text(
                      //     'Account Settings',
                      //     style: AppTextStyle.bTextStyle.copyWith(
                      //       color: blackColor,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),

                      Container(
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(16.adaptSize),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.changePasswordScreen,
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  16.adaptSize,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 16.v,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.adaptSize),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12.adaptSize,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: primaryColor,
                                          size: 22.adaptSize,
                                        ),
                                      ),
                                      SizedBox(width: 16.h),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Change Password',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            SizedBox(height: 2.v),
                                            Text(
                                              'Update your password',
                                              style: AppTextStyle.cTextStyle
                                                  .copyWith(
                                                    color: textColor
                                                        .withOpacity(0.6),
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: textColor.withOpacity(0.3),
                                        size: 16.adaptSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Divider(height: 1, indent: 68.h),

                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.preferenceScreen,
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  16.adaptSize,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 16.v,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.adaptSize),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12.adaptSize,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.tune,
                                          color: Colors.blue,
                                          size: 22.adaptSize,
                                        ),
                                      ),
                                      SizedBox(width: 16.h),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.preferenceScreen,
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Preferences',
                                                style: AppTextStyle.eTextStyle
                                                    .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              SizedBox(height: 2.v),
                                              Text(
                                                'App settings and preferences',
                                                style: AppTextStyle.cTextStyle
                                                    .copyWith(
                                                      color: textColor
                                                          .withOpacity(0.6),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: textColor.withOpacity(0.3),
                                        size: 16.adaptSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Divider(height: 1, indent: 68.h),

                            

                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.feedSettingsScreen,
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  16.adaptSize,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.h,
                                    vertical: 16.v,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10.adaptSize),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12.adaptSize,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.rss_feed,
                                          color: primaryColor,
                                          size: 22.adaptSize,
                                        ),
                                      ),
                                      SizedBox(width: 16.h),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Feed Settings',
                                              style: AppTextStyle.eTextStyle
                                                  .copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            SizedBox(height: 2.v),
                                            Text(
                                              'Manage calendar feeds and external calendars',
                                              style: AppTextStyle.cTextStyle
                                                  .copyWith(
                                                    color: textColor
                                                        .withOpacity(0.6),
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: textColor.withOpacity(0.3),
                                        size: 16.adaptSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.v),

                      Container(
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(16.adaptSize),
                          border: Border.all(
                            color: redColor.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showDeleteAccountDialog(context),
                            borderRadius: BorderRadius.circular(16.adaptSize),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.h,
                                vertical: 16.v,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.adaptSize),
                                    decoration: BoxDecoration(
                                      color: redColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        12.adaptSize,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: redColor,
                                      size: 22.adaptSize,
                                    ),
                                  ),
                                  SizedBox(width: 16.h),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delete Account',
                                          style: AppTextStyle.eTextStyle
                                              .copyWith(
                                                color: redColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(height: 2.v),
                                        Text(
                                          'Permanently delete your account',
                                          style: AppTextStyle.cTextStyle
                                              .copyWith(
                                                color: textColor.withOpacity(
                                                  0.6,
                                                ),
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: textColor.withOpacity(0.3),
                                    size: 16.adaptSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32.v),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
