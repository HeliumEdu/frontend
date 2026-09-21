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
  String get s3ObjectKeyPrefix =>
      '$environment/inbound.email/heliumedu-cluster/';

  /// Email domain for test users
  /// SES receipt rule stores at: inbound.email/heliumedu-cluster/
  String get emailDomain => '${_envPrefix}heliumedu.dev';

  /// Email suffix for test accounts (reuse to avoid test account pollution).
  /// To use your local username, pass it at compile time:
  ///   --dart-define=INTEGRATION_EMAIL_SUFFIX=$USER
  String get emailSuffix =>
      const String.fromEnvironment(
        'INTEGRATION_EMAIL_SUFFIX',
        defaultValue: 'integration',
      );

  /// Test email address: heliumedu-cluster-{emailSuffix}@{emailDomain}
  String get testEmail => 'heliumedu-cluster+$emailSuffix@$emailDomain';

  /// Consistent test password for CI
  String get testPassword => 'IntegrationTestPassword123!';

  bool get isDevLocal => environment == 'dev-local';

  /// The region the browser is running as (runner `TZ` + `--accept-lang`),
  /// which decides what signup and setup are expected to detect.
  IntegrationRegion get region => IntegrationRegion.values.byName(
        const String.fromEnvironment('INTEGRATION_REGION', defaultValue: 'us'),
      );

  /// Timeout for operations that depend on an API response (network round-trip
  /// to the backend).
  Duration get apiTimeout => const Duration(seconds: 30);
}

/// What each runner region's browser detects, and whether signup overrides
/// the detected time zone (the US leg picks America/Chicago so the rest of
/// the full suite can assume it).
enum IntegrationRegion {
  us(
    languageCode: 'en',
    detectedTimeZone: 'America/Los_Angeles',
    signupTimeZoneOverride: 'America/Chicago',
    weekStartsOn: 0,
    dateFormat: 0,
    timeFormat: 0,
    numberFormat: 0,
    atRiskThreshold: 70,
  ),
  de(
    languageCode: 'de',
    detectedTimeZone: 'Europe/Berlin',
    signupTimeZoneOverride: null,
    weekStartsOn: 1,
    dateFormat: 1,
    timeFormat: 1,
    numberFormat: 1,
    atRiskThreshold: 60,
  );

  final String languageCode;
  final String detectedTimeZone;
  final String? signupTimeZoneOverride;
  final int weekStartsOn;
  final int dateFormat;
  final int timeFormat;
  final int numberFormat;
  final int atRiskThreshold;

  const IntegrationRegion({
    required this.languageCode,
    required this.detectedTimeZone,
    required this.signupTimeZoneOverride,
    required this.weekStartsOn,
    required this.dateFormat,
    required this.timeFormat,
    required this.numberFormat,
    required this.atRiskThreshold,
  });

  String get accountTimeZone => signupTimeZoneOverride ?? detectedTimeZone;
}
