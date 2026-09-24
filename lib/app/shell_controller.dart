import 'package:get/get.dart';

/// Page indexes of the main shell, in the order of `_destinations` in
/// `money_manager_app.dart`. Always navigate with these, never raw ints.
abstract class AppPage {
  static const dashboard = 0;
  static const transactions = 1;
  static const accounts = 2;
  static const budgets = 3;
  static const reports = 4;
  static const goals = 5;
  static const debts = 6;
  static const recurring = 7;
  static const zakat = 8;
  static const family = 9;
  static const categories = 10;
  static const settings = 11;
}

class ShellController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  void goTo(int index) => selectedIndex.value = index;
}
