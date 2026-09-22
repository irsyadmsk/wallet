import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class WalletController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = "".obs;
  final RxInt counter = 0.obs;
  var box = Hive.box<WalletModel>('walletBox');
  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  @override
  void refresh() {
    wallets.clear();
    initializeData();
    super.refresh();
  }

  final wallets = <WalletModel>[].obs;

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      if (!Hive.isBoxOpen('walletBox')) {
        box = await Hive.openBox<WalletModel>('walletBox');
      }

      wallets.assignAll(box.values.toList());

      isLoading.value = false;
      hasError.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }

  void deleteWallet(WalletModel wallet) async {
    await wallet.delete();
    initializeData();
  }

  void increment() {
    counter.value++;
  }

  void decrement() {
    counter.value--;
  }
}
