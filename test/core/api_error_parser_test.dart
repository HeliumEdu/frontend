import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/api_error_parser.dart';

void main() {
  group('ApiErrorParser', () {
    group('parse with Map response data', () {
      test('parses single field error with list value', () {
        final responseData = {
          'email': ['Sorry, that email is already in use.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors['email'], contains('Sorry, that email is already in use.'));
        expect(result.displayMessage, equals('Sorry, that email is already in use.'));
        expect(result.getFieldError('email'), equals('Sorry, that email is already in use.'));
      });

      test('parses single field error with string value', () {
        final responseData = {
          'password': 'This password is too common.',
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors['password'], contains('This password is too common.'));
        expect(result.displayMessage, equals('This password is too common.'));
      });

      test('parses multiple field errors', () {
        final responseData = {
          'email': ['Invalid email format.'],
          'password': ['Password must be at least 8 characters.', 'Password cannot be entirely numeric.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors.length, equals(2));
        expect(result.fieldErrors['email'], contains('Invalid email format.'));
        expect(result.fieldErrors['password']!.length, equals(2));
        expect(result.displayMessage, contains('Invalid email format.'));
        expect(result.displayMessage, contains('Password must be at least 8 characters.'));
        expect(result.displayMessage, contains('Password cannot be entirely numeric.'));
      });

      test('parses non_field_errors key', () {
        final responseData = {
          'non_field_errors': ['The credentials provided are incorrect.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors['non_field_errors'], contains('The credentials provided are incorrect.'));
        expect(result.displayMessage, equals('The credentials provided are incorrect.'));
      });

      test('parses old_password field error', () {
        final responseData = {
          'old_password': ['The current password was entered incorrectly.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.getFieldError('old_password'), equals('The current password was entered incorrectly.'));
      });
    });

    group('parse with List response data', () {
      test('parses list of plain error strings', () {
        final responseData = [
          'An error occurred.',
          'Please try again later.',
        ];

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isFalse);
        expect(result.generalErrors.length, equals(2));
        expect(result.generalErrors, contains('An error occurred.'));
        expect(result.generalErrors, contains('Please try again later.'));
      });

      test('parses list with prefixed field errors', () {
        final responseData = [
          'email: Invalid email address.',
          'password: Password too short.',
        ];

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors['email'], contains('Invalid email address.'));
        expect(result.fieldErrors['password'], contains('Password too short.'));
        expect(result.displayMessage, contains('Invalid email address.'));
        expect(result.displayMessage, contains('Password too short.'));
      });
    });

    group('parse with String response data', () {
      test('parses plain string error', () {
        const responseData = 'Something went wrong.';

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isFalse);
        expect(result.generalErrors, contains('Something went wrong.'));
        expect(result.displayMessage, equals('Something went wrong.'));
      });

      test('parses string with field prefix', () {
        const responseData = 'email: This email is already registered.';

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.getFieldError('email'), equals('This email is already registered.'));
        expect(result.displayMessage, equals('This email is already registered.'));
      });

      test('parses multiline string with multiple field errors', () {
        const responseData = 'email: Invalid email.\npassword: Too short.';

        final result = ApiErrorParser.parse(responseData);

        expect(result.hasFieldErrors, isTrue);
        expect(result.fieldErrors.length, equals(2));
        expect(result.getFieldError('email'), equals('Invalid email.'));
        expect(result.getFieldError('password'), equals('Too short.'));
      });
    });


    group('ParsedApiError', () {
      test('getFieldError returns null for non-existent field', () {
        final result = ApiErrorParser.parse({'email': ['Error']});

        expect(result.getFieldError('password'), isNull);
      });

      test('getFieldError returns first error when multiple exist', () {
        final result = ApiErrorParser.parse({
          'password': ['Error 1', 'Error 2'],
        });

        expect(result.getFieldError('password'), equals('Error 1'));
      });


    });

    group('edge cases', () {
      test('handles empty map response data', () {
        final result = ApiErrorParser.parse(<String, dynamic>{});

        expect(result.hasFieldErrors, isFalse);
        expect(result.displayMessage, isEmpty);
      });

      test('handles empty list response data', () {
        final result = ApiErrorParser.parse(<dynamic>[]);

        expect(result.hasFieldErrors, isFalse);
      });

      test('handles field names with underscores', () {
        final responseData = {
          'old_password': ['Incorrect password.'],
          'confirm_password': ['Passwords do not match.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.getFieldError('old_password'), equals('Incorrect password.'));
        expect(result.getFieldError('confirm_password'), equals('Passwords do not match.'));
      });



    });

    group('real-world API error formats', () {
      test('parses Django REST Framework validation error', () {
        final responseData = {
          'email': ['A user with that email already exists.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.getFieldError('email'), equals('A user with that email already exists.'));
        expect(result.displayMessage, equals('A user with that email already exists.'));
      });

      test('parses Django REST Framework multiple field validation', () {
        final responseData = {
          'email': ['Enter a valid email address.'],
          'password': ['This password is too short. It must contain at least 8 characters.', 'This password is too common.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.fieldErrors.length, equals(2));
        expect(result.fieldErrors['password']!.length, equals(2));
      });

      test('parses category weight validation error', () {
        final responseData = {
          'weight': ['The cumulative weights of all categories associated with a course cannot exceed 100%.'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.getFieldError('weight'), contains('cumulative weights'));
      });

      test('parses title uniqueness validation error', () {
        final responseData = {
          'title': ['This course already has a category named "Homework".'],
        };

        final result = ApiErrorParser.parse(responseData);

        expect(result.getFieldError('title'), contains('already has a category'));
      });
    });
  });
}
