import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  void goTo(int index) => selectedIndex.value = index;
}
