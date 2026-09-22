import 'package:hive/hive.dart';
import 'package:financial_recording/config/app_config.dart';
import 'package:financial_recording/models/category_model/category_model.dart';
import 'i_category_repository.dart';

class CategoryRepository implements ICategoryRepository {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(AppConfig.categoryBoxName);

  @override
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final list = _box.values.toList();
    if (type != null) {
      return list.where((c) => c.type == type).toList();
    }
    return list;
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await _box.add(category);
  }

  @override
  Future<void> updateCategory(dynamic key, CategoryModel category) async {
    await _box.put(key, category);
  }

  @override
  Future<void> deleteCategory(dynamic key) async {
    await _box.delete(key);
  }
}
