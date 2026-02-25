// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:minio/minio.dart';
import 'package:minio/src/minio_models_generated.dart' as minio_models;

import 'test_config.dart';

final _log = Logger('email_helper');

const _maxRetries = 60; // 12 * 5 = 60 retries
const _retryDelay = Duration(seconds: 5);

class EmailHelper {
  final TestConfig _config = TestConfig();
  late final Minio _minio;

  EmailHelper() {
    _minio = Minio(
      endPoint: 's3.${_config.awsRegion}.amazonaws.com',
      accessKey: _config.awsS3AccessKeyId,
      secretKey: _config.awsS3SecretAccessKey,
      region: _config.awsRegion,
      useSSL: true,
    );
  }

  /// Polls S3 for a verification email and extracts the verification code.
  ///
  /// [username] is the email address used during signup (URL-encoded in the verification link).
  /// Returns the verification code, or throws if not found within timeout.
  Future<String> getVerificationCode(String username, {int retry = 0}) async {
    _log.info('Polling for verification email (attempt ${retry + 1}/$_maxRetries)');

    try {
      // List objects in the inbound email prefix
      final results = await _minio.listObjects(
        _config.s3BucketName,
        prefix: 'inbound.email/heliumedu-cluster/',
      ).toList();

      // Flatten all objects from all results
      final allObjects = <minio_models.Object>[];
      for (final result in results) {
        allObjects.addAll(result.objects);
      }

      if (allObjects.isEmpty) {
        return _retryOrFail(username, retry, 'No emails found in bucket');
      }

      // Find the latest object by last modified time
      minio_models.Object? latestObject;
      DateTime? latestModified;
      for (final obj in allObjects) {
        if (obj.key == null) continue;
        if (latestModified == null ||
            (obj.lastModified != null && obj.lastModified!.isAfter(latestModified))) {
          latestObject = obj;
          latestModified = obj.lastModified;
        }
      }

      if (latestObject == null || latestObject.key == null) {
        return _retryOrFail(username, retry, 'No valid email objects found');
      }

      _log.info('Found latest email: ${latestObject.key}');

      // Get the email content
      final stream = await _minio.getObject(_config.s3BucketName, latestObject.key!);
      final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
      final emailStr = utf8.decode(bytes);

      // Parse email to extract date and body
      final parseResult = _parseEmail(emailStr);
      final emailDate = parseResult.date;
      final emailBody = parseResult.body;

      // Check if email is within the test window
      final now = DateTime.now().toUtc();
      final windowPadding = Duration(seconds: 15 + (retry * _retryDelay.inSeconds));
      final leftWindow = now.subtract(windowPadding);
      final rightWindow = now.add(windowPadding);

      _log.info('Left window: $leftWindow');
      _log.info('Email date: $emailDate');
      _log.info('Right window: $rightWindow');

      final inTestWindow = emailDate != null &&
          emailDate.isAfter(leftWindow) &&
          emailDate.isBefore(rightWindow);

      // Verify this email is for our user and is recent
      // The verification URL uses just the local part of the email (before @), not URL-encoded
      final localPart = username.split('@').first;
      final usernamePattern = 'username=$localPart&code';
      final isForOurUser = emailBody?.contains(usernamePattern) ?? false;

      if (!inTestWindow || !isForOurUser || emailBody == null) {
        final reason = !inTestWindow
            ? 'Email outside test window'
            : !isForOurUser
                ? 'Email not for user $username'
                : 'No email body';
        return _retryOrFail(username, retry, reason);
      }

      // Extract verification code from the URL
      // The verification URL uses just the local part of the email (before @), not URL-encoded
      final verifyPattern = 'verify?username=$localPart&code=';
      final codeStart = emailBody.indexOf(verifyPattern);
      if (codeStart == -1) {
        return _retryOrFail(username, retry, 'Verification URL not found in email');
      }

      final codeStartIndex = codeStart + verifyPattern.length;
      final codeEndIndex = emailBody.indexOf('\n', codeStartIndex);
      final verificationCode = emailBody
          .substring(codeStartIndex, codeEndIndex == -1 ? null : codeEndIndex)
          .trim();

      _log.info('Extracted verification code: $verificationCode');

      // Delete the email object after successful extraction
      await _minio.removeObject(_config.s3BucketName, latestObject.key!);
      _log.info('Deleted email object: ${latestObject.key}');

      return verificationCode;
    } catch (e) {
      _log.warning('Error during email fetch: $e');
      return _retryOrFail(username, retry, 'Error: $e');
    }
  }

  Future<String> _retryOrFail(String username, int retry, String reason) async {
    if (retry < _maxRetries) {
      _log.info('$reason. Retrying in ${_retryDelay.inSeconds}s...');
      await Future.delayed(_retryDelay);
      return getVerificationCode(username, retry: retry + 1);
    }
    throw Exception(
      'No matching verification email found after ${_maxRetries * _retryDelay.inSeconds} seconds. Last reason: $reason',
    );
  }

  /// Parses a raw email string to extract date and plain text body.
  _EmailParseResult _parseEmail(String emailStr) {
    DateTime? emailDate;
    String? emailBody;

    // Simple email parsing - look for Date header and text/plain content
    final lines = emailStr.split('\n');
    bool inBody = false;
    bool inPlainText = false;
    final bodyLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Parse Date header
      if (line.startsWith('Date: ') && emailDate == null) {
        try {
          final dateStr = line.substring(6).trim();
          emailDate = _parseRfc2822Date(dateStr);
        } catch (e) {
          _log.warning('Failed to parse date: $e');
        }
      }

      // Detect content type boundaries
      if (line.contains('Content-Type: text/plain')) {
        inPlainText = true;
        inBody = false;
        continue;
      }
      if (line.contains('Content-Type:') && !line.contains('text/plain')) {
        inPlainText = false;
      }

      // After blank line following Content-Type, we're in the body
      if (inPlainText && line.trim().isEmpty && !inBody) {
        inBody = true;
        continue;
      }

      // Detect boundary markers
      if (line.startsWith('--') && inBody) {
        inBody = false;
        inPlainText = false;
      }

      if (inBody && inPlainText) {
        bodyLines.add(line);
      }
    }

    if (bodyLines.isNotEmpty) {
      emailBody = bodyLines.join('\n');
    }

    return _EmailParseResult(date: emailDate, body: emailBody);
  }

  /// Parse RFC 2822 date format (e.g., "Mon, 24 Feb 2025 10:30:00 +0000")
  DateTime? _parseRfc2822Date(String dateStr) {
    try {
      // Remove day name if present
      var cleaned = dateStr;
      if (cleaned.contains(',')) {
        cleaned = cleaned.substring(cleaned.indexOf(',') + 1).trim();
      }

      // Parse: "24 Feb 2025 10:30:00 +0000"
      final parts = cleaned.split(' ');
      if (parts.length < 5) return null;

      final day = int.parse(parts[0]);
      final month = _monthFromString(parts[1]);
      final year = int.parse(parts[2]);
      final timeParts = parts[3].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      // Parse timezone offset
      final tzOffset = parts[4];
      final tzSign = tzOffset.startsWith('-') ? -1 : 1;
      final tzHours = int.parse(tzOffset.substring(1, 3));
      final tzMinutes = int.parse(tzOffset.substring(3, 5));
      final offsetDuration = Duration(hours: tzHours, minutes: tzMinutes) * tzSign;

      final utcTime = DateTime.utc(year, month, day, hour, minute, second);
      return utcTime.subtract(offsetDuration);
    } catch (e) {
      _log.warning('Failed to parse RFC 2822 date "$dateStr": $e');
      return null;
    }
  }

  int _monthFromString(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[month] ?? 1;
  }
}

class _EmailParseResult {
  final DateTime? date;
  final String? body;

  _EmailParseResult({this.date, this.body});
}
