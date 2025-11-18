import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helium_student_flutter/core/app_exception.dart';
import 'package:helium_student_flutter/domain/repositories/homework_repository.dart';
import 'package:helium_student_flutter/presentation/bloc/homeworkBloc/homework_event.dart';
import 'package:helium_student_flutter/presentation/bloc/homeworkBloc/homework_state.dart';

class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  final HomeworkRepository homeworkRepository;

  HomeworkBloc({required this.homeworkRepository}) : super(HomeworkInitial()) {
    on<FetchAllHomeworkEvent>(_onFetchAllHomework);
    on<CreateHomeworkEvent>(_onCreateHomework);
    on<FetchHomeworkEvent>(_onFetchHomework);
    on<FetchHomeworkByIdEvent>(_onFetchHomeworkById);
    on<UpdateHomeworkEvent>(_onUpdateHomework);
    on<DeleteHomeworkEvent>(_onDeleteHomework);
  }

  Future<void> _onFetchAllHomework(
    FetchAllHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkLoading());
    try {
      final filterSummary = (event.categoryTitles?.isNotEmpty ?? false)
          ? " with categories: ${event.categoryTitles}"
          : '';
      print('🎯 Fetching all homework from repository$filterSummary');
      final homeworks = await homeworkRepository.getAllHomework(
        categoryTitles: event.categoryTitles,
      );
      print('✅ Homework fetched successfully: ${homeworks.length} homework(s)');
      emit(HomeworkLoaded(homeworks: homeworks));
    } on AppException catch (e) {
      print('❌ App error: ${e.message}');
      emit(HomeworkError(message: e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      emit(HomeworkError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCreateHomework(
    CreateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkCreating());
    try {
      final homework = await homeworkRepository.createHomework(
        groupId: event.groupId,
        courseId: event.courseId,
        request: event.request,
      );
      emit(HomeworkCreated(homework: homework));

      // Refresh homework list after creation
      add(FetchHomeworkEvent(groupId: event.groupId, courseId: event.courseId));
    } on AppException catch (e) {
      emit(HomeworkCreateError(message: e.message));
    } catch (e) {
      emit(HomeworkCreateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchHomework(
    FetchHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkLoading());
    try {
      final homeworks = await homeworkRepository.getHomework(
        groupId: event.groupId,
        courseId: event.courseId,
      );
      emit(HomeworkLoaded(homeworks: homeworks));
    } on AppException catch (e) {
      emit(HomeworkError(message: e.message));
    } catch (e) {
      emit(HomeworkError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onFetchHomeworkById(
    FetchHomeworkByIdEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkByIdLoading());
    try {
      final homework = await homeworkRepository.getHomeworkById(
        groupId: event.groupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );
      emit(HomeworkByIdLoaded(homework: homework));
    } on AppException catch (e) {
      emit(HomeworkByIdError(message: e.message));
    } catch (e) {
      emit(HomeworkByIdError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onUpdateHomework(
    UpdateHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkUpdating());
    try {
      final homework = await homeworkRepository.updateHomework(
        groupId: event.groupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
        request: event.request,
      );
      emit(HomeworkUpdated(homework: homework));

      // Refresh homework list after update
      add(FetchHomeworkEvent(groupId: event.groupId, courseId: event.courseId));
    } on AppException catch (e) {
      emit(HomeworkUpdateError(message: e.message));
    } catch (e) {
      emit(HomeworkUpdateError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onDeleteHomework(
    DeleteHomeworkEvent event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(HomeworkDeleting());
    try {
      await homeworkRepository.deleteHomework(
        groupId: event.groupId,
        courseId: event.courseId,
        homeworkId: event.homeworkId,
      );
      emit(HomeworkDeleted());

      // Refresh homework list after deletion
      add(FetchHomeworkEvent(groupId: event.groupId, courseId: event.courseId));
    } on AppException catch (e) {
      emit(HomeworkDeleteError(message: e.message));
    } catch (e) {
      emit(HomeworkDeleteError(message: 'An unexpected error occurred: $e'));
    }
  }
}
