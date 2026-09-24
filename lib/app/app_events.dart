import 'package:get/get.dart';

/// Bumped whenever data changes underneath the UI (a sync pulled rows, the
/// ledger switched to a family). Screens listen and reload.
final RxInt dataVersion = 0.obs;

void notifyDataChanged() => dataVersion.value++;
