// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

class SignInController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController changePasswordController =
      TextEditingController();
  final TextEditingController changeNewPasswordController =
      TextEditingController();
  final TextEditingController changeConfirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isChangePasswordVisible = false;
  bool isLoading = false;

  // Validation methods
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateChangePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != changeNewPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
  }

  void toggleChangePasswordVisibility() {
    isChangePasswordVisible = !isChangePasswordVisible;
  }

  // Sign in method
  Future<void> signIn() async {
    if (formKey.currentState!.validate()) {
      isLoading = true;

      try {
        // Add your authentication logic here
        // Example API call or authentication service
        await Future.delayed(Duration(seconds: 2)); // Simulate API call

        // Handle successful sign in
        print('Username: ${usernameController.text}');
        print('Password: ${passwordController.text}');

        // Navigate to next screen or show success message
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } catch (error) {
        // Handle sign in error
        print('Sign in failed: $error');
        // Show error message to user
      } finally {
        isLoading = false;
      }
    }
  }

  // Clear form data
  void clearForm() {
    usernameController.clear();
    passwordController.clear();
    changePasswordController.clear();
    changeNewPasswordController.clear();
    changeConfirmPasswordController.clear();
  }

  // Dispose controllers
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    changePasswordController.dispose();
    changeNewPasswordController.dispose();
    changeConfirmPasswordController.dispose();
  }
}
