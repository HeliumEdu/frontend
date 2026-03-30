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

const _retryDelay = Duration(seconds: 5);
const _defaultTimeoutMinutes = 5;
const _maxTimeoutMinutes = 30;

int get _timeoutMinutes {
  const envValue = String.fromEnvironment('EMAIL_POLL_TIMEOUT_MINUTES');
  if (envValue.isEmpty) return _defaultTimeoutMinutes;
  final parsed = int.tryParse(envValue);
  if (parsed == null || parsed < 1) return _defaultTimeoutMinutes;
  if (parsed > _maxTimeoutMinutes) return _maxTimeoutMinutes;
  return parsed;
}

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
  /// [sentAfter] is the timestamp before the email-triggering action was initiated.
  ///   Emails must have S3 timestamp >= sentAfter to be considered.
  /// Returns the verification code.
  ///
  /// Timeout defaults to 5 minutes for local runs. Set EMAIL_POLL_TIMEOUT_MINUTES
  /// env var to override (max 30 minutes) for CI with high concurrency.
  Future<String> getVerificationCode(
    String username, {
    required DateTime sentAfter,
    DateTime? startedAt,
    int attempt = 0,
  }) async {
    startedAt ??= DateTime.now();
    final timeout = Duration(minutes: _timeoutMinutes);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed > timeout) {
      throw Exception(
        'No matching verification email found after ${elapsed.inMinutes} minutes '
        '(timeout: $_timeoutMinutes min). Checked $attempt attempts.',
      );
    }
    _log.info('Polling for verification email for $username (attempt ${attempt + 1})');
    try {
      // List objects in the inbound email prefix (environment-specific)
      final results = await _minio.listObjects(
        _config.s3BucketName,
        prefix: _config.s3ObjectKeyPrefix,
      ).toList();

      // Flatten all objects from all results
      final allObjects = <minio_models.Object>[];
      for (final result in results) {
        allObjects.addAll(result.objects);
      }

      if (allObjects.isEmpty) {
        return _retry(username, sentAfter, startedAt, attempt, 'No emails found in bucket');
      }

      _log.info('Found ${allObjects.length} email(s) in bucket');

      // Sort by newest first so we check recent emails before older ones
      final validObjects = allObjects
          .where((obj) => obj.key != null && obj.lastModified != null)
          .toList()
        ..sort((a, b) => b.lastModified!.compareTo(a.lastModified!));

      if (validObjects.isEmpty) {
        return _retry(username, sentAfter, startedAt, attempt, 'No valid emails found');
      }

      // URL-encode the username since the email template uses urlencode filter
      final encodedUsername = Uri.encodeComponent(username);
      final verifyPattern = 'verify?email=$encodedUsername&code=';

      // Check each email (newest first) looking for one that matches our user
      for (final obj in validObjects) {
        final s3Timestamp = obj.lastModified!;

        // Skip emails that arrived before our action was triggered
        if (s3Timestamp.isBefore(sentAfter)) {
          _log.fine('Skipping ${obj.key} - arrived before action triggered');
          continue;
        }

        // Get the email content
        final stream = await _minio.getObject(_config.s3BucketName, obj.key!);
        final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        final emailStr = utf8.decode(bytes);

        // Parse email to extract body
        final emailBody = _parseEmailBody(emailStr);
        if (emailBody == null || !emailBody.contains(verifyPattern)) {
          _log.fine('Skipping ${obj.key} - not for our user');
          continue;
        }

        // Found our email - extract the verification code
        _log.info('Found matching email: ${obj.key} (S3 timestamp: $s3Timestamp)');

        final codeStart = emailBody.indexOf(verifyPattern);
        final codeStartIndex = codeStart + verifyPattern.length;
        final codeEndIndex = emailBody.indexOf('\n', codeStartIndex);
        final verificationCode = emailBody
            .substring(codeStartIndex, codeEndIndex == -1 ? null : codeEndIndex)
            .trim();

        _log.info('Extracted verification code: $verificationCode');

        // Delete our email
        await _minio.removeObject(_config.s3BucketName, obj.key!);
        _log.info('Deleted matching email: ${obj.key}');

        return verificationCode;
      }

      // No matching email found in this pass
      return _retry(username, sentAfter, startedAt, attempt, 'No email found for our user');
    } catch (e) {
      _log.warning('Error during email fetch: $e');
      return _retry(username, sentAfter, startedAt, attempt, 'Error: $e');
    }
  }

  Future<String> _retry(
    String username,
    DateTime sentAfter,
    DateTime startedAt,
    int attempt,
    String reason,
  ) async {
    _log.info('$reason. Retrying in ${_retryDelay.inSeconds}s ...');
    await Future.delayed(_retryDelay);
    return getVerificationCode(
      username,
      sentAfter: sentAfter,
      startedAt: startedAt,
      attempt: attempt + 1,
    );
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
