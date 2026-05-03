// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('redirect_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Redirect Preservation Tests', () {
    setUpAll(() async {
      await startSuite('Redirect Preservation Tests');
    });

    tearDownAll(() async {
      // Strip leftover ?next= so subsequent suites don't get redirected
      // through a stale destination on their first login.
      router.go(AppRoute.loginScreen);
      await endSuite();
    });

    const protectedPaths = [
      AppRoute.plannerScreen,
      AppRoute.coursesScreen,
      AppRoute.gradesScreen,
      AppRoute.resourcesScreen,
      AppRoute.notebookScreen,
      AppRoute.settingScreen,
    ];

    for (var i = 0; i < protectedPaths.length; i++) {
      final path = protectedPaths[i];
      namedTestWidgets(
        '${i + 1}. Unauthenticated $path redirects to /login with next=$path',
        (tester) async {
          await initializeTestApp(tester);
          await PrefService().clear();
          _log.info('Cleared session, navigating to $path ...');

          router.go(path);
          await tester.pumpAndSettle();

          final reachedLogin = await waitForRoute(
            tester,
            AppRoute.loginScreen,
            browserTitle: 'Login',
            timeout: config.apiTimeout,
          );
          expect(
            reachedLogin,
            isTrue,
            reason: '$path should redirect unauthenticated user to /login',
          );

          final uri = router.routeInformationProvider.value.uri;
          expect(
            uri.path,
            equals(AppRoute.loginScreen),
            reason: 'Should be on /login after redirect',
          );
          expect(
            uri.queryParameters['next'],
            equals(path),
            reason: '/login should carry next=$path to preserve intended route',
          );
        },
      );
    }
  });
}
