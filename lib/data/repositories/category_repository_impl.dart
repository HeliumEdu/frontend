import 'package:helium_student_flutter/data/datasources/category_remote_data_source.dart';
import 'package:helium_student_flutter/data/models/planner/category_model.dart';
import 'package:helium_student_flutter/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryModel>> getCategories({
    int? course,
    String? title,
  }) async {
    return await remoteDataSource.getCategories(course: course, title: title);
  }
}
