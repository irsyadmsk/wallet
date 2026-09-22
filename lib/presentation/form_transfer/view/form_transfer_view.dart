import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';

class FormTransferView extends StatelessWidget {
  const FormTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FormTransferController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (controller.hasError.value) {
        return Scaffold(
          body: Center(child: Text("Error: ${controller.errorMessage.value}")),
        );
      }

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTransferCard(controller),
                    const SizedBox(height: 16),
                    _buildAmountCard(controller),
                    const SizedBox(height: 16),
                    _buildInfoBox(),
                  ],
                ),
              ),
            ),
            _buildBottomSection(controller),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "Transfer Antar Wallet",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  Widget _buildTransferCard(FormTransferController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWalletSection(
            label: "Dari Wallet",
            icon: Icons.account_balance_wallet,
            iconColor: primaryColor,
            iconBgColor: primaryColor.withOpacity(0.1),
            dropdownLabel: "Pilih Wallet Sumber",
            controller: controller,
            items: controller.sourceWallets,
            selectedKey: controller.selectedSourceWalletKey,
            hasMargin: true,
            onChanged: (val) {
              controller.selectedSourceWalletKey.value = val ?? "";
              // Reset dest if same as source
              if (controller.selectedDestWalletKey.value == val) {
                controller.selectedDestWalletKey.value = "";
              }
            },
          ),
          _buildWalletSection(
            label: "Ke Wallet",
            icon: Icons.account_balance_wallet,
            iconColor: Colors.green.shade700,
            iconBgColor: Colors.green.shade100,
            dropdownLabel: "Pilih Wallet Tujuan",
            controller: controller,
            items: controller.filteredDestWallets,
            selectedKey: controller.selectedDestWalletKey,
            hasMargin: false,
            onChanged: (val) {
              controller.selectedDestWalletKey.value = val ?? "";
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String dropdownLabel,
    required FormTransferController controller,
    required List<Map<String, dynamic>> items,
    required RxString selectedKey,
    required Function(String?) onChanged,
    required bool hasMargin,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        QDropdownField(
          label: dropdownLabel,
          hint: "Pilih wallet",
          validator: Validator.required,
          items: items,
          value: selectedKey.value.isEmpty ? null : selectedKey.value,
          onChanged: (value, label) => onChanged(value),
          margin: hasMargin
              ? const EdgeInsets.only(bottom: 12)
              : EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTransferArrow() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_downward_rounded,
        color: Colors.blue.shade700,
        size: 20,
      ),
    );
  }

  Widget _buildAmountCard(FormTransferController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Jumlah Transfer",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          QTextField(
            label: "Nominal Transfer (Rp)",
            hint: "Masukkan jumlah",
            isNumberOnly: true,
            validator: Validator.required,
            value: controller.incomeList.isNotEmpty
                ? controller.incomeList[0]["nominal"]
                : "",
            onChanged: (value) {
              if (controller.incomeList.isEmpty) {
                controller.addItem();
              }
              controller.incomeList[0]["nominal"] = value;
              controller.incomeList.refresh();
            },
            prefixIcon: Icons.attach_money,
          ),
          QTextField(
            label: "Catatan (Opsional)",
            hint: "Contoh: Transfer untuk operasional",
            value: controller.incomeList.isNotEmpty
                ? controller.incomeList[0]["name"]
                : "",
            onChanged: (value) {
              if (controller.incomeList.isEmpty) {
                controller.addItem();
              }
              controller.incomeList[0]["name"] = value;
              controller.incomeList.refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Pastikan wallet tujuan sudah benar",
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(FormTransferController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTotalDisplay(controller),
            const SizedBox(height: 16),
            _buildTransferButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDisplay(FormTransferController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Transfer",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Rp ${_formatCurrency(controller.totalIncome)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton(FormTransferController controller) {
    return ElevatedButton(
      onPressed: () {
        controller.saveTransfer();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Text(
            "Proses Transfer",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
