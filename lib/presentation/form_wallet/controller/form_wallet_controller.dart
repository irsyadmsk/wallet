import 'package:financial_recording/models/wallet_model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../core.dart';

class FormWalletController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = "".obs;
  var box = Hive.box<WalletModel>('walletBox');
  final RxString walletName = "".obs;
  final RxString initialBalance = "".obs;
  final RxList<Color> selectedGradient = <Color>[].obs;
  final RxString selectedIcon = "".obs;

  // Available wallet icons (bank logos) - all logos from bank_logo folder
  final List<String> availableIcons = [
    "assets/icon_pack/bank_logo/akulaku.png",
    "assets/icon_pack/bank_logo/amex.png",
    "assets/icon_pack/bank_logo/anz.png",
    "assets/icon_pack/bank_logo/applepay.png",
    "assets/icon_pack/bank_logo/bank syariah indonesia.png",
    "assets/icon_pack/bank_logo/bareksa.png",
    "assets/icon_pack/bank_logo/bca.png",
    "assets/icon_pack/bank_logo/bi.png",
    "assets/icon_pack/bank_logo/bibit.png",
    "assets/icon_pack/bank_logo/bjb.png",
    "assets/icon_pack/bank_logo/bluepay.png",
    "assets/icon_pack/bank_logo/bni.png",
    "assets/icon_pack/bank_logo/bri.png",
    "assets/icon_pack/bank_logo/btn.png",
    "assets/icon_pack/bank_logo/bukopin.png",
    "assets/icon_pack/bank_logo/cashbac.png",
    "assets/icon_pack/bank_logo/cashlez.png",
    "assets/icon_pack/bank_logo/cimb.png",
    "assets/icon_pack/bank_logo/citi.png",
    "assets/icon_pack/bank_logo/dana.png",
    "assets/icon_pack/bank_logo/danamon.png",
    "assets/icon_pack/bank_logo/dhuha.png",
    "assets/icon_pack/bank_logo/digibank.png",
    "assets/icon_pack/bank_logo/doku.png",
    "assets/icon_pack/bank_logo/faspay.png",
    "assets/icon_pack/bank_logo/flip.png",
    "assets/icon_pack/bank_logo/gopay.png",
    "assets/icon_pack/bank_logo/gpay.png",
    "assets/icon_pack/bank_logo/homecredit.png",
    "assets/icon_pack/bank_logo/hsbc.png",
    "assets/icon_pack/bank_logo/jago.png",
    "assets/icon_pack/bank_logo/jcb.png",
    "assets/icon_pack/bank_logo/jenius.png",
    "assets/icon_pack/bank_logo/kredivo.png",
    "assets/icon_pack/bank_logo/kudo.png",
    "assets/icon_pack/bank_logo/linkaja.png",
    "assets/icon_pack/bank_logo/mandiri.png",
    "assets/icon_pack/bank_logo/mastercard.png",
    "assets/icon_pack/bank_logo/maybank.png",
    "assets/icon_pack/bank_logo/mega.png",
    "assets/icon_pack/bank_logo/midtrans.png",
    "assets/icon_pack/bank_logo/ocbc.png",
    "assets/icon_pack/bank_logo/ovo.png",
    "assets/icon_pack/bank_logo/panin.png",
    "assets/icon_pack/bank_logo/payfazz.png",
    "assets/icon_pack/bank_logo/paypal.png",
    "assets/icon_pack/bank_logo/paypro.png",
    "assets/icon_pack/bank_logo/paytren.png",
    "assets/icon_pack/bank_logo/permata.png",
    "assets/icon_pack/bank_logo/pluang.png",

    "assets/icon_pack/bank_logo/shopeepay.png",

    "assets/icon_pack/bank_logo/uangku.png",
    "assets/icon_pack/bank_logo/visa.png",
  ];

  // Available color scheme options
  final List<Color> colorScheme = [
    const Color(0xFF667EEA), // Purple
    const Color(0xFF764BA2), // Dark Purple
    const Color(0xFF11998E), // Teal
    const Color(0xFF38EF7D), // Green
    const Color(0xFFF093FB), // Pink
    const Color(0xFFF5576C), // Coral
    const Color(0xFFFA709A), // Rose
    const Color(0xFFFEE140), // Yellow
    const Color(0xFF4FACFE), // Sky Blue
    const Color(0xFF00F2FE), // Cyan
    const Color(0xFF0BA360), // Forest
    const Color(0xFF3CBA92), // Mint
    const Color(0xFF8E2DE2), // Royal Purple
    const Color(0xFF4A00E0), // Deep Purple
    const Color(0xFFFF512F), // Orange Red
    const Color(0xFFF09819), // Orange
    const Color(0xFFFF6B6B), // Red
    const Color(0xFF4ECDC4), // Turquoise
    const Color(0xFF45B7D1), // Light Blue
    const Color(0xFF96CEB4), // Sage
  ];

  final Rx<WalletModel?> editingWallet = Rx<WalletModel?>(null);

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
      hasError.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }

  void setWallet(WalletModel? wallet) {
    editingWallet.value = wallet;
    if (wallet != null) {
      walletName.value = wallet.name;
      initialBalance.value = wallet.balance.toString();
      selectedIcon.value = wallet.iconPath;
      selectedGradient.assignAll(wallet.gradientColors);
    } else {
      walletName.value = "";
      initialBalance.value = "";
      selectedIcon.value = "";
      selectedGradient.clear();
    }
  }

  void selectColor(Color color) {
    if (selectedGradient.length < 2) {
      selectedGradient.add(color);
    } else {
      // Replace the second color if both are already selected
      selectedGradient[1] = color;
    }
    selectedGradient.refresh();
  }

  void removeColor(int index) {
    if (selectedGradient.length > index) {
      selectedGradient.removeAt(index);
      selectedGradient.refresh();
    }
  }

  void clearColors() {
    selectedGradient.clear();
  }

  void selectIcon(String iconPath) {
    selectedIcon.value = iconPath;
  }

  void saveWallet() {
    if (walletName.value.isEmpty) {
      Get.snackbar("Error", "Nama wallet tidak boleh kosong");
      return;
    }
    if (initialBalance.value.isEmpty) {
      Get.snackbar("Error", "Saldo awal tidak boleh kosong");
      return;
    }
    if (selectedGradient.length < 2) {
      Get.snackbar("Error", "Pilih 2 warna untuk wallet");
      return;
    }
    if (selectedIcon.value.isEmpty) {
      Get.snackbar("Error", "Pilih icon untuk wallet");
      return;
    }

    if (editingWallet.value != null) {
      var wallet = editingWallet.value!;
      wallet.name = walletName.value;
      wallet.balance = int.parse(initialBalance.value.replaceAll(".", ""));
      wallet.iconPath = selectedIcon.value;
      wallet.gradientColors = selectedGradient.toList();
      wallet.save();
    } else {
      box.add(
        WalletModel(
          name: walletName.value,
          iconPath: selectedIcon.value,
          balance: int.parse(initialBalance.value.replaceAll(".", "")),
          gradient: selectedGradient.map((c) => c.value).toList(),
        ),
      );
    }

    final controller = Get.find<WalletController>();
    controller
        .refresh(); // This might need improvement as refresh reloads from DB
    // Actually controller.refresh() calls initializeData which reloads from box.values.
    // Since we saved to box, it should be fine.

    Get.back();
    Get.snackbar("Success", "Wallet berhasil disimpan");
  }
}
