import 'package:hive/hive.dart';

part 'category_model.g.dart'; // wajib

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String iconPath;

  @HiveField(2)
  String type;

  @HiveField(3)
  String? color;

  CategoryModel({
    required this.name,
    required this.iconPath,
    required this.type,
    this.color,
  });

  @override
  String toString() {
    return 'CategoryModel(name: $name, iconPath: $iconPath, type: $type, color: $color)';
  }
}
