import 'package:financial_recording/models/category_model/category_model.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> getCategories({String? type});
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(dynamic key, CategoryModel category);
  Future<void> deleteCategory(dynamic key);
}
