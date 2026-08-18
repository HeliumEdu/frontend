// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

// Runs all integration test suites in order. signup must come first; the
// authed/external_calendar/logout/redirect suites assume the test user
// already exists. delete_user removes it at the end.

import 'authed_user_test.dart' as authed_user_test;
import 'delete_user_test.dart' as delete_user_test;
import 'external_calendar_test.dart' as external_calendar_test;
import 'logout_test.dart' as logout_test;
import 'redirect_test.dart' as redirect_test;
import 'signup_user_test.dart' as signup_user_test;

void main() {
  signup_user_test.main();
  external_calendar_test.main();
  authed_user_test.main();
  logout_test.main();
  redirect_test.main();
  delete_user_test.main();
}
