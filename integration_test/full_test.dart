// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

// This file runs all integration test suites in the correct order:
// 1. signup_user_test - Creates and verifies a new user
// 2. tooltip_test - Verifies calendar item tooltips (needs pristine data)
// 3. authed_user_test - Tests authenticated user features
// 4. logout_test - Verifies logout clears session and tokens
// 5. redirect_test - Verifies unauthenticated route redirects preserve next
// 6. delete_user_test - Deletes the test user
//
// Each suite can also be run independently, but some suites depend on
// the test user existing (created by suite 1).

import 'authed_user_test.dart' as authed_user_test;
import 'delete_user_test.dart' as delete_user_test;
import 'logout_test.dart' as logout_test;
import 'redirect_test.dart' as redirect_test;
import 'signup_user_test.dart' as signup_user_test;
import 'tooltip_test.dart' as tooltip_test;

void main() {
  signup_user_test.main();
  tooltip_test.main();
  authed_user_test.main();
  logout_test.main();
  redirect_test.main();
  delete_user_test.main();
}
