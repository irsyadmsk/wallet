import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../core.dart';

class FormCategoryController extends GetxController {
  var box = Hive.box<CategoryModel>('categories');
  final RxString categoryName = "".obs;
  final RxString selectedIcon = "".obs;
  final Rx<CategoryModel?> editingCategory = Rx<CategoryModel?>(null);

  // List of available icons
  final List<String> availableIcons = [
    "assets/icon_pack/icons8-ball-96.png",
    "assets/icon_pack/icons8-books-100.png",
    "assets/icon_pack/icons8-castle-96.png",
    "assets/icon_pack/icons8-crypto-96.png",
    "assets/icon_pack/icons8-doctor-96.png",
    "assets/icon_pack/icons8-gas-96.png",
    "assets/icon_pack/icons8-gold-96.png",
    "assets/icon_pack/icons8-health-96.png",
    "assets/icon_pack/icons8-insurance-96.png",
    "assets/icon_pack/icons8-investment-96.png",
    "assets/icon_pack/icons8-island-on-water-96.png",
    "assets/icon_pack/icons8-lightning-bolt-96.png",
    "assets/icon_pack/icons8-mountain-96.png",
    "assets/icon_pack/icons8-movie-96.png",
    "assets/icon_pack/icons8-phone-96.png",
    "assets/icon_pack/icons8-piggy-bank-96.png",
    "assets/icon_pack/icons8-popcorn-100.png",
    "assets/icon_pack/icons8-refreshments-100.png",
    "assets/icon_pack/icons8-refund-96.png",
    "assets/icon_pack/icons8-stroller-96.png",
    "assets/icon_pack/icons8-ticket-96.png",
    "assets/icon_pack/icons8-train-96.png",
    "assets/icon_pack/icons8-trekking-96.png",
    "assets/icon_pack/icons8-vehicle-96.png",
    "assets/icon_pack/icons8-voltage-96.png",
  ];

  @override
  void onInit() {
    super.onInit();
  }

  void setCategory(CategoryModel? category) {
    editingCategory.value = category;
    if (category != null) {
      categoryName.value = category.name;
      selectedIcon.value = category.iconPath;
    } else {
      categoryName.value = "";
      selectedIcon.value = "";
    }
  }

  void selectIcon(String iconPath) {
    selectedIcon.value = iconPath;
  }

  void saveCategory(String type) {
    if (categoryName.value.isEmpty) {
      Get.snackbar("Error", "Nama kategori tidak boleh kosong");
      return;
    }
    if (selectedIcon.value.isEmpty) {
      Get.snackbar("Error", "Pilih icon untuk kategori");
      return;
    }

    // Check for duplicates (skip current if editing)
    for (var element in box.values) {
      if (element.name == categoryName.value && element.type == type) {
        if (editingCategory.value != null &&
            element.key == editingCategory.value!.key) {
          continue; // It's the same item
        }
        Get.snackbar("Error", "Nama kategori sudah ada");
        return;
      }
    }

    if (editingCategory.value != null) {
      // Update existing
      var category = editingCategory.value!;
      category.name = categoryName.value;
      category.iconPath = selectedIcon.value;
      category.type = type;
      category.save(); // HiveObject save
    } else {
      // Create new
      final category = CategoryModel(
        name: categoryName.value,
        iconPath: selectedIcon.value,
        type: type,
      );
      box.add(category);
    }

    if (type == "income") {
      final controller = Get.find<CategoryIncomeController>();
      controller.loadData();
    } else {
      final controller = Get.find<CategoryExpansesController>();
      controller.loadData();
    }

    Get.back();
    Get.snackbar("Success", "Kategori berhasil disimpan");
  }
}
