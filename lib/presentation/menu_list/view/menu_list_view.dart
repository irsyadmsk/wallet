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
        length: 4,
        initialIndex: controller.selectedIndex.value,
        child: Scaffold(
          body: IndexedStack(
            index: controller.selectedIndex.value,
            children: [
              DashboardView(),
              HistoryTransactionView(),
              CategoryView(),
              // ProfileView(),
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
            },
            items: const [
              BottomNavigationBarItem(
                label: "Dashboard",
                icon: Icon(Icons.dashboard),
              ),
              BottomNavigationBarItem(
                label: "History",
                icon: Icon(Icons.history),
              ),

              BottomNavigationBarItem(
                label: "Kategori",
                icon: Icon(Icons.category),
              ),

              BottomNavigationBarItem(
                label: "Wallet",
                icon: Icon(Icons.wallet),
              ),
            ],
          ),
        ),
      );
    });
  }
}
