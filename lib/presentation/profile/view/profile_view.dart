import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/presentation/profile/controller/profile_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Profil & Pengaturan",
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Author Profile Card
            _buildAuthorCard(controller),
            const SizedBox(height: 24),

            // 2. Section: Target Anggaran Bulanan
            _buildSectionHeader("Target Anggaran (Budgeting)"),
            const SizedBox(height: 10),
            Obx(
              () => _buildSettingTile(
                icon: Icons.track_changes_rounded,
                iconColor: const Color(0xFF10B981),
                title: "Batas Anggaran Bulanan",
                subtitle:
                    "Rp ${NumberFormat.decimalPattern('id').format(controller.monthlyBudget.value)} / bulan",
                trailing: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                onTap: () => _showBudgetDialog(context, controller),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Section: Tampilan Aplikasi
            _buildSectionHeader("Tampilan Aplikasi"),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.palette_outlined,
              iconColor: const Color(0xFF6366F1),
              title: "Warna Tema Aplikasi",
              subtitle: "Sesuaikan warna primer antarmuka",
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
              ),
              onTap: () => _showColorPicker(context, controller),
            ),
            const SizedBox(height: 24),

            // 4. Section: Manajemen Data
            _buildSectionHeader("Manajemen Data"),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.table_chart_outlined,
              iconColor: const Color(0xFF0EA5E9),
              title: "Ekspor ke CSV (Excel)",
              subtitle: "Unduh rekap transaksi untuk spreadsheet",
              onTap: () => controller.exportToCsv(),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.cloud_upload_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: "Backup Data",
              subtitle: "Cadangkan seluruh database ke file JSON",
              onTap: () => controller.backupData(),
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.cloud_download_outlined,
              iconColor: const Color(0xFF10B981),
              title: "Restore Data",
              subtitle: "Pulihkan data transaksi dari file cadangan",
              onTap: () => controller.restoreData(),
            ),
            const SizedBox(height: 24),

            // 5. Section: Informasi Aplikasi
            _buildSectionHeader("Tentang Aplikasi"),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.monetization_on_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Money Manager",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Obx(
                            () => Text(
                              "Versi ${controller.appVersion.value}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _buildInfoRow("Pemilik Lisensi", "Muhammad Irsyad Sirojul Khoeir"),
                  const SizedBox(height: 8),
                  _buildInfoRow("Lisensi", "MIT License"),
                  const SizedBox(height: 8),
                  _buildInfoRow("Arsitektur", "Flutter • GetX • Hive • Repository"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorCard(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "MI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.userName.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    controller.userEmail.value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Pemilik Lisensi Resmi",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, ProfileController controller) {
    final textController = TextEditingController(
      text: NumberFormat.decimalPattern('id').format(controller.monthlyBudget.value),
    );

    Get.defaultDialog(
      title: "Atur Target Anggaran",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const Text(
              "Tentukan batas maksimal pengeluaran Anda dalam sebulan (Rp):",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: "Rp ",
                hintText: "5.000.000",
              ),
            ),
          ],
        ),
      ),
      textCancel: "Batal",
      textConfirm: "Simpan",
      confirmTextColor: Colors.white,
      buttonColor: primaryColor,
      onConfirm: () {
        final cleaned = textController.text.replaceAll(".", "").replaceAll(",", "").trim();
        final newLimit = int.tryParse(cleaned);
        if (newLimit != null && newLimit > 0) {
          controller.setBudget(newLimit);
          Get.back();
        } else {
          Get.snackbar("Peringatan", "Masukkan nominal angka yang valid");
        }
      },
    );
  }

  void _showColorPicker(BuildContext context, ProfileController controller) {
    Color pickerColor = primaryColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pilih Warna Tema", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updatePrimaryColor(pickerColor);
                Navigator.pop(context);
              },
              child: const Text("Terapkan"),
            ),
          ],
        );
      },
    );
  }
}
