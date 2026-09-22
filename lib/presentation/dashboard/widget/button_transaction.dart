import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core.dart';

class ButtonTransaction extends StatelessWidget {
  const ButtonTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Get.to(() => FormExpenseView()),
                  tooltip: "Tambah Pengeluaran",
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.red.withOpacity(0.12),
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Colors.red.shade700,
                    ),
                    shape: WidgetStateProperty.all(const CircleBorder()),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 22),
                ),

                const SizedBox(height: 12),

                Text(
                  "Tambah Pengeluaran",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .red
                        .shade700, // samakan dengan icon biar harmonis
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Get.to(() => FormIncomeView()),
                  tooltip: "Tambah Pemasukan",
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.green.withOpacity(0.12), // soft green background
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Colors.green.shade700, // warna ikon hijau soft
                    ),
                    shape: WidgetStateProperty.all(const CircleBorder()),
                  ),
                  icon: const Icon(Icons.arrow_downward, size: 22),
                ),

                const SizedBox(height: 12),

                Text(
                  "Tambah Pemasukan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700, // samakan dengan icon
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Get.to(() => FormTransferView()),
                  tooltip: "Transfer",
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.blue.withOpacity(0.12), // soft blue background
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      Colors.blue.shade700, // warna ikon biru soft
                    ),
                    shape: WidgetStateProperty.all(const CircleBorder()),
                  ),
                  icon: const Icon(Icons.sync_alt, size: 22), // ikon transfer
                ),

                const SizedBox(height: 12),

                Text(
                  "Transfer",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
