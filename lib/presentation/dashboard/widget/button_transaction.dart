import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/presentation/form_expense/view/form_expense_view.dart';
import 'package:financial_recording/presentation/form_income/view/form_income_view.dart';
import 'package:financial_recording/presentation/form_transfer/view/form_transfer_view.dart';

class ButtonTransaction extends StatelessWidget {
  const ButtonTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            label: "Pengeluaran",
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            onTap: () => Get.to(() => const FormExpenseView()),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
          _buildActionButton(
            label: "Pemasukan",
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFD1FAE5),
            onTap: () => Get.to(() => const FormIncomeView()),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
          _buildActionButton(
            label: "Transfer",
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF0EA5E9),
            bgColor: const Color(0xFFE0F2FE),
            onTap: () => Get.to(() => const FormTransferView()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
