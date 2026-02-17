// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/repositories/attachment_repository_impl.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_schedule_event_repository_impl.dart';
import 'package:heliumapp/data/repositories/event_repository_impl.dart';
import 'package:heliumapp/data/repositories/external_calendar_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/repositories/resource_repository_impl.dart';
import 'package:heliumapp/data/sources/attachment_remote_data_source.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_schedule_builder_source.dart';
import 'package:heliumapp/data/sources/course_schedule_remote_data_source.dart';
import 'package:heliumapp/data/sources/event_remote_data_source.dart';
import 'package:heliumapp/data/sources/external_calendar_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/data/sources/resource_remote_data_source.dart';
import 'package:heliumapp/presentation/bloc/attachment/attachment_bloc.dart';
import 'package:heliumapp/presentation/bloc/planneritem/planneritem_bloc.dart';
import 'package:heliumapp/presentation/bloc/externalcalendar/external_calendar_bloc.dart';


class ProviderHelpers {
  final DioClient _dioClient = DioClient();

  PlannerItemBloc Function(BuildContext context) createPlannerItemBloc() {
    return (context) => PlannerItemBloc(
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
        builderSource: CourseScheduleBuilderSource(),
      ),
      resourceRepository: ResourceRepositoryImpl(
        remoteDataSource: ResourceRemoteDataSourceImpl(dioClient: _dioClient),
      ),
    );
  }

  AttachmentBloc Function(BuildContext context) createAttachmentBloc() {
    return (context) => AttachmentBloc(
      attachmentRepository: AttachmentRepositoryImpl(
        remoteDataSource: AttachmentRemoteDataSourceImpl(dioClient: _dioClient),
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
