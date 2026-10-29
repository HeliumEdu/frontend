import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';

void main() {
  group('AppRoute', () {
    test('test_paths_are_unique_so_no_external_redirect_shadows_an_app_route', () {
      // GIVEN
      const paths = [
        AppRoute.landingScreen,
        AppRoute.signinScreen,
        AppRoute.signupScreen,
        AppRoute.loginScreen,
        AppRoute.registerScreen,
        AppRoute.forgotPasswordScreen,
        AppRoute.resetPasswordScreen,
        AppRoute.verifyEmailScreen,
        AppRoute.setupAccountScreen,
        AppRoute.mobileWebScreen,
        AppRoute.plannerScreen,
        AppRoute.notebookScreen,
        AppRoute.coursesScreen,
        AppRoute.resourcesScreen,
        AppRoute.gradesScreen,
        AppRoute.notificationsScreen,
        AppRoute.settingScreen,
        AppRoute.connectScreen,
        AppRoute.statusRedirect,
        AppRoute.supportRedirect,
        AppRoute.contactRedirect,
        AppRoute.docsRedirect,
        AppRoute.apiRedirect,
      ];

      // WHEN
      final duplicates = paths.where((path) => paths.where((other) => other == path).length > 1).toSet();

      // THEN
      expect(duplicates, isEmpty, reason: 'Each path must belong to exactly one route');
    });
  });

  group('NextRoute', () {
    test('test_only_in_app_paths_are_safe', () {
      // GIVEN
      const safe = ['/connect?client_id=abc', '/planner'];
      const unsafe = [null, '', 'connect', 'https://evil.example/connect', '//evil.example/connect'];

      // WHEN / THEN
      for (final route in safe) {
        expect(NextRoute.isSafe(route), isTrue, reason: route);
      }
      for (final route in unsafe) {
        expect(NextRoute.isSafe(route), isFalse, reason: route);
      }
    });

    test('test_carry_attaches_next_for_read_to_recover', () {
      // GIVEN
      const next = '/connect?client_id=abc&redirect_uri=http%3A%2F%2F127.0.0.1%3A9999%2Fcallback';

      // WHEN
      final plain = NextRoute.carry(AppRoute.setupAccountScreen, next);
      final withQuery = NextRoute.carry('${AppRoute.setupAccountScreen}?auto_detect_tz=true', next);

      // THEN
      expect(NextRoute.read(Uri.parse(plain).queryParameters), next);
      expect(withQuery, startsWith('/setup?auto_detect_tz=true&next='));
      expect(NextRoute.read(Uri.parse(withQuery).queryParameters), next);
    });

    test('test_next_survives_the_web_engine_decoding_the_whole_url', () {
      // GIVEN
      const next = '/connect?client_id=abc&state=xyz';
      final carried = NextRoute.carry(AppRoute.signinScreen, next);

      // WHEN
      final browserUrl = Uri.decodeComponent(carried);

      // THEN
      expect(NextRoute.read(Uri.parse(browserUrl).queryParameters), next);
    });

    test('test_read_accepts_a_plain_path_and_rejects_anything_unsafe', () {
      // WHEN / THEN
      expect(NextRoute.read({'next': '/grades'}), '/grades');
      expect(NextRoute.read({}), isNull);
      expect(NextRoute.read({'next': 'not base64!'}), isNull);
      expect(
        NextRoute.read({'next': base64Url.encode(utf8.encode('https://evil.example')).replaceAll('=', '')}),
        isNull,
      );
    });

    test('test_carry_drops_an_unsafe_next', () {
      // WHEN
      final route = NextRoute.carry(AppRoute.signupScreen, 'https://evil.example');

      // THEN
      expect(route, AppRoute.signupScreen);
    });
  });
}
