// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:timezone/standalone.dart' as tz;

const List<String> dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thurday',
  'Friday',
  'Saturday',
];

const List<String> dayNamesAbbrev = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

const List<String> mobileViews = ['Month', 'Week', 'Day', 'Todos'];
const List<String> reminderTypes = ['Popup', 'Email', 'Text'];
const List<String> reminderOffsetUnits = ['Minutes', 'Hours', 'Days', 'Weeks'];

final List<String> materialStatus = [
  'Owned',
  'Rented',
  'Ordered',
  'Shipped',
  'Needed',
  'Returned',
  'To Sell',
  'Digital',
];

final List<String> materialCondition = [
  'Brand New',
  'Refurbished',
  'Used - Like New',
  'Used - Very Good',
  'Used - Good',
  'Used - Acceptable',
  'Used - Poor',
  'Broken',
  'Digital',
];

extension PluralExtension on int {
  String plural(String singularWord, [String pluralLetters = 's']) {
    return (this == 0 || this > 1)
        ? '$singularWord$pluralLetters'
        : singularWord;
  }
}

List<String> populateTimeZones() {
  final allLocations = tz.timeZoneDatabase.locations.keys;
  final allTimeZones = allLocations.where((id) => id.contains('/')).toList();
  allTimeZones.add('Etc/UTC');
  return allTimeZones
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
