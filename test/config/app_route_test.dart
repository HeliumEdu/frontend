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
}
