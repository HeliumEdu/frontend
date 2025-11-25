// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.



const List<String> listOfDays = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thur',
  'Fri',
  'Sat',
];

const List<String> mobileViews = ["Month", "Week", "Day", "Todos"];
const List<String> reminderTypes = ["Popup", "Email"];
const List<String> reminderOffsetUnits = ["Minutes", "Hours", "Days", "Weeks"];

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = "s"]) {
    return (this == 0 || this > 1)
        ? "$singularWord$pluralLetters"
        : "$singularWord";
  }
}
