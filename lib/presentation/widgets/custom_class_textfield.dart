// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';
import 'package:heliumedu/utils/app_text_style.dart';

class CustomClassTextField extends StatelessWidget {
  const CustomClassTextField({super.key, required this.text, this.controller});

  final String text;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.adaptSize),
        border: Border.all(color: blackColor.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        style: AppTextStyle.eTextStyle.copyWith(color: blackColor),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: AppTextStyle.eTextStyle.copyWith(
            color: blackColor.withOpacity(0.5),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
