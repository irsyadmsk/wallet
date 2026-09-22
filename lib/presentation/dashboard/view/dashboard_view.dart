import 'package:financial_recording/presentation/dashboard/widget/button_transaction.dart';
import 'package:financial_recording/presentation/history_transaction/view/transaction_detail_view.dart';
import 'package:financial_recording/presentation/dashboard/widget/card_wallet.dart';
import 'package:financial_recording/shared/widget/icon_primary/expense_icon.dart';
import 'package:financial_recording/shared/widget/icon_primary/income_icon.dart';
import 'package:financial_recording/shared/widget/icon_primary/transfer_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final double appBarHeight = AppBar().preferredSize.height;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
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
        padding: const EdgeInsets.only(left: 30.0, top: 30.0, right: 30.0),
        height: MediaQuery.of(context).size.height - appBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(44.0),
            topRight: Radius.circular(44.0),
          ),
          color: Colors.white,
        ),
        // padding: const EdgeInsets.only(left: 30.0, top: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardWallet(controller: controller),
            const SizedBox(height: 20),
            ButtonTransaction(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transaksi",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Get.to(() => const HistoryTransactionView());
                  },
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(fontSize: 14.0, color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.transactions.length,
                  physics: const ScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final item = controller.transactions[index];
                    return ListTile(
                      onTap: () {
                        Get.to(() => TransactionDetailView(transaction: item));
                      },
                      leading: item.type == "income"
                          ? const IncomeIcon()
                          : item.type == "expense"
                          ? const ExpenseIcon()
                          : const TransferIcon(),
                      title: Text(item.categoryName),
                      subtitle: Text(
                        "Rp. ${NumberFormat.decimalPattern('id').format(item.amount)}",
                        style: TextStyle(
                          color: item.type == "income"
                              ? Colors.green
                              : item.type == "transfer"
                              ? Colors.blue
                              : const Color.fromARGB(255, 230, 88, 78),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        DateFormat("dd MMM yyyy").format(item.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
