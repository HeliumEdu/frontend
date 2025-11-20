import 'package:flutter/material.dart';
import 'package:helium_student_flutter/utils/app_colors.dart';
import 'package:helium_student_flutter/utils/app_size.dart';
import 'package:helium_student_flutter/utils/app_text_style.dart';

class CustomTimeTextField extends StatefulWidget {
  final String text;
  final Function(TimeOfDay)? onTimeSelected;

  const CustomTimeTextField({super.key, required this.text, this.onTimeSelected});

  @override
  State<CustomTimeTextField> createState() => _CustomTimeTextFieldState();
}

class _CustomTimeTextFieldState extends State<CustomTimeTextField> {
  TimeOfDay? selectedTime;

  void _showCustomTimePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: whiteColor,
          child: const CustomTimePicker(),
        );
      },
    ).then((time) {
      if (time != null && time is TimeOfDay) {
        setState(() {
          selectedTime = time;
        });
        if (widget.onTimeSelected != null) {
          widget.onTimeSelected!(time);
        }
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCustomTimePicker,
      child: Container(
        height: 50.v,
        padding: EdgeInsets.symmetric(horizontal: 12.h),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedTime != null ? _formatTime(selectedTime!) : widget.text,
              style: AppTextStyle.cTextStyle.copyWith(
                color: selectedTime != null
                    ? blackColor
                    : blackColor.withOpacity(0.5),
              ),
            ),
            Icon(Icons.access_time, color: greyColor, size: 20.adaptSize),
          ],
        ),
      ),
    );
  }
}

class CustomTimePicker extends StatefulWidget {
  const CustomTimePicker({super.key});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;

  int selectedHour = 9;
  int selectedMinute = 30;
  int selectedPeriod = 1; // 0 = AM, 1 = PM

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(
      initialItem: selectedHour - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );
    _periodController = FixedExtentScrollController(
      initialItem: selectedPeriod,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Picker
              _buildTimeUnit(
                controller: _hourController,
                itemCount: 12,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedHour = index + 1;
                  });
                },
                builder: (index) => (index + 1).toString().padLeft(2, '0'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              // Minute Picker
              _buildTimeUnit(
                controller: _minuteController,
                itemCount: 60,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedMinute = index;
                  });
                },
                builder: (index) => index.toString().padLeft(2, '0'),
              ),
              const SizedBox(width: 16),
              // AM/PM Picker
              _buildTimeUnit(
                controller: _periodController,
                itemCount: 2,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedPeriod = index;
                  });
                },
                builder: (index) => index == 0 ? 'AM' : 'PM',
                width: 60,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: greyColor),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  int hour = selectedHour;
                  if (selectedPeriod == 1 && hour != 12) {
                    hour += 12;
                  } else if (selectedPeriod == 0 && hour == 12) {
                    hour = 0;
                  }
                  Navigator.pop(
                    context,
                    TimeOfDay(hour: hour, minute: selectedMinute),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: whiteColor,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) builder,
    double width = 70,
  }) {
    return Container(
      width: width,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Selection highlight
          Center(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // Scroll wheel
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    builder(index),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
          // Up arrow
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (controller.selectedItem > 0) {
                  controller.animateToItem(
                    controller.selectedItem - 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade600),
            ),
          ),
          // Down arrow
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (controller.selectedItem < itemCount - 1) {
                  controller.animateToItem(
                    controller.selectedItem + 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
