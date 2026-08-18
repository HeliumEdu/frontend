import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:logging/logging.dart';

LogRecord _record(
  Level level, {
  Object? error,
  StackTrace? stackTrace,
  String message = 'msg',
}) {
  return LogRecord(level, message, 'test.logger', error, stackTrace);
}

void main() {
  group('LogService.classifyRecord (release Sentry forwarding)', () {
    group('SEVERE tier', () {
      test('captures an exception when a non-network error is attached', () {
        final record = _record(
          Level.SEVERE,
          error: StateError('boom'),
          stackTrace: StackTrace.current,
        );

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.captureException,
        );
      });

      test('captures a message when no error is attached', () {
        expect(
          LogService.classifyRecord(_record(Level.SEVERE)),
          LogSentryAction.captureMessage,
        );
      });

      test('SHOUT (above severe) with an error still captures an exception', () {
        final record = _record(Level.SHOUT, error: Exception('x'));

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.captureException,
        );
      });
    });

    group('Handled connectivity errors are NOT events (FRONTEND-7T class)', () {
      test('NetworkException at SEVERE becomes a breadcrumb, not an event', () {
        final record = _record(
          Level.SEVERE,
          error: NetworkException(
            message: 'No internet connection.',
            code: 'NO_INTERNET',
          ),
        );

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.breadcrumb,
          reason: 'Handled offline errors must not create Sentry events',
        );
      });

      test('NetworkException subtypes (timeout/generic) also downgrade', () {
        for (final code in const ['TIMEOUT', 'NETWORK_ERROR', 'CANCELLED']) {
          final record = _record(
            Level.SEVERE,
            error: NetworkException(message: 'network', code: code),
          );

          expect(
            LogService.classifyRecord(record),
            LogSentryAction.breadcrumb,
            reason: 'NetworkException($code) should not be an event',
          );
        }
      });

      test('Non-network HeliumException at SEVERE is still captured', () {
        final record = _record(
          Level.SEVERE,
          error: ServerException(message: 'server error', code: '500'),
        );

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.captureException,
          reason: 'Server errors are actionable and should be events',
        );
      });
    });

    group('WARNING tier', () {
      test('WARNING becomes a breadcrumb', () {
        expect(
          LogService.classifyRecord(_record(Level.WARNING)),
          LogSentryAction.breadcrumb,
        );
      });

      test('WARNING with an attached error still only breadcrumbs', () {
        final record = _record(Level.WARNING, error: Exception('x'));

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.breadcrumb,
        );
      });
    });

    group('INFO tier (breadcrumb — Sentry LoggingIntegration default)', () {
      test('INFO becomes a breadcrumb', () {
        expect(
          LogService.classifyRecord(_record(Level.INFO)),
          LogSentryAction.breadcrumb,
        );
      });

      test('INFO with an attached error still only breadcrumbs (not an event)', () {
        final record = _record(Level.INFO, error: Exception('x'));

        expect(
          LogService.classifyRecord(record),
          LogSentryAction.breadcrumb,
          reason: 'INFO must never create an event regardless of attached error',
        );
      });
    });

    group('Below INFO is dropped', () {
      test('FINE is dropped', () {
        expect(
          LogService.classifyRecord(_record(Level.FINE)),
          LogSentryAction.drop,
        );
      });

      test('FINER is dropped', () {
        expect(
          LogService.classifyRecord(_record(Level.FINER)),
          LogSentryAction.drop,
        );
      });
    });
  });
}
