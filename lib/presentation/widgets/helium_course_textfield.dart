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

class HeliumCourseTextField extends StatelessWidget {
  const HeliumCourseTextField({super.key, required this.text, this.controller, this.focusNode});

  final String text;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.adaptSize),
        border: Border.all(color: blackColor.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: AppStyle.eTextStyle.copyWith(color: blackColor),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: AppStyle.eTextStyle.copyWith(
            color: blackColor.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
