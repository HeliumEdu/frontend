// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

final List<Color> colorsList = [
  const Color(0xffFD7E14), // orangeColor
  const Color(0xff007BFF), // primaryColor
  const Color(0xff28A745), // greenColor
  const Color(0xffFFC107), // yellowColor
  const Color(0xffDC3545), // redColor
];
const List<String> listOfClassesSchedule = [
  'Mon',
  'Tue',
  'Wed',
  'Thur',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> defaultPreferences = ["Month", "Week", "Day", "Todos"];
final List<String> timezonesPreference = [
  'Asia/Karachi',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Shanghai',
  'Asia/Tokyo',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'America/New_York',
  'America/Los_Angeles',
  'America/Chicago',
  'Australia/Sydney',
  'Australia/Melbourne',
];
const List<String> reminderPreferences = ["Popup", "Email", "Text", "Push"];
const List<String> reminderTimeUnits = ["Minutes", "Hours", "Days", "Weeks"];
const List<String> viewList = ["Month", "Week", "Day", "Todos"];

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = "s"]) {
    return (this == 0 || this > 1)
        ? "$singularWord$pluralLetters"
        : "$singularWord";
  }
}