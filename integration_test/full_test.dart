// Runs all integration test suites in order. signup must come first; the
// deep_link/authed/external_calendar/logout/redirect suites assume the test
// user already exists; deep_link runs before authed because authed clears
// the example schedule it links into. delete_user removes it at the end.

import 'authed_user_test.dart' as authed_user_test;
import 'deep_link_test.dart' as deep_link_test;
import 'delete_user_test.dart' as delete_user_test;
import 'external_calendar_test.dart' as external_calendar_test;
import 'logout_test.dart' as logout_test;
import 'preferences_test.dart' as preferences_test;
import 'redirect_test.dart' as redirect_test;
import 'signup_user_test.dart' as signup_user_test;

void main() {
  signup_user_test.main();
  external_calendar_test.main();
  deep_link_test.main();
  authed_user_test.main();
  preferences_test.main();
  logout_test.main();
  redirect_test.main();
  delete_user_test.main();
}
