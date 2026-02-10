// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/repositories/material_repository_impl.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/data/sources/material_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/calendaritem/calendaritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';

// TODO: Cleanup: Move all provider instantiation in to here

class ProviderHelpers {
  final DioClient _dioClient = DioClient();

  CalendarItemBloc Function(BuildContext context) createCalendarItemBloc() {
    return (context) => CalendarItemBloc(
      eventRepository: EventRepositoryImpl(
        remoteDataSource: EventRemoteDataSourceImpl(dioClient: _dioClient),
      ),
      homeworkRepository: HomeworkRepositoryImpl(
        remoteDataSource: HomeworkRemoteDataSourceImpl(dioClient: _dioClient),
      ),
      courseRepository: CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(dioClient: _dioClient),
      ),
      categoryRepository: CategoryRepositoryImpl(
        remoteDataSource: CategoryRemoteDataSourceImpl(dioClient: _dioClient),
      ),
      courseScheduleRepository: CourseScheduleRepositoryImpl(
        remoteDataSource: CourseScheduleRemoteDataSourceImpl(
          dioClient: _dioClient,
        ),
      ),
      materialRepository: MaterialRepositoryImpl(
        remoteDataSource: MaterialRemoteDataSourceImpl(dioClient: _dioClient),
      ),
    );
  }

  ExternalCalendarBloc Function(BuildContext context)
  createExternalCalendarBloc() {
    return (context) => ExternalCalendarBloc(
      externalCalendarRepository: ExternalCalendarRepositoryImpl(
        remoteDataSource: ExternalCalendarRemoteDataSourceImpl(
          dioClient: _dioClient,
        ),
      ),
    );
  }
}
