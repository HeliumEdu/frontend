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
  ///
  /// Matches the Python cluster-tests logic: find the most recent email first,
  /// then validate it matches our criteria.
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

      // Find the most recent email by S3 lastModified (matches Python logic)
      minio_models.Object? latestObj;
      for (final obj in allObjects) {
        if (obj.key == null || obj.lastModified == null) continue;
        if (latestObj == null || obj.lastModified!.isAfter(latestObj.lastModified!)) {
          latestObj = obj;
        }
      }

      if (latestObj == null) {
        return _retryOrFail(username, retry, 'No valid emails found');
      }

      final s3Timestamp = latestObj.lastModified!;
      _log.info('Latest email: ${latestObj.key} (S3 timestamp: $s3Timestamp)');

      // Get the email content
      final stream = await _minio.getObject(_config.s3BucketName, latestObj.key!);
      final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
      final emailStr = utf8.decode(bytes);

      // Parse email to extract body
      final emailBody = _parseEmailBody(emailStr);

      // Calculate time window (matches Python: ±(15 + retry * 5) seconds)
      final nowUtc = DateTime.now().toUtc();
      final windowPadding = Duration(seconds: 15 + (retry * _retryDelay.inSeconds));
      final leftWindow = nowUtc.subtract(windowPadding);
      final rightWindow = nowUtc.add(windowPadding);
      final staleThreshold = nowUtc.subtract(const Duration(minutes: 10));

      _log.fine('leftWindow: $leftWindow');
      _log.fine('s3Timestamp: $s3Timestamp');
      _log.fine('rightWindow: $rightWindow');

      // Validate: in time window, for our user, and has verification code
      final localPart = username.split('@').first;
      final usernamePattern = 'username=$localPart&code';
      final verifyPattern = 'verify?username=$localPart&code=';

      final inTestWindow = !s3Timestamp.isBefore(leftWindow) && s3Timestamp.isBefore(rightWindow);
      final isForOurUser = emailBody?.contains(usernamePattern) ?? false;
      final hasVerifyUrl = emailBody?.contains(verifyPattern) ?? false;

      if (!inTestWindow || !isForOurUser || !hasVerifyUrl) {
        final reason = !inTestWindow
            ? 'Email outside time window'
            : !isForOurUser
                ? 'Email not for our user'
                : 'Email missing verification URL';
        return _retryOrFail(username, retry, reason);
      }

      // Extract the verification code
      final codeStart = emailBody!.indexOf(verifyPattern);
      final codeStartIndex = codeStart + verifyPattern.length;
      final codeEndIndex = emailBody.indexOf('\n', codeStartIndex);
      final verificationCode = emailBody
          .substring(codeStartIndex, codeEndIndex == -1 ? null : codeEndIndex)
          .trim();

      _log.info('Extracted verification code: $verificationCode');

      // Delete our email
      await _minio.removeObject(_config.s3BucketName, latestObj.key!);
      _log.info('Deleted matching email: ${latestObj.key}');

      // Clean up old emails (>10 min) now that we succeeded
      await _cleanupOldEmails(allObjects, staleThreshold);

      return verificationCode;
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
