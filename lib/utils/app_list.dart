// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.



const List<String> listOfClassesSchedule = [
  'Mon',
  'Tue',
  'Wed',
  'Thur',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> mobileViews = ["Month", "Week", "Day", "Todos"];
final List<String> timeZones = [
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
const List<String> reminderTypes = ["Popup", "Email"];
const List<String> reminderOffsetUnits = ["Minutes", "Hours", "Days", "Weeks"];

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = "s"]) {
    return (this == 0 || this > 1)
        ? "$singularWord$pluralLetters"
        : "$singularWord";
  }
}
