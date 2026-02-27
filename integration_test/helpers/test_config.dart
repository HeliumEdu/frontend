// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Configuration for integration tests.
class TestConfig {
  static final TestConfig _instance = TestConfig._internal();
  factory TestConfig() => _instance;
  TestConfig._internal();

  /// Environment: 'dev', 'dev-local', etc. (prod not supported for integration tests)
  String get environment =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev-local');

  /// Environment prefix for URLs.
  /// e.g., dev -> "dev.", dev-local -> "dev-local.", prod -> ""
  String get _envPrefix => environment == 'prod' ? '' : '$environment.';

  /// AWS region for S3 integration bucket (always us-east-2, where the bucket is created)
  String get awsRegion => 'us-east-2';

  /// Frontend app host
  String get projectAppHost {
    if (environment == 'dev-local') return 'http://localhost:8080';
    return 'https://app.${_envPrefix}heliumedu.com';
  }

  /// Backend API host
  String get projectApiHost {
    if (environment == 'dev-local') return 'http://localhost:8000';
    return 'https://api.${_envPrefix}heliumedu.com';
  }

  /// AWS S3 access key for email verification (shared integration bucket)
  String get awsS3AccessKeyId =>
      const String.fromEnvironment('AWS_INTEGRATION_S3_ACCESS_KEY_ID');

  /// AWS S3 secret key for email verification (shared integration bucket)
  String get awsS3SecretAccessKey =>
      const String.fromEnvironment('AWS_INTEGRATION_S3_SECRET_ACCESS_KEY');

  /// S3 bucket name for inbound emails (shared across all environments)
  String get s3BucketName => 'heliumedu-integration';

  /// S3 object key prefix for this environment's emails
  /// SES receipt rule stores at: {environment}/inbound.email/heliumedu-cluster/
  String get s3ObjectKeyPrefix => '$environment/inbound.email/heliumedu-cluster/';

  /// Email domain for test users
  /// SES receipt rule stores at: inbound.email/heliumedu-cluster/
  String get emailDomain => '${_envPrefix}heliumedu.dev';

  /// Email suffix for test accounts (reuse to avoid test account pollution)
  String get emailSuffix =>
      const String.fromEnvironment('INTEGRATION_EMAIL_SUFFIX', defaultValue: 'integration');

  /// Test email address: heliumedu-cluster-{emailSuffix}@{emailDomain}
  String get testEmail => 'heliumedu-cluster+$emailSuffix@$emailDomain';

  /// Consistent test password for CI
  String get testPassword => 'IntegrationTestPassword123!';

  bool get isDevLocal => environment == 'dev-local';
}
