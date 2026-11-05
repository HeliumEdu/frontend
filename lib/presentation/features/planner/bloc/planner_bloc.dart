import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/domain/repositories/resource_repository.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planner_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final CourseRepository courseRepository;
  final CategoryRepository categoryRepository;
  final ResourceRepository resourceRepository;
  final AttachmentRepository attachmentRepository;

  PlannerBloc({
    required this.courseRepository,
    required this.categoryRepository,
    required this.resourceRepository,
    required this.attachmentRepository,
  }) : super(PlannerInitial(origin: EventOrigin.bloc)) {
    on<FetchPlannerScreenDataEvent>(_onFetchPlannerScreenDataEvent);
    on<SkipCourseOccurrenceEvent>(_onSkipCourseOccurrence);
  }

  Future<void> _onSkipCourseOccurrence(
    SkipCourseOccurrenceEvent event,
    Emitter<PlannerState> emit,
  ) async {
    try {
      final exceptions = [...event.course.exceptions, event.date]..sort();
      final updatedCourse = await courseRepository.updateCourseExceptions(
        event.course.courseGroup,
        event.course.id,
        exceptions,
      );
      emit(
        CourseOccurrenceSkipped(
          origin: event.origin,
          updatedCourse: updatedCourse,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerError(origin: event.origin, message: e.displayMessage));
    } catch (e) {
      emit(
        PlannerError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<void> _onFetchPlannerScreenDataEvent(
    FetchPlannerScreenDataEvent event,
    Emitter<PlannerState> emit,
  ) async {
    emit(PlannerLoading(origin: event.origin));
    try {
      final results = await Future.wait([
        courseRepository.getCourseGroups(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        courseRepository.getCourses(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        categoryRepository.getCategories(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        resourceRepository.getResources(
          shownOnCalendar: true,
          forceRefresh: event.forceRefresh,
        ),
        _getAttachmentsOrNone(event.forceRefresh),
      ]);
      final courseGroups = results[0] as List<CourseGroupModel>;
      final courses = results[1] as List<CourseModel>;
      final categories = results[2] as List<CategoryModel>;
      final resources = results[3] as List<ResourceModel>;
      final attachments = results[4] as List<AttachmentModel>;

      emit(
        PlannerScreenDataFetched(
          origin: event.origin,
          courseGroups: courseGroups,
          courses: courses,
          categories: categories,
          resources: resources,
          attachments: attachments,
          forceRefresh: event.forceRefresh,
        ),
      );
    } on HeliumException catch (e) {
      emit(PlannerError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        PlannerError(
          origin: event.origin,
          message: HeliumException.unexpectedError,
        ),
      );
    }
  }

  Future<List<AttachmentModel>> _getAttachmentsOrNone(bool forceRefresh) async {
    try {
      return await attachmentRepository.getAttachments(
        forceRefresh: forceRefresh,
      );
    } on HeliumException catch (e) {
      _log.warning('Failed to load attachment counts: ${e.code}');
    } catch (e) {
      _log.warning('Failed to load attachment counts: ${e.runtimeType}');
    }
    return const [];
  }
}
