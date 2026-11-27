import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_event.dart';
import 'package:heliumapp/presentation/features/courses/bloc/category_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository})
    : super(CategoryInitial(origin: EventOrigin.bloc)) {
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<ResetCategoriesEvent>(
      (event, emit) => emit(CategoryInitial(origin: EventOrigin.bloc)),
    );
  }

  Future<void> _onFetchCategories(
    FetchCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    if (!event.passive) emit(CategoriesLoading(origin: event.origin));
    try {
      final categories = await categoryRepository.getCategories(
        courseId: event.courseId,
        title: event.title,
        forceRefresh: event.forceRefresh,
      );
      emit(CategoriesFetched(origin: event.origin, categories: categories));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: HeliumException.unexpectedErrorMessage,
        ),
      );
    }
  }

  Future<void> _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      final category = await categoryRepository.createCategory(
        event.courseGroupId,
        event.courseId,
        event.request,
      );
      emit(CategoryCreated(origin: event.origin, category: category));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: HeliumException.unexpectedErrorMessage,
        ),
      );
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      final category = await categoryRepository.updateCategory(
        event.courseGroupId,
        event.courseId,
        event.categoryId,
        event.request,
        version: event.version,
      );
      emit(CategoryUpdated(origin: event.origin, category: category));
    } on ConflictException catch (e) {
      emit(CategoryConflict(
        origin: event.origin,
        latest: CategoryModel.fromJson(e.latest),
      ));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: HeliumException.unexpectedErrorMessage,
        ),
      );
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoriesLoading(origin: event.origin));

    try {
      await categoryRepository.deleteCategory(
        event.courseGroupId,
        event.courseId,
        event.categoryId,
      );

      emit(CategoryDeleted(origin: event.origin, id: event.categoryId));
    } on HeliumException catch (e) {
      emit(CategoriesError(origin: event.origin, message: e.message));
      return;
    } catch (e) {
      emit(
        CategoriesError(
          origin: event.origin,
          message: HeliumException.unexpectedErrorMessage,
        ),
      );
      return;
    }

    try {
      final categories = await categoryRepository.getCategories(
        courseId: event.courseId,
        forceRefresh: true,
      );
      emit(CategoriesFetched(origin: EventOrigin.bloc, categories: categories));
    } on HeliumException catch (e) {
      _log.warning('Failed to refetch categories after a delete: ${e.runtimeType} code=${e.code}');
    }
  }
}
