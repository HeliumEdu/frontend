// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_core/localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class HeliumSfLocalizationsDelegate
    extends LocalizationsDelegate<SfLocalizations> {
  const HeliumSfLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<SfLocalizations> load(Locale locale) =>
      SynchronousFuture(const _HeliumSfLocalizations());

  @override
  bool shouldReload(covariant LocalizationsDelegate<SfLocalizations> old) =>
      false;
}

class _HeliumSfLocalizations extends SfLocalizationsEn {
  const _HeliumSfLocalizations();

  @override
  String get noEventsCalendarLabel => 'Nothing to see here';

  @override
  String get noSelectedDateCalendarLabel => 'Select a date to get started';
}
