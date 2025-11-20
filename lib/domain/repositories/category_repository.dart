import 'package:heliumedu/data/models/planner/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories({int? course, String? title});
}
