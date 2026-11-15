import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_query.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/data/services/currency/currency_service.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';
import 'package:financial_recording/presentation/form_tx/view/form_tx_view.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/util/money/money_format.dart';

/// How many category shortcuts the quick sheet offers.
const quickCategoryCount = 8;

/// The categories to offer first: the ones [recent] transactions used most,
/// then the remaining [roots] in their own order. Categories that no longer
/// exist (or are archived) are skipped.
List<TxCategoryModel> quickCategories({
  required Iterable<TxModel> recent,
  required List<TxCategoryModel> roots,
  required TxCategoryModel? Function(String id) byId,
  int limit = quickCategoryCount,
}) {
  final counts = <String, int>{};
  for (final t in recent) {
    final id = t.categoryId;
    if (id == null || id.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final ranked = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  final out = <TxCategoryModel>[];
  final seen = <String>{};
  for (final id in ranked) {
    final c = byId(id);
    if (c == null || c.isArchived || !seen.add(c.id)) continue;
    out.add(c);
    if (out.length == limit) return out;
  }
  for (final c in roots) {
    if (!seen.add(c.id)) continue;
    out.add(c);
    if (out.length == limit) break;
  }
  return out;
}

/// Records an income or expense in three moves: type the amount on the
/// built-in keypad, tap a category, save. Account and date default to the
/// last-used account and now; everything else (jam, catatan, struk, cicilan,
/// transfer) stays in the full [FormTxView], one tap away under "Detail".
///
/// Only rupiah accounts are offered here; [open] falls back to the full form
/// when there is none.
class QuickTxSheet extends StatefulWidget {
  const QuickTxSheet({super.key, this.initialType = TxType.expense});

  final TxType initialType;

  /// Opens the quick sheet, or the full form when quick entry can't apply.
  /// Returns true when a transaction was saved.
  static Future<bool> open(BuildContext context, {TxType type = TxType.expense}) async {
    final quick = type != TxType.transfer && _rupiahAccounts().isNotEmpty;
    final saved = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => quick ? QuickTxSheet(initialType: type) : FormTxView(initialType: type),
    );
    return saved == true;
  }

  static List<AccountModel> _rupiahAccounts() => [
        for (final a in AccountRepository().all())
          if (CurrencyService.instance.currencyOf(a.id) == Currency.idr) a,
      ];

  @override
  State<QuickTxSheet> createState() => _QuickTxSheetState();
}

class _QuickTxSheetState extends State<QuickTxSheet> {
  static const _maxDigits = 12;

  final _txs = TxRepository();
  final _categories = TxCategoryRepository();
  final _ledger = LedgerService();

  late final List<AccountModel> _accounts = QuickTxSheet._rupiahAccounts();
  late TxType _type = widget.initialType;
  late List<TxModel> _recent;
  late List<TxCategoryModel> _shortcuts;
  String? _accountId;
  String? _categoryId;
  int _amount = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFor(_type);
  }

  void _loadFor(TxType type) {
    final now = DateTime.now();
    _recent = _txs.query(TxQuery(from: now.subtract(const Duration(days: 90)), types: {type}));
    _shortcuts = quickCategories(
      recent: _recent,
      roots: _categories.roots(type == TxType.income ? 0 : 1),
      byId: _categories.byId,
    );
    final ids = {for (final a in _accounts) a.id};
    _accountId ??= _recent.map((t) => t.accountId).where(ids.contains).firstOrNull ?? _accounts.firstOrNull?.id;
    _categoryId = null;
  }

  void _setType(TxType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _loadFor(type);
    });
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '<') {
        _amount ~/= 10;
        return;
      }
      final next = '${_amount == 0 ? '' : _amount}$key';
      if (next.length > _maxDigits) return;
      _amount = int.tryParse(next) ?? _amount;
    });
  }

  Future<void> _save() async {
    final accountId = _accountId;
    if (accountId == null || _amount <= 0 || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final income = _type == TxType.income;
    final now = DateTime.now();
    if (income) {
      await _ledger.addIncome(accountId: accountId, categoryId: _categoryId ?? '', amount: _amount, date: now);
    } else {
      await _ledger.addExpense(accountId: accountId, categoryId: _categoryId ?? '', amount: _amount, date: now);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${income ? 'Pemasukan' : 'Pengeluaran'} ${_amount.rupiah} dicatat'),
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _openDetail() async {
    final saved = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => FormTxView(
        initialType: _type,
        initialAccountId: _accountId,
        initialAmount: _amount > 0 ? _amount : null,
        initialCategoryId: _categoryId,
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = _type == TxType.income;
    final tone = income ? c.income : c.expense;
    final account = _accounts.where((a) => a.id == _accountId).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _TypeChip(label: 'Pengeluaran', selected: !income, tone: c.expense, onTap: () => _setType(TxType.expense)),
                        const SizedBox(width: 8),
                        _TypeChip(label: 'Pemasukan', selected: income, tone: c.income, onTap: () => _setType(TxType.income)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PopupMenuButton<String>(
                        tooltip: 'Ganti akun',
                        initialValue: _accountId,
                        onSelected: (id) => setState(() => _accountId = id),
                        itemBuilder: (_) => [
                          for (final a in _accounts) PopupMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 16, color: c.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${account?.name ?? 'Pilih akun'} · hari ini',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                                ),
                              ),
                              Icon(Icons.expand_more_rounded, size: 18, color: c.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      label: 'Jumlah ${_amount.rupiah}',
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            _amount.rupiah,
                            maxLines: 1,
                            style: AppTypography.numeric(
                              size: 36,
                              weight: FontWeight.w600,
                              color: _amount == 0 ? c.textTertiary : tone,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_shortcuts.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in _shortcuts)
                            ChoiceChip(
                              label: Text(cat.isSub ? cat.name : cat.displayName),
                              selected: _categoryId == cat.id,
                              showCheckmark: false,
                              onSelected: (on) => setState(() => _categoryId = on ? cat.id : null),
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            _Keypad(onKey: _press),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _openDetail,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: const Text('Detail', maxLines: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _amount > 0 && _accountId != null && !_saving ? _save : null,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: Text(_saving ? 'Menyimpan…' : 'Simpan', maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.tone, required this.onTap});
  final String label;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Flexible(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tone.withValues(alpha: .12) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: selected ? tone : c.border),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: selected ? tone : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A fixed numeric keypad: no system keyboard to wait for, and a "000" key
/// because rupiah amounts nearly always end in thousands.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', '<'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: InkWell(
                          key: ValueKey('quick-key-$key'),
                          onTap: () => onKey(key),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          child: SizedBox(
                            height: 50,
                            child: Center(
                              child: key == '<'
                                  ? Icon(Icons.backspace_outlined, size: 22, color: c.textPrimary, semanticLabel: 'Hapus angka')
                                  : Text(
                                      key,
                                      textScaler: TextScaler.noScaling,
                                      style: AppTypography.numeric(size: 20, weight: FontWeight.w500, color: c.textPrimary),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
