// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:helium_mobile/utils/app_colors.dart';
import 'package:helium_mobile/utils/app_size.dart';
import 'package:helium_mobile/utils/app_text_style.dart';
import 'package:intl/intl.dart';

class CustomCalendarTextfield extends StatefulWidget {
  const CustomCalendarTextfield({
    super.key,
    required this.text,
    this.onDateSelected,
    this.initialDate,
  });

  final String text;
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;

  @override
  State<CustomCalendarTextfield> createState() =>
      _CustomCalendarTextfieldState();
}

class _CustomCalendarTextfieldState extends State<CustomCalendarTextfield> {
  DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = DateFormat('MMM dd, yyyy').format(_selectedDate!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // header background color
              onPrimary: whiteColor, // header text color
              onSurface: blackColor, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('MMM dd, yyyy').format(picked);
      });

      // Call the callback function if provided
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(picked);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.adaptSize),
        border: Border.all(color: blackColor.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: _controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        style: AppTextStyle.eTextStyle.copyWith(color: blackColor),
        decoration: InputDecoration(
          hintText: widget.text,
          hintStyle: AppTextStyle.eTextStyle.copyWith(
            color: blackColor.withOpacity(0.5),
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.calendar_today,
            color: blackColor.withOpacity(0.6),
            size: 20,
          ),
        ),
      ),
    );
  }
}
