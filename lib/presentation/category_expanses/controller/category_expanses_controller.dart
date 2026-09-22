import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../core.dart';

class CategoryExpansesController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Color parseColorString(String colorString) {
    final regex = RegExp(
      r'Color\(alpha:\s*(\d+\.\d+),\s*red:\s*(\d+\.\d+),\s*green:\s*(\d+\.\d+),\s*blue:\s*(\d+\.\d+)',
    );
    final match = regex.firstMatch(colorString);

    if (match != null) {
      final alpha = double.parse(match.group(1) ?? '0.0');
      final red = double.parse(match.group(2) ?? '0.0');
      final green = double.parse(match.group(3) ?? '0.0');
      final blue = double.parse(match.group(4) ?? '0.0');

      final alphaInt = (alpha * 255).toInt();
      final redInt = (red * 255).toInt();
      final greenInt = (green * 255).toInt();
      final blueInt = (blue * 255).toInt();

      return Color.fromARGB(alphaInt, redInt, greenInt, blueInt);
    }

    return Colors.transparent;
  }

  var categories = <CategoryModel>[].obs;
  void loadData() async {
    final box = await Hive.openBox<CategoryModel>('categories');
    categories.clear();
    final List<Color> colors = [
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
    ];

    int i = 0;
    for (var key in box.keys) {
      var category = box.get(key);

      if (category != null) {
        if (category.type != "expense") {
          continue;
        }
        // Use the object directly. Assign display color.
        category.color = colors[i].toString();
        categories.add(category);
        i++;

        if (i >= colors.length) {
          i = 0;
        }
      }
    }
  }

  void addCategory(CategoryModel model) {
    final box = Hive.box<CategoryModel>('categories');
    box.add(model);
    loadData();
  }

  void deleteCategory(CategoryModel category) async {
    await category.delete();
    loadData();
  }
}
