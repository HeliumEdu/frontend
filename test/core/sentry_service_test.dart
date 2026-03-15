// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('SentryService filtering', () {
    group('Real-world auth scenarios (via SentryException)', () {
      test('Wrong password on login - 401 DioException', () {
        // This is what Sentry captures when a DioException is thrown
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value:
                  'DioException [bad response]: This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.\n'
                  'The status code of 401 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"\n'
                  'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n'
                  'In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Wrong password 401 should be filtered');
      });

      test('Token expired - 401 with "Http status error" message', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'Http status error [401]',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Token expired 401 should be filtered');
      });

      test('Token blacklisted - 401', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value:
                  'DioException [bad response]: status code of 401, Token is blacklisted',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Blacklisted token 401 should be filtered');
      });

      test('User deleted - 403', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value:
                  'DioException [bad response]: This exception was thrown because the response has a status code of 403',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'User deleted 403 should be filtered');
      });

      test('Permission denied - 403 Forbidden', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'Http status error [403]',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Permission denied 403 should be filtered');
      });

      test('Verify endpoint - 400', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value:
                  'DioException [bad response]: /auth/user/verify/abc123 returned 400',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Verify 400 should be filtered');
      });
    });

    group('UnauthorizedException type filtering', () {
      test('Filters UnauthorizedException type', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'UnauthorizedException',
              value: 'Check your credentials and try again.',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue);
      });
    });

    group('Various 401 format patterns', () {
      test('status code of 401', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'response has a status code of 401',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('[401] bracket format', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'DioException [401]: Unauthorized',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('HTTP 401 format', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'HTTP 401 response from API',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('status 401 format', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'Request failed with status 401',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });
    });

    group('Various 403 format patterns', () {
      test('status code of 403', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'response has a status code of 403',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('[403] bracket format', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'DioException [403]: Forbidden',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('HTTP 403 format', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'HTTP 403 forbidden response',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });
    });

    group('Text-based filtering with message', () {
      test('Filters 401 in message with API context', () {
        final event = SentryEvent(
          message: SentryMessage('Request to API failed with status 401'),
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('Filters 403 in message with response context', () {
        final event = SentryEvent(
          message: SentryMessage('Response returned 403 forbidden'),
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });
    });

    group('Errors that should NOT be filtered', () {
      test('500 server error', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'status code of 500 Internal Server Error',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: '500 errors are bugs and should NOT be filtered');
      });

      test('404 not found', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'status code of 404 Not Found',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: '404 errors might indicate bugs');
      });

      test('400 validation on non-verify endpoint', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value:
                  'DioException [bad response]: /api/planner/courses/ returned 400',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Validation 400 on non-verify endpoints might be bugs');
      });

      test('Network timeout', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DioException',
              value: 'DioException [connection timeout]',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Network timeouts should NOT be filtered');
      });

      test('Generic exception', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'Something went wrong',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse);
      });

      test('Null pointer error', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'NoSuchMethodError',
              value: 'The method was called on null',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse);
      });

      test('401 in non-HTTP context (user ID)', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'User ID 14012 not found in database',
            ),
          ],
        );
        // No HTTP context words, should NOT be filtered
        expect(SentryService.shouldFilterEvent(event), isFalse);
      });
    });

    group('GoException wrapping DioException', () {
      test('GoException wrapping 403 DioException during redirect', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'GoException',
              value:
                  'GoException: Exception during redirect: DioException [bad response]: This exception was thrown because the response has a status code of 403 and RequestOptions.validateStatus was configured to throw for this status code.',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'GoException wrapping 403 DioException should be filtered');
      });

      test('GoException wrapping 401 DioException during redirect', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'GoException',
              value:
                  'GoException: Exception during redirect: DioException [bad response]: This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'GoException wrapping 401 DioException should be filtered');
      });
    });

    group('Global error handler edge cases', () {
      test('403 wrapped as generic Error type - global handler capture', () {
        // When DioException escapes to global error handlers, it may be
        // wrapped as a generic "Error" type but the value contains the
        // original DioException message
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Error',
              value:
                  'DioException [bad response]: This exception was thrown because the response has a status code of 403 and RequestOptions.validateStatus was configured to throw for this status code.\n'
                  'The status code of 403 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"\n'
                  'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n'
                  'In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Global handler captured 403 should be filtered');
      });

      test('401 wrapped as generic Error type - global handler capture', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'Error',
              value:
                  'DioException [bad response]: This exception was thrown because the response has a status code of 401 and RequestOptions.validateStatus was configured to throw for this status code.',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Global handler captured 401 should be filtered');
      });

      test('403 with only value containing status code', () {
        // Even if the type is something generic, the "status code of 403"
        // pattern should trigger filtering
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'UnknownException',
              value: 'response has a status code of 403',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue);
      });

      test('403 wrapped in GoException during redirect', () {
        // GoRouter wraps DioException when it occurs during redirect
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'GoException',
              value:
                  'GoException: Exception during redirect: DioException [bad response]: This exception was thrown because the response has a status code of 403 and RequestOptions.validateStatus was configured to throw for this status code.\n'
                  'The status code of 403 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'GoException wrapping 403 should be filtered');
      });

      test('401 wrapped in GoException during redirect', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'GoException',
              value:
                  'GoException: Exception during redirect: DioException [bad response]: status code of 401',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'GoException wrapping 401 should be filtered');
      });
    });

    group('Edge cases', () {
      test('Empty event', () {
        expect(SentryService.shouldFilterEvent(SentryEvent()), isFalse);
      });

      test('Empty exception list', () {
        expect(
            SentryService.shouldFilterEvent(SentryEvent(exceptions: [])), isFalse);
      });

      test('Exception with null type and value', () {
        final event = SentryEvent(
          exceptions: [SentryException(type: null, value: null)],
        );
        expect(SentryService.shouldFilterEvent(event), isFalse);
      });

      test('Case insensitive matching', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'DIOEXCEPTION',
              value: 'STATUS CODE 401',
            ),
          ],
        );
        expect(SentryService.shouldFilterEvent(event), isTrue);
      });
    });

    // Note: Emulator and test device filtering is now handled natively on Android
    // (see HeliumApplication.kt). Sentry won't initialize on those devices,
    // so no Dart-level tests are needed for that functionality.

    group('Background endpoint network errors', () {
      test('Filters connection abort on token refresh', () {
        // Real-world case: device goes offline while refreshing token
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'HttpException',
              value:
                  'HttpException: Software caused connection abort, uri = https://api.heliumedu.com/auth/token/refresh/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason:
                'Connection abort on token refresh is expected when offline');
      });

      test('Filters socket exception on token refresh', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'SocketException',
              value:
                  'SocketException: Connection reset by peer, /auth/token/refresh/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Socket errors on token refresh are expected when offline');
      });

      test('Filters connection abort on push token registration', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'HttpException',
              value:
                  'HttpException: Software caused connection abort, uri = https://api.heliumedu.com/auth/user/pushtoken/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason:
                'Connection abort on push token is expected when offline');
      });

      test('Filters socket exception on push token registration', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'SocketException',
              value:
                  'SocketException: Connection refused, /auth/user/pushtoken/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Socket errors on push token are expected when offline');
      });

      test('Does NOT filter network errors on other endpoints', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'HttpException',
              value:
                  'HttpException: Software caused connection abort, uri = https://api.heliumedu.com/planner/homework/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Network errors on other endpoints might indicate issues');
      });

      test('Does NOT filter non-network errors on token refresh', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'FormatException',
              value: 'Invalid JSON response from /auth/token/refresh/',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Non-network errors on token refresh might be bugs');
      });
    });

    group('Apple development device filtering', () {
      test('Filters events from Apple DEVELOPMENT kernel', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'WatchdogTermination',
              value:
                  'The OS watchdog terminated your app, possibly because it overused RAM.',
            ),
          ],
          contexts: Contexts(
            operatingSystem: SentryOperatingSystem(
              kernelVersion:
                  'Darwin Kernel Version 25.3.0: Mon Jan 26 21:56:52 PST 2026; root:xnu_development-12377.82.2~2/DEVELOPMENT_ARM64_T8140',
            ),
          ),
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Events from Apple development devices should be filtered');
      });

      test('Filters events with lowercase development in kernel', () {
        final event = SentryEvent(
          contexts: Contexts(
            operatingSystem: SentryOperatingSystem(
              kernelVersion: 'xnu_development-12345/development_ARM64',
            ),
          ),
        );

        expect(SentryService.shouldFilterEvent(event), isTrue,
            reason: 'Case insensitive matching for development kernel');
      });

      test('Does not filter events from release kernel', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'WatchdogTermination',
              value:
                  'The OS watchdog terminated your app, possibly because it overused RAM.',
            ),
          ],
          contexts: Contexts(
            operatingSystem: SentryOperatingSystem(
              kernelVersion:
                  'Darwin Kernel Version 25.3.0: Mon Jan 26 20:58:26 PST 2026; root:xnu-12377.82.2~2/RELEASE_ARM64_T8103',
            ),
          ),
        );

        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Events from release kernels should NOT be filtered');
      });

      test('Does not filter when no OS context present', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'WatchdogTermination',
              value:
                  'The OS watchdog terminated your app, possibly because it overused RAM.',
            ),
          ],
        );

        expect(SentryService.shouldFilterEvent(event), isFalse,
            reason: 'Events without OS context should not be filtered by this rule');
      });
    });
  });
}
