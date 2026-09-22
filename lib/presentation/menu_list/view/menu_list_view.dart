import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';

class MenuListView extends StatelessWidget {
  const MenuListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MenuListController());

    return Obx(() {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: const [
            DashboardView(),
            HistoryTransactionView(),
            AnalyticsView(),
            CategoryView(),
            WalletView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    controller: controller,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: "Riwayat",
                    controller: controller,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    label: "Laporan",
                    controller: controller,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: "Kategori",
                    controller: controller,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: "Dompet",
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MenuListController controller,
  }) {
    final isSelected = controller.selectedIndex.value == index;

    return InkWell(
      onTap: () {
        controller.selectedIndex.value = index;
        if (index == 0 && Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().initializeData();
        } else if (index == 2 && Get.isRegistered<AnalyticsController>()) {
          Get.find<AnalyticsController>().loadAnalytics();
        } else if (index == 1 && Get.isRegistered<HistoryTransactionController>()) {
          Get.find<HistoryTransactionController>().initializeData();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
