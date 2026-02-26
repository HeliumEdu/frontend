// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:logging/logging.dart';

/// ANSI color codes for log levels.
class LogColors {
  static const String shout = '\x1B[31m'; // Dark red
  static const String severe = '\x1B[91m'; // Light red
  static const String warning = '\x1B[33m'; // Yellow
  static const String info = '\x1B[36m'; // Cyan
  static const String debug = '\x1B[90m'; // Grey
  static const String reset = '\x1B[0m';
  static const String green = '\x1B[32m'; // Green (for success)

  /// Get the color code for a log level.
  static String forLevel(Level level) {
    if (level >= Level.SHOUT) {
      return shout;
    } else if (level >= Level.SEVERE) {
      return severe;
    } else if (level >= Level.WARNING) {
      return warning;
    } else if (level >= Level.INFO) {
      return info;
    } else {
      return debug;
    }
  }
}

/// Formats a log record for console output with colors.
class LogFormatter {
  /// Format a log record with colors.
  static String format(LogRecord record, {bool includeLoggerName = true}) {
    final colorCode = LogColors.forLevel(record.level);
    const resetCode = LogColors.reset;

    final buffer = StringBuffer();
    if (includeLoggerName) {
      buffer.write(
        '$colorCode${record.level.name}$resetCode: ${record.time}: [${record.loggerName}] ${record.message}',
      );
    } else {
      buffer.write(
        '$colorCode${record.level.name}$resetCode: ${record.time}: ${record.message}',
      );
    }

    if (record.error != null) {
      buffer.write('\n${colorCode}Error$resetCode: ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\n${colorCode}Stack Trace:$resetCode\n${record.stackTrace}');
    }

    return buffer.toString();
  }

  /// Format a simple message with a color.
  static String colorize(String message, String colorCode) {
    return '$colorCode$message${LogColors.reset}';
  }
}
