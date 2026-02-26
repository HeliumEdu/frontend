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

      _log.info('Found ${allObjects.length} email(s) in bucket');

      // Calculate time windows using UTC for consistency across environments
      final nowUtc = DateTime.now().toUtc();
      final windowPadding = Duration(seconds: 30 + (retry * _retryDelay.inSeconds));
      final windowStart = nowUtc.subtract(windowPadding);
      final staleThreshold = nowUtc.subtract(const Duration(minutes: 10));

      // The verification URL uses just the local part of the email (before @)
      final localPart = username.split('@').first;
      final usernamePattern = 'username=$localPart&code';
      final verifyPattern = 'verify?username=$localPart&code=';

      // Look for our email
      for (final obj in allObjects) {
        if (obj.key == null || obj.lastModified == null) continue;

        // Use S3's lastModified (always UTC) for time window check
        final s3Timestamp = obj.lastModified!;
        final inTestWindow = s3Timestamp.isAfter(windowStart);

        if (!inTestWindow) {
          // Skip old emails without fetching content
          continue;
        }

        // Get the email content
        final stream = await _minio.getObject(_config.s3BucketName, obj.key!);
        final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        final emailStr = utf8.decode(bytes);

        // Parse email to extract body
        final emailBody = _parseEmailBody(emailStr);
        final isForOurUser = emailBody?.contains(usernamePattern) ?? false;

        if (isForOurUser) {
          // Found our email - extract the code
          _log.info('Found matching email: ${obj.key} (S3 timestamp: $s3Timestamp)');

          final codeStart = emailBody!.indexOf(verifyPattern);
          if (codeStart == -1) {
            _log.warning('Email matched but verification URL not found, skipping');
            continue;
          }

          final codeStartIndex = codeStart + verifyPattern.length;
          final codeEndIndex = emailBody.indexOf('\n', codeStartIndex);
          final verificationCode = emailBody
              .substring(codeStartIndex, codeEndIndex == -1 ? null : codeEndIndex)
              .trim();

          _log.info('Extracted verification code: $verificationCode');

          // Delete our email
          await _minio.removeObject(_config.s3BucketName, obj.key!);
          _log.info('Deleted matching email: ${obj.key}');

          // Clean up old emails (>10 min) now that we succeeded
          await _cleanupOldEmails(allObjects, staleThreshold);

          return verificationCode;
        }
      }

      // No matching email found - don't touch anything, just retry
      return _retryOrFail(username, retry, 'No matching email found');
    } catch (e) {
      _log.warning('Error during email fetch: $e');
      return _retryOrFail(username, retry, 'Error: $e');
    }
  }

  Future<String> _retryOrFail(String username, int retry, String reason) async {
    if (retry < _maxRetries) {
      _log.info('$reason. Retrying in ${_retryDelay.inSeconds}s ...');
      await Future.delayed(_retryDelay);
      return getVerificationCode(username, retry: retry + 1);
    }
    throw Exception(
      'No matching verification email found after ${_maxRetries * _retryDelay.inSeconds} seconds. Last reason: $reason',
    );
  }

  /// Cleans up old emails (>10 min) after successfully finding our email.
  Future<void> _cleanupOldEmails(
    List<minio_models.Object> allObjects,
    DateTime staleThreshold,
  ) async {
    var cleanedCount = 0;
    for (final obj in allObjects) {
      if (obj.key == null || obj.lastModified == null) continue;

      // Use S3 object's lastModified for simple staleness check
      if (obj.lastModified!.isBefore(staleThreshold)) {
        await _minio.removeObject(_config.s3BucketName, obj.key!);
        cleanedCount++;
      }
    }
    if (cleanedCount > 0) {
      _log.info('Cleaned up $cleanedCount old email(s)');
    }
  }

  /// Parses a raw email string to extract the plain text body.
  String? _parseEmailBody(String emailStr) {
    // Simple email parsing - look for text/plain content
    final lines = emailStr.split('\n');
    bool inBody = false;
    bool inPlainText = false;
    final bodyLines = <String>[];

    for (final line in lines) {
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

    return bodyLines.isNotEmpty ? bodyLines.join('\n') : null;
  }
}
