// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';

abstract class RouteArgs {
  const RouteArgs();

  List<BlocProvider>? toProviders();
}

class PlannerItemAddArgs extends RouteArgs {
  final AttachmentBloc attachmentBloc;
  final int? eventId;
  final int? homeworkId;
  final DateTime? initialDate;
  final bool isFromMonthView;
  final bool isEdit;
  final bool isNew;

  const PlannerItemAddArgs({
    required this.attachmentBloc,
    this.eventId,
    this.homeworkId,
    this.initialDate,
    this.isFromMonthView = false,
    required this.isEdit,
    required this.isNew,
  });

  @override
  List<BlocProvider>? toProviders() {
    return [BlocProvider<AttachmentBloc>.value(value: attachmentBloc)];
  }
}

class CourseAddArgs extends RouteArgs {
  final CourseBloc courseBloc;
  final int courseGroupId;
  final bool isEdit;
  final bool isNew;
  final int? courseId;
  final int initialStep;

  const CourseAddArgs({
    required this.courseBloc,
    required this.courseGroupId,
    required this.isEdit,
    required this.isNew,
    this.courseId,
    this.initialStep = 0,
  });

  @override
  List<BlocProvider>? toProviders() {
    return [BlocProvider<CourseBloc>.value(value: courseBloc)];
  }
}

class ResourceAddArgs extends RouteArgs {
  final ResourceBloc resourceBloc;
  final int resourceGroupId;
  final int? resourceId;
  final bool isEdit;

  const ResourceAddArgs({
    required this.resourceBloc,
    required this.resourceGroupId,
    this.resourceId,
    required this.isEdit,
  });

  @override
  List<BlocProvider>? toProviders() {
    return [BlocProvider<ResourceBloc>.value(value: resourceBloc)];
  }
}
