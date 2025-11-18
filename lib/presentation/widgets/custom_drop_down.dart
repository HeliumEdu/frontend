import 'package:flutter/material.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';

class CustomDropdown extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: textColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: textColor),
          contentPadding: EdgeInsets.only(left: 12.h, top: 14.h, right: 12.h),
          hintText: hintText,
          hintStyle: AppTextStyle.fTextStyle.copyWith(color: textColor),
          border: InputBorder.none,
        ),
        style: AppTextStyle.fTextStyle.copyWith(color: textColor),
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down, color: textColor),
        isExpanded: true,
        items: items.map((String timezone) {
          return DropdownMenuItem<String>(
            value: timezone,
            child: Text(
              timezone.replaceAll('_', ' '),
              style: AppTextStyle.fTextStyle.copyWith(color: textColor),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
