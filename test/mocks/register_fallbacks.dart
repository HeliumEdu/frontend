// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:typed_data';

import 'package:heliumapp/data/models/auth/change_password_request_model.dart';
import 'package:heliumapp/data/models/auth/delete_account_request_model.dart';
import 'package:heliumapp/data/models/auth/forgot_password_request_model.dart';
import 'package:heliumapp/data/models/auth/login_request_model.dart';
import 'package:heliumapp/data/models/auth/refresh_token_request_model.dart';
import 'package:heliumapp/data/models/auth/register_request_model.dart';
import 'package:heliumapp/data/models/auth/update_settings_request_model.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/data/models/planner/category_request_model.dart';
import 'package:heliumapp/data/models/planner/course_group_request_model.dart';
import 'package:heliumapp/data/models/planner/course_request_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_request_model.dart';
import 'package:heliumapp/data/models/planner/event_request_model.dart';
import 'package:heliumapp/data/models/planner/external_calendar_request_model.dart';
import 'package:heliumapp/data/models/planner/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/material_group_request_model.dart';
import 'package:heliumapp/data/models/planner/material_request_model.dart';
import 'package:heliumapp/data/models/planner/reminder_request_model.dart';
import 'package:mocktail/mocktail.dart';

/// Register all fallback values for mocktail.
/// Call this function once in setUpAll() before running tests.
void registerFallbackValues() {
  // Common types
  registerFallbackValue(Uint8List(0));

  // Auth request models
  registerFallbackValue(_FakeLoginRequestModel());
  registerFallbackValue(_FakeRegisterRequestModel());
  registerFallbackValue(_FakeRefreshTokenRequestModel());
  registerFallbackValue(_FakeChangePasswordRequestModel());
  registerFallbackValue(_FakeForgotPasswordRequestModel());
  registerFallbackValue(_FakeDeleteAccountRequestModel());
  registerFallbackValue(_FakeUpdateSettingsRequestModel());
  registerFallbackValue(_FakeUserSettingsModel());

  // Planner request models
  registerFallbackValue(_FakeCourseGroupRequestModel());
  registerFallbackValue(_FakeCourseRequestModel());
  registerFallbackValue(_FakeCourseScheduleRequestModel());
  registerFallbackValue(_FakeCategoryRequestModel());
  registerFallbackValue(_FakeEventRequestModel());
  registerFallbackValue(_FakeHomeworkRequestModel());
  registerFallbackValue(_FakeBasicHomeworkRequestModel());
  registerFallbackValue(_FakeMaterialRequestModel());
  registerFallbackValue(_FakeMaterialGroupRequestModel());
  registerFallbackValue(_FakeReminderRequestModel());
  registerFallbackValue(_FakeExternalCalendarRequestModel());
}

// Fake implementations for request models
class _FakeLoginRequestModel extends Fake implements LoginRequestModel {}

class _FakeRegisterRequestModel extends Fake implements RegisterRequestModel {}

class _FakeRefreshTokenRequestModel extends Fake
    implements RefreshTokenRequestModel {}

class _FakeChangePasswordRequestModel extends Fake
    implements ChangePasswordRequestModel {}

class _FakeForgotPasswordRequestModel extends Fake
    implements ForgotPasswordRequestModel {}

class _FakeDeleteAccountRequestModel extends Fake
    implements DeleteAccountRequestModel {}

class _FakeUpdateSettingsRequestModel extends Fake
    implements UpdateSettingsRequestModel {}

class _FakeCourseGroupRequestModel extends Fake
    implements CourseGroupRequestModel {}

class _FakeCourseRequestModel extends Fake implements CourseRequestModel {}

class _FakeCourseScheduleRequestModel extends Fake
    implements CourseScheduleRequestModel {}

class _FakeCategoryRequestModel extends Fake implements CategoryRequestModel {}

class _FakeEventRequestModel extends Fake implements EventRequestModel {}

class _FakeHomeworkRequestModel extends Fake implements HomeworkRequestModel {}

class _FakeBasicHomeworkRequestModel extends Fake
    implements HomeworkRequestModel {}

class _FakeMaterialRequestModel extends Fake implements MaterialRequestModel {}

class _FakeMaterialGroupRequestModel extends Fake
    implements MaterialGroupRequestModel {}

class _FakeReminderRequestModel extends Fake implements ReminderRequestModel {}

class _FakeExternalCalendarRequestModel extends Fake
    implements ExternalCalendarRequestModel {}

class _FakeUserSettingsModel extends Fake implements UserSettingsModel {}
