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

  /// AWS region for S3 access
  /// Matches Terraform: dev-local uses us-east-2, all others use us-east-1
  String get awsRegion => environment == 'dev-local' ? 'us-east-2' : 'us-east-1';

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

  /// AWS S3 access key for email verification
  String get awsS3AccessKeyId =>
      const String.fromEnvironment('AWS_S3_ACCESS_KEY_ID');

  /// AWS S3 secret key for email verification
  String get awsS3SecretAccessKey =>
      const String.fromEnvironment('AWS_S3_SECRET_ACCESS_KEY');

  /// S3 bucket name for inbound emails
  /// Format: heliumedu.{environment}
  String get s3BucketName => 'heliumedu.$environment';

  /// Email domain for test users
  /// SES receipt rule stores at: inbound.email/heliumedu-cluster/
  String get emailDomain => '${_envPrefix}heliumedu.dev';

  /// Consistent test email address for CI
  /// Only one integration test run is allowed at a time to avoid user pollution
  String get testEmail => 'heliumedu-cluster+3@$emailDomain';

  /// Consistent test password for CI
  String get testPassword => 'IntegrationTestPassword123!';

  bool get isDevLocal => environment == 'dev-local';
}
