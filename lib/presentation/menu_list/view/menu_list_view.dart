import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';

class MenuListView extends StatelessWidget {
  const MenuListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MenuListController());

    return Obx(() {
      return DefaultTabController(
        length: 5,
        initialIndex: controller.selectedIndex.value,
        child: Scaffold(
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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey[500],
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              controller.selectedIndex.value = index;
              if (index == 2 && Get.isRegistered<AnalyticsController>()) {
                Get.find<AnalyticsController>().loadAnalytics();
              }
            },
            items: const [
              BottomNavigationBarItem(
                label: "Dashboard",
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
              ),
              BottomNavigationBarItem(
                label: "Riwayat",
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
              ),
              BottomNavigationBarItem(
                label: "Laporan",
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
              ),
              BottomNavigationBarItem(
                label: "Kategori",
                icon: Icon(Icons.category_outlined),
                activeIcon: Icon(Icons.category),
              ),
              BottomNavigationBarItem(
                label: "Dompet",
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
              ),
            ],
          ),
        ),
      );
    });
  }
}
