// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class SignUpController {
  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  bool agreeToTerms = false;
  String selectedTimezone = 'America/Chicago';

  // Populated from tz database
  List<String> timezones = [];

  // Initialize tz database and load timezone IDs
  void initializeTimezones() {
    // Safe to call multiple times; it no-ops after first
    tzdata.initializeTimeZones();
    final allLocations = tz.timeZoneDatabase.locations.keys;
    // Keep only region/zone style IDs and sort alphabetically
    timezones = allLocations.where((id) => id.contains('/')).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!timezones.contains(selectedTimezone)) {
      // Fallback to UTC if default isn't present
      selectedTimezone = 'UTC';
    }
  }

  // Validation methods
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (value.length >= 30) {
      return 'Username must be less than 30 characters';
    }
    final usernameRegExp = RegExp(r'^[A-Za-z0-9+\-_.]+$');
    if (!usernameRegExp.hasMatch(value)) {
      return 'Username can only include letters, numbers, or + - _ .';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Basic email regex pattern
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
  }

  // Toggle terms agreement
  void toggleTermsAgreement() {
    agreeToTerms = !agreeToTerms;
  }

  // Update selected timezone
  void updateTimezone(String? timezone) {
    if (timezone != null) {
      selectedTimezone = timezone;
    }
  }

  // Sign up method
  Future<void> signUp() async {
    if (formKey.currentState!.validate()) {
      if (!agreeToTerms) {
        // You can show a snackbar or toast here
        print('Please agree to Terms of Service and Privacy Policy');
        return;
      }

      isLoading = true;

      try {
        // Add your registration logic here
        // Example API call or authentication service
        await Future.delayed(Duration(seconds: 2)); // Simulate API call

        // Handle successful sign up
        print('Username: ${usernameController.text}');
        print('Email: ${emailController.text}');
        print('Password: ${passwordController.text}');
        print('Timezone: $selectedTimezone');

        // Navigate to next screen or show success message
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } catch (error) {
        // Handle sign up error
        print('Sign up failed: $error');
        // Show error message to user
      } finally {
        isLoading = false;
      }
    }
  }

  // Clear form data
  void clearForm() {
    usernameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    agreeToTerms = false;
    selectedTimezone = 'America/Chicago';
  }

  // Dispose controllers
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
