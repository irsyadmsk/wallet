import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// The currency the user reads their totals in (Saldo total on Beranda and
/// Akun). Balances are still kept per account; only the total is shown
/// converted, at the latest rate. Remembered on this device.
abstract class DisplayCurrency {
  static const _key = 'display_currency';
  static final code = ValueNotifier<String>(Currency.idr);

  static Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      if (saved != null && Currency.all.any((c) => c.code == saved)) code.value = saved;
    } catch (_) {
      // Storage unavailable: stay on rupiah.
    }
  }

  static Future<void> set(String next) async {
    code.value = next;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, next);
    } catch (_) {}
  }

  /// [idr] in the chosen currency (or [as]). Falls back to rupiah while
  /// that currency's rate hasn't been fetched yet, so a total never reads 0.
  static String format(int idr, [String? as]) {
    final c = as ?? code.value;
    final fx = CurrencyService.instance;
    if (c == Currency.idr || !fx.hasRate(c)) return idr.rupiah;
    return Currency.of(c).format(fx.fromIdr(idr, c));
  }

  static String get symbol {
    final c = code.value;
    return c == Currency.idr || !CurrencyService.instance.hasRate(c) ? 'Rp' : Currency.of(c).symbol;
  }

  /// Bottom sheet listing every currency with a known rate; picking one
  /// switches all totals.
  static Future<void> pick(BuildContext context, {int? previewIdr}) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Tampilkan total dalam', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final c in Currency.all)
              if (c.isRupiah || CurrencyService.instance.hasRate(c.code))
                ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                  title: Text('${c.name} (${c.code})'),
                  subtitle: previewIdr == null ? null : Text(format(previewIdr, c.code)),
                  trailing: c.code == code.value ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(ctx).pop(c.code),
                ),
          ],
        ),
      ),
    );
    if (chosen != null) await set(chosen);
  }
}
