// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';
import 'package:heliumapp/domain/repositories/auth_repository.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/course_schedule_event_repository.dart';
import 'package:heliumapp/domain/repositories/event_repository.dart';
import 'package:heliumapp/domain/repositories/external_calendar_repository.dart';
import 'package:heliumapp/domain/repositories/grade_repository.dart';
import 'package:heliumapp/domain/repositories/homework_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/domain/repositories/push_notification_repository.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Mock implementation of [AuthRepository] for testing.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock implementation of [CourseRepository] for testing.
class MockCourseRepository extends Mock implements CourseRepository {}

/// Mock implementation of [CategoryRepository] for testing.
class MockCategoryRepository extends Mock implements CategoryRepository {}

/// Mock implementation of [CourseScheduleRepository] for testing.
class MockCourseScheduleRepository extends Mock
    implements CourseScheduleRepository {}

/// Mock implementation of [EventRepository] for testing.
class MockEventRepository extends Mock implements EventRepository {}

/// Mock implementation of [HomeworkRepository] for testing.
class MockHomeworkRepository extends Mock implements HomeworkRepository {}

/// Mock implementation of [GradeRepository] for testing.
class MockGradeRepository extends Mock implements GradeRepository {}

/// Mock implementation of [ResourceRepository] for testing.
class MockResourceRepository extends Mock implements ResourceRepository {}

/// Mock implementation of [ReminderRepository] for testing.
class MockReminderRepository extends Mock implements ReminderRepository {}

/// Mock implementation of [AttachmentRepository] for testing.
class MockAttachmentRepository extends Mock implements AttachmentRepository {}

/// Mock implementation of [ExternalCalendarRepository] for testing.
class MockExternalCalendarRepository extends Mock
    implements ExternalCalendarRepository {}

/// Mock implementation of [PushNotificationRepository] for testing.
class MockPushNotificationRepository extends Mock
    implements PushNotificationRepository {}

/// Mock implementation of [DioClient] for testing.
class MockDioClient extends Mock implements DioClient {}
