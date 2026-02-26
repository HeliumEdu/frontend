// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/log_formatter.dart';
import 'package:logging/logging.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() => _instance;

  LogService._internal();

  void init() {
    // Use --dart-define=LOG_LEVEL=FINE to set a log level in development
    const logLevelName = String.fromEnvironment(
      'LOG_LEVEL',
      defaultValue: 'INFO',
    );
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == logLevelName.toUpperCase(),
      orElse: () => Level.INFO,
    );

    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print(LogFormatter.format(record));
    });
  }
}
