import 'package:financial_recording/presentation/history_transaction/view/transaction_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';
import 'package:intl/intl.dart';

class HistoryTransactionView extends StatelessWidget {
  const HistoryTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryTransactionController());
    final double appBarHeight = AppBar().preferredSize.height;
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
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: const Text(
            "Histori Transaksi",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Get.to(() => const ProfileView());
              },
              icon: const Icon(Icons.settings, color: Colors.white, size: 32.0),
            ),
          ],
          backgroundColor: primaryColor,
        ),
        body: Container(
          padding: const EdgeInsets.only(left: 20.0, top: 30.0, right: 20.0),
          height: MediaQuery.of(context).size.height - appBarHeight,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(44.0),
              topRight: Radius.circular(44.0),
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Filters Display (Optional, skipping for clean UI, user can see in modal)
              // Date Range Display
              Obx(() {
                final range = controller.selectedDateRange.value;
                String dateText = "Semua Waktu";
                if (range != null) {
                  final start = range.start;
                  final end = range.end;
                  if (start.year == end.year && start.month == end.month) {
                    dateText = DateFormat("MMMM yyyy", "id").format(start);
                  } else {
                    dateText =
                        "${DateFormat("dd MMM yyyy", "id").format(start)} - ${DateFormat("dd MMM yyyy", "id").format(end)}";
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                );
              }),

              // Summaries
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.green,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Pemasukan",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              "Rp. ${NumberFormat.decimalPattern('id').format(controller.totalIncome.value)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Pengeluaran",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              "Rp. ${NumberFormat.decimalPattern('id').format(controller.totalExpense.value)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Obx(() {
                  if (controller.filteredHistories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.history, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "Tidak ada data",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.filteredHistories.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final item = controller.filteredHistories[index];
                      return _buildTransactionItem(item, controller);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "btn_filter_history",
          onPressed: () => _showFilterModal(context, controller),
          backgroundColor: primaryColor,
          child: const Icon(Icons.filter_list, color: Colors.white),
        ),
      );
    });
  }

  Widget _buildTransactionItem(
    dynamic item,
    HistoryTransactionController controller,
  ) {
    // item is TransactionModel
    // dynamic type casting if needed or use model directly if imported
    // Assuming item has properties matching model

    Color color = Colors.black;
    IconData icon = Icons.help;
    Color iconBg = Colors.grey.shade100;

    if (item.type == 'income') {
      color = Colors.green;
      icon = Icons.arrow_downward;
      iconBg = Colors.green.shade50;
    } else if (item.type == 'expense') {
      color = const Color.fromARGB(255, 230, 88, 78);
      icon = Icons.arrow_upward;
      iconBg = Colors.red.shade50;
    } else {
      color = Colors.blue;
      icon = Icons.swap_horiz;
      iconBg = Colors.blue.shade50;
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => TransactionDetailView(transaction: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.walletName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (item.createdAt != null)
                    Text(
                      DateFormat("dd MMM yyyy HH:mm").format(item.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            Text(
              "Rp. ${NumberFormat.decimalPattern('id').format(item.amount)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(
    BuildContext context,
    HistoryTransactionController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Transaksi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.resetFilters();
                          Get.back();
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Date Filter
                  const Text(
                    "Tanggal",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => InkWell(
                      onTap: () async {
                        final DateTimeRange? result = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          currentDate: DateTime.now(),
                          saveText: 'Simpan',
                        );
                        if (result != null) {
                          controller.selectedDateRange.value = result;
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.selectedDateRange.value == null
                                  ? "Pilih Rentang Tanggal"
                                  : "${DateFormat('dd/MM/yy').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd/MM/yy').format(controller.selectedDateRange.value!.end)}",
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction Type
                  const Text(
                    "Jenis Transaksi",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      children:
                          ["Semua", "Pemasukan", "Pengeluaran", "Transfer"].map(
                            (type) {
                              final isSelected =
                                  controller.selectedType.value == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected)
                                    controller.selectedType.value = type;
                                },
                                selectedColor: primaryColor.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            },
                          ).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wallet Filter
                  const Text(
                    "Wallet",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: controller.selectedWallet.value.isEmpty
                          ? null
                          : controller.selectedWallet.value,
                      hint: const Text("Semua Wallet"),
                      items: [
                        const DropdownMenuItem(
                          value: "",
                          child: Text("Semua Wallet"),
                        ),
                        ...controller.walletOptions.map(
                          (w) => DropdownMenuItem(value: w, child: Text(w)),
                        ),
                      ],
                      onChanged: (val) {
                        controller.selectedWallet.value = val ?? "";
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Filter
                  const Text(
                    "Kategori",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: controller.selectedCategory.value.isEmpty
                          ? null
                          : controller.selectedCategory.value,
                      hint: const Text("Semua Kategori"),
                      items: [
                        const DropdownMenuItem(
                          value: "",
                          child: Text("Semua Kategori"),
                        ),
                        ...controller.categoryOptions.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (val) {
                        controller.selectedCategory.value = val ?? "";
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.applyFilters();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Terapkan Filter",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
