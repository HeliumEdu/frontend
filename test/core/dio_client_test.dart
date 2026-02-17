// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late MockPrefService mockPrefService;
  late MockDio mockDio;
  late MockCacheService mockCacheService;
  late DioClient dioClient;

  setUp(() {
    mockPrefService = MockPrefService();
    mockDio = MockDio();
    mockCacheService = MockCacheService();

    // Setup default mock behaviors
    when(() => mockDio.options).thenReturn(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Stub init() to return a completed Future
    when(() => mockPrefService.init()).thenAnswer((_) async {});

    // Stub cache service methods
    when(() => mockCacheService.clearAll()).thenAnswer((_) async {});

    dioClient = DioClient.forTesting(
      dio: mockDio,
      prefService: mockPrefService,
      cacheService: mockCacheService,
    );
  });

  tearDown(() {
    DioClient.resetForTesting();
    PrefService.resetForTesting();
  });

  group('DioClient', () {
    group('singleton pattern', () {
      test('factory constructor returns same instance', () {
        // WHEN
        final instance1 = DioClient();
        final instance2 = DioClient();

        // THEN
        expect(identical(instance1, instance2), isTrue);
      });

      test('setInstanceForTesting allows replacing the singleton', () {
        // GIVEN
        DioClient.setInstanceForTesting(dioClient);

        // WHEN
        final instance = DioClient();

        // THEN
        expect(identical(instance, dioClient), isTrue);
      });

      test('resetForTesting creates a new instance', () {
        // GIVEN
        DioClient.setInstanceForTesting(dioClient);
        final oldInstance = DioClient();

        // WHEN
        DioClient.resetForTesting();
        final newInstance = DioClient();

        // THEN
        expect(identical(oldInstance, newInstance), isFalse);
      });
    });

    group('isAuthenticated', () {
      test('returns true when access token exists and is not empty', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => 'valid_token');

        // WHEN
        final result = await dioClient.isAuthenticated();

        // THEN
        expect(result, isTrue);
      });

      test('returns false when access token is null', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => null);

        // WHEN
        final result = await dioClient.isAuthenticated();

        // THEN
        expect(result, isFalse);
      });

      test('returns false when access token is empty', () async {
        // GIVEN
        when(
          () => mockPrefService.getSecure('access_token'),
        ).thenAnswer((_) async => '');

        // WHEN
        final result = await dioClient.isAuthenticated();

        // THEN
        expect(result, isFalse);
      });
    });

    group('isInvalidTokenError', () {
      test('returns true for "Token is blacklisted" message', () {
        // GIVEN
        final data = {'detail': 'Token is blacklisted'};

        // WHEN
        final result = dioClient.isInvalidTokenError(data);

        // THEN
        expect(result, isTrue);
      });

      test('returns true for message containing "invalid"', () {
        // GIVEN
        final data = {'detail': 'Token is invalid'};

        // WHEN
        final result = dioClient.isInvalidTokenError(data);

        // THEN
        expect(result, isTrue);
      });

      test('returns true for message containing "expired"', () {
        // GIVEN
        final data = {'detail': 'Token has expired'};

        // WHEN
        final result = dioClient.isInvalidTokenError(data);

        // THEN
        expect(result, isTrue);
      });

      test('returns false for other error messages', () {
        // GIVEN
        final data = {'detail': 'Network error'};

        // WHEN
        final result = dioClient.isInvalidTokenError(data);

        // THEN
        expect(result, isFalse);
      });

      test('returns false for null data', () {
        // WHEN
        final result = dioClient.isInvalidTokenError(null);

        // THEN
        expect(result, isFalse);
      });

      test('returns false for non-map data', () {
        // WHEN
        final result = dioClient.isInvalidTokenError('string data');

        // THEN
        expect(result, isFalse);
      });

      test('returns false for map without detail key', () {
        // GIVEN
        final data = {'error': 'Some error'};

        // WHEN
        final result = dioClient.isInvalidTokenError(data);

        // THEN
        expect(result, isFalse);
      });
    });

    group('getSettings', () {
      test('retrieves all settings from prefService', () async {
        // GIVEN
        when(
          () => mockPrefService.getString('time_zone'),
        ).thenReturn('America/New_York');
        when(
          () => mockPrefService.getBool('color_by_category'),
        ).thenReturn(true);
        when(() => mockPrefService.getInt('default_view')).thenReturn(0);
        when(() => mockPrefService.getInt('color_scheme_theme')).thenReturn(1);
        when(() => mockPrefService.getInt('week_starts_on')).thenReturn(0);
        when(() => mockPrefService.getInt('all_day_offset')).thenReturn(0);
        when(
          () => mockPrefService.getInt('whats_new_version_seen'),
        ).thenReturn(0);
        when(
          () => mockPrefService.getString('events_color'),
        ).thenReturn('#FF0000');
        when(
          () => mockPrefService.getString('resource_color'),
        ).thenReturn('#00FF00');
        when(
          () => mockPrefService.getString('grade_color'),
        ).thenReturn('#0000FF');
        when(
          () => mockPrefService.getInt('default_reminder_type'),
        ).thenReturn(3);
        when(
          () => mockPrefService.getInt('default_reminder_offset'),
        ).thenReturn(15);
        when(
          () => mockPrefService.getInt('default_reminder_offset_type'),
        ).thenReturn(0);
        when(
          () => mockPrefService.getBool('calendar_use_category_colors'),
        ).thenReturn(true);
        when(
          () => mockPrefService.getBool('show_planner_tooltips'),
        ).thenReturn(false);
        when(
          () => mockPrefService.getBool('remember_filter_state'),
        ).thenReturn(false);

        // WHEN
        final settings = await dioClient.getSettings();

        // THEN
        expect(settings, isNotNull);
        // timeZone is a Location object, check its name property
        expect(settings!.timeZone.name, equals('America/New_York'));
        // colorByCategory comes from calendar_use_category_colors in the JSON
        expect(settings.colorByCategory, isTrue);
        expect(settings.showPlannerTooltips, isFalse);
        expect(settings.defaultView, equals(0));
        expect(settings.colorSchemeTheme, equals(1));
        verify(() => mockPrefService.getString('time_zone')).called(1);
        // The service reads from calendar_use_category_colors, not color_by_category
        verify(
          () => mockPrefService.getBool('calendar_use_category_colors'),
        ).called(1);
      });
    });

    group('cacheService', () {
      test('getter returns the cache service', () {
        // WHEN
        final cacheService = dioClient.cacheService;

        // THEN
        expect(cacheService, isA<CacheService>());
        expect(cacheService, equals(mockCacheService));
      });
    });

    group('clearStorage', () {
      test('clears cache and preferences', () async {
        // GIVEN
        when(() => mockPrefService.clear()).thenAnswer((_) async => []);

        // WHEN
        await dioClient.clearStorage();

        // THEN
        verify(() => mockCacheService.clearAll()).called(1);
        verify(() => mockPrefService.clear()).called(1);
      });
    });
  });
}
