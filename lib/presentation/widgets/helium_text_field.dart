// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/app_colors.dart';
import 'package:heliumapp/utils/app_size.dart';
import 'package:heliumapp/utils/app_style.dart';

class HeliumTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const HeliumTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    required this.validator,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,

        border: Border.all(color: textColor.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: AppStyle.fTextStyle.copyWith(color: textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: textColor),
          contentPadding: EdgeInsets.only(left: 12.h, top: 15.h),
          hintText: hintText,
          hintStyle: AppStyle.fTextStyle.copyWith(color: textColor),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          // Will be null if not provided
          errorText: errorText,
          errorMaxLines: 3,
          errorStyle: AppStyle.pTextStyle.copyWith(
            color: redColor,

            height: 1.2,
          ),
        ),
      ),
    );
  }
}
