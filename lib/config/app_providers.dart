// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/notification_count_service.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/data/repositories/info_repository_impl.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/data/sources/info_remote_data_source.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_bloc.dart';
import 'package:heliumapp/presentation/features/courses/bloc/course_event.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_bloc.dart';
import 'package:heliumapp/presentation/features/grades/bloc/grade_event.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_bloc.dart';
import 'package:heliumapp/presentation/features/notebook/bloc/note_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/reminder_event.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_bloc.dart';
import 'package:heliumapp/presentation/features/resources/bloc/resource_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/info/info_event.dart';

/// Hosts every entity-data BLoC read across multiple shells, so any overlay
/// route (settings, notifications, homework/event/note/resource/course
/// editors) resolves its providers without per-branch wiring.
///
/// Each provider is `lazy: true`: the BLoC isn't constructed until the first
/// `context.read`/`context.watch`, so initial app boot stays cheap.
/// AuthBloc is the lone exception — the router's redirect logic reads it
/// before any screen mounts, so it must be eagerly created.
///
/// A nested [BlocListener] fans logout out to every data BLoC's reset event,
/// guaranteeing that per-user state doesn't leak across sessions.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    final providerHelpers = ProviderHelpers();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
            dioClient: dioClient,
          ),
        ),
        BlocProvider<InfoBloc>(
          lazy: true,
          create: (context) => InfoBloc(
            infoRepository: InfoRepositoryImpl(
              remoteDataSource: InfoRemoteDataSourceImpl(dioClient: dioClient),
            ),
          )..add(LoadInfoEvent()),
        ),
        BlocProvider<ExternalCalendarBloc>(
          lazy: true,
          create: providerHelpers.createExternalCalendarBloc(),
        ),
        BlocProvider<PlannerItemBloc>(
          lazy: true,
          create: providerHelpers.createPlannerItemBloc(),
        ),
        BlocProvider<CategoryBloc>(
          lazy: true,
          create: providerHelpers.createCategoryBloc(),
        ),
        BlocProvider<CourseBloc>(
          lazy: true,
          create: providerHelpers.createCourseBloc(),
        ),
        BlocProvider<NoteBloc>(
          lazy: true,
          create: providerHelpers.createNoteBloc(),
        ),
        BlocProvider<ResourceBloc>(
          lazy: true,
          create: providerHelpers.createResourceBloc(),
        ),
        BlocProvider<GradeBloc>(
          lazy: true,
          create: providerHelpers.createGradeBloc(),
        ),
        BlocProvider<AttachmentBloc>(
          lazy: true,
          create: providerHelpers.createAttachmentBloc(),
        ),
        BlocProvider<ReminderBloc>(
          lazy: true,
          create: providerHelpers.createReminderBloc(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthLoggedOut && previous is! AuthLoggedOut,
        listener: (context, _) {
          context.read<PlannerItemBloc>().add(ResetPlannerItemsEvent());
          context.read<ExternalCalendarBloc>().add(
            ResetExternalCalendarsEvent(),
          );
          context.read<CategoryBloc>().add(ResetCategoriesEvent());
          context.read<CourseBloc>().add(ResetCoursesEvent());
          context.read<NoteBloc>().add(ResetNotesEvent());
          context.read<ResourceBloc>().add(ResetResourcesEvent());
          context.read<GradeBloc>().add(ResetGradesEvent());
          context.read<AttachmentBloc>().add(ResetAttachmentsEvent());
          context.read<ReminderBloc>().add(ResetRemindersEvent());
          NotificationCountService().reset();
        },
        child: child,
      ),
    );
  }
}
