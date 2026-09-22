import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/presentation/account_detail/controller/account_detail_controller.dart';
import 'package:financial_recording/shared/widget/section_card.dart';
import 'package:financial_recording/presentation/accounts/widget/account_editor_sheet.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/widget/account_avatar.dart';
import 'package:financial_recording/shared/widget/tx_tile.dart';
import 'package:financial_recording/shared/widget/zen_background.dart';
import 'package:financial_recording/util/money/money_format.dart';

class AccountDetailView extends StatelessWidget {
  const AccountDetailView({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AccountDetailController(accountId), tag: accountId);
    final colors = context.colors;

    return Obx(() {
      final account = c.account.value;
      return ZenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(account?.name ?? 'Akun'),
            actions: [
              if (account != null)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final result = await showAdaptiveSheet<AccountEditorResult>(
                      context,
                      builder: (_) => AccountEditorSheet(existing: account),
                    );
                    if (result?.saved != null) {
                      await c.saveAccount(result!.saved!);
                    }
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
          child: ContentShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (account != null) AccountAvatar(account: account, radius: 20),
                            if (account != null) const SizedBox(width: AppSpacing.md),
                            Text('Saldo', style: TextStyle(color: colors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (account?.cachedBalance ?? 0).rupiah,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(label: 'Masuk bulan ini', value: c.monthIncome.value.rupiah, color: colors.income),
                            ),
                            Expanded(
                              child: _Stat(label: 'Keluar bulan ini', value: c.monthExpense.value.rupiah, color: colors.expense),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (c.balanceHistory.length > 1) ...[
                  SectionCard(
                    title: 'Riwayat saldo',
                    child: SizedBox(
                      height: 160,
                      child: _BalanceHistoryChart(points: c.balanceHistory),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text('Riwayat transaksi', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: c.transactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('Belum ada transaksi di akun ini.'),
                        )
                      : Column(
                          children: [
                            for (final tx in c.transactions)
                              TxTile(
                                tx: tx,
                                onTap: () async {
                                  final saved = await showAdaptiveSheet<bool>(
                                    context,
                                    builder: (_) => FormTxView(existing: tx),
                                  );
                                  if (saved == true) c.refresh();
                                },
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  });
  }
}

class _BalanceHistoryChart extends StatelessWidget {
  const _BalanceHistoryChart({required this.points});
  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final values = points.map((p) => p.balance).toList();
    final minY = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    final pad = (maxY - minY).abs() * 0.15;
    final lineColor = values.last >= values.first ? colors.income : colors.expense;

    return LineChart(
      LineChartData(
        minY: minY - (pad == 0 ? 1 : pad),
        maxY: maxY + (pad == 0 ? 1 : pad),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY).abs() / 3 == 0 ? 1 : (maxY - minY).abs() / 3),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(v.toInt().compact, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= points.length || (v - i).abs() > 0.01) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MMM', 'id_ID').format(points[i].month), style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.12)),
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].balance.toDouble())],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
