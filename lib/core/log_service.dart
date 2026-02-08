// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
      final String colorCode;
      if (record.level >= Level.SHOUT) {
        colorCode = '\x1B[31m'; // Dark red
      } else if (record.level >= Level.SEVERE) {
        colorCode = '\x1B[91m'; // Light red
      } else if (record.level >= Level.WARNING) {
        colorCode = '\x1B[33m'; // Yellow
      } else if (record.level >= Level.INFO) {
        colorCode = '\x1B[36m'; // Cyan
      } else {
        colorCode = '\x1B[90m'; // Grey
      }
      const resetCode = '\x1B[0m';

      // ignore: avoid_print
      print(
        '$colorCode${record.level.name}$resetCode: ${record.time}: [${record.loggerName}] ${record.message}',
      );
      if (record.error != null) {
        // ignore: avoid_print
        print('${colorCode}Error$resetCode: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('${colorCode}Stack Trace:$resetCode\n${record.stackTrace}');
      }
    });
  }
}
