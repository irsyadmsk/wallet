import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/budget_model/budget_model.dart';
import 'package:financial_recording/data/models/debt_model/debt_model.dart';
import 'package:financial_recording/data/models/goal_model/goal_model.dart';
import 'package:financial_recording/data/models/monthly_plan.dart';
import 'package:financial_recording/data/models/recurring_model/recurring_model.dart';
import 'package:financial_recording/data/repositories/debt_repository.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/services/monthly_plan_service.dart';
import 'package:financial_recording/data/repositories/budget_repository.dart';
import 'package:financial_recording/data/repositories/goal_repository.dart';
import 'package:financial_recording/data/models/tx_model/tx_model.dart';
import 'package:financial_recording/data/models/crypto_model/crypto_holding_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/crypto_repository.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/ledger_service.dart';
import 'package:financial_recording/data/services/seed_service.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/domain/enums/hive_enums.dart';

/// Compile-time switch for design review and screenshots:
/// `flutter run --dart-define=WALLET_DEMO=true`. Skips sign-in and fills the
/// local boxes with illustrative data; nothing is synced. Being a `const`,
/// every demo branch is tree-shaken out of normal builds.
const bool kDemoMode = bool.fromEnvironment('WALLET_DEMO');

/// Adds `WALLET_DEMO_BIG=true` on top of demo mode to fill the ledger with
/// a few thousand rows over dozens of accounts, the size of a long-running
/// real ledger, for checking performance.
const bool kDemoBig = bool.fromEnvironment('WALLET_DEMO_BIG');

/// Illustrative ledger: four months of a household's income and spending.
/// All figures are made up.
Future<void> seedDemoData(DateTime now) async {
  final accounts = AccountRepository();
  if (accounts.all(includeArchived: true).isNotEmpty) return;
  await SeedService().seedIfEmpty();
  // The starter cash account opens at Rp 0; give it pocket money so the
  // front card in store screenshots isn't empty.
  for (final cash in accounts.all().where((a) => a.groupCode == AccountGroupType.cash.code)) {
    cash.openingBalance = 1250000;
    await accounts.upsert(cash);
  }

  const uuid = Uuid();
  final bank = AccountModel(id: uuid.v4(), name: 'Bank Syariah', groupCode: AccountGroupType.bank.code, openingBalance: 12500000, colorValue: 0xFF1F8A70);
  final wallet = AccountModel(id: uuid.v4(), name: 'Dompet digital', groupCode: AccountGroupType.ewallet.code, openingBalance: 3500000, colorValue: 0xFF2F74C8);
  final savings = AccountModel(id: uuid.v4(), name: 'Tabungan pendidikan', groupCode: AccountGroupType.savings.code, openingBalance: 18000000, colorValue: 0xFFD8612F);
  // Shows off foreign-currency and gold accounts in store screenshots.
  final dollars = AccountModel(id: uuid.v4(), name: 'Tabungan Dolar', groupCode: AccountGroupType.bank.code, openingBalance: 125000, currencyCode: 'USD', colorValue: 0xFF3B4FB8);
  final gold = AccountModel(id: uuid.v4(), name: 'Emas Antam', groupCode: AccountGroupType.gold.code, openingBalance: 10500, currencyCode: 'XAU', colorValue: 0xFFB8892E);
  for (final a in [bank, wallet, savings, dollars, gold]) {
    await accounts.upsert(a);
  }
  await QuickTemplateRepository().seedDefaultsIfEmpty();

  final cats = TxCategoryRepository();
  String cat(String name, int type) => cats.byType(type).firstWhere((c) => c.name == name).id;
  final txs = TxRepository();

  Future<void> add(TxType type, int amount, DateTime date, String memo, String category, String who, {String? account}) async {
    await txs.put(TxModel(
      id: uuid.v4(),
      type: type,
      amount: amount,
      accountId: account ?? bank.id,
      categoryId: cat(category, type == TxType.income ? 0 : 1),
      date: date,
      memo: memo,
      createdBy: who,
      createdByName: who,
    ));
  }

  for (var back = 3; back >= 0; back--) {
    final m = DateTime(now.year, now.month - back, 1);
    DateTime d(int day) => DateTime(m.year, m.month, day, 9 + day % 8);
    final lastDay = back == 0 ? now.day : DateTime(m.year, m.month + 1, 0).day;
    bool has(int day) => day <= lastDay;

    if (has(1)) await add(TxType.income, 7500000, d(1), 'Gaji madrasah', 'Gaji', 'Irsyad');
    if (has(3)) await add(TxType.income, 1250000, d(3), 'Honor penelitian', 'Bonus', 'Irsyad');
    if (has(5)) await add(TxType.expense, 54990, d(5), 'Netflix', 'Hiburan', 'Irsyad', account: wallet.id);
    if (has(6)) await add(TxType.expense, 1150000, d(6), 'Belanja bulanan', 'Kebutuhan harian', 'Istri');
    if (has(8)) await add(TxType.expense, 350000, d(8), 'Bensin Pertamina', 'Transportasi', 'Irsyad', account: wallet.id);
    if (has(10)) await add(TxType.expense, 275000, d(10), 'Buku referensi', 'Pendidikan', 'Irsyad');
    for (final day in [4, 9, 13, 18, 23, 27]) {
      if (has(day)) await add(TxType.expense, 28000 + day * 500, d(day), 'Kopi Kenangan', 'Makanan', day.isEven ? 'Irsyad' : 'Istri', account: wallet.id);
    }
    for (final day in [7, 14, 21, 28]) {
      if (has(day)) await add(TxType.expense, 185000 + back * 12000, d(day), 'Makan keluarga', 'Makanan', 'Istri');
    }
    if (has(15)) await add(TxType.expense, 420000, d(15), 'Periksa gigi', 'Kesehatan', 'Istri');
    // This month's outing is well above the usual — shows the spike detector.
    if (back == 0 && has(12)) await add(TxType.expense, 950000, d(12), 'Liburan akhir pekan', 'Hiburan', 'Istri');
    if (back > 0 && has(20)) await add(TxType.expense, 160000, d(20), 'Bioskop', 'Hiburan', 'Irsyad');
  }
  final crypto = CryptoRepository();
  await crypto.upsert(CryptoHoldingModel(
    id: uuid.v4(), coinId: 'bitcoin', symbol: 'BTC', name: 'Bitcoin', amount: 0.0125, costBasis: 15000000,
    imageUrl: 'https://coin-images.coingecko.com/coins/images/1/thumb/bitcoin.png',
  ));
  await crypto.upsert(CryptoHoldingModel(
    id: uuid.v4(), coinId: 'ethereum', symbol: 'ETH', name: 'Ethereum', amount: 0.4, costBasis: 22000000,
    imageUrl: 'https://coin-images.coingecko.com/coins/images/279/thumb/ethereum.png', note: 'Disimpan di Indodax',
  ));
  if (kDemoBig) await _seedBulk(now, [bank.id, wallet.id, savings.id], cats);
  // A monthly budget and two savings goals, so those screens aren't empty.
  final month = DateTime(now.year, now.month);
  final budgets = BudgetRepository();
  await budgets.upsert(BudgetModel(id: uuid.v4(), isTotal: true, amount: 6000000, startMonth: month));
  for (final (name, limit) in [('Makanan', 2000000), ('Transportasi', 800000), ('Hiburan', 500000)]) {
    await budgets.upsert(BudgetModel(id: uuid.v4(), categoryId: cat(name, 1), amount: limit, startMonth: month));
  }
  final goals = FinancialGoalRepository();
  await goals.upsert(FinancialGoalModel(id: uuid.v4(), title: 'Dana Darurat', targetAmount: 30000000, currentAmount: 12500000, colorValue: 0xFF1F8A70));
  await goals.upsert(FinancialGoalModel(
    id: uuid.v4(),
    title: 'Umroh Keluarga',
    targetAmount: 60000000,
    currentAmount: 18000000,
    targetDate: DateTime(now.year + 1, 10),
    colorValue: 0xFFB8892E,
  ));

  // Upcoming bills and a debt, so the bill calendar and the reminders have
  // something to show. Dates stay in the future: nothing is auto-posted.
  DateTime ahead(int days) => DateTime(now.year, now.month, now.day + days, 8);
  final recurring = RecurringRepository();
  for (final (memo, type, amount, category, days, auto) in [
    ('Internet rumah', TxType.expense, 350000, 'Kebutuhan harian', 1, true),
    ('SPP sekolah', TxType.expense, 750000, 'Pendidikan', 6, false),
    ('Langganan film', TxType.expense, 120000, 'Hiburan', 12, true),
  ]) {
    await recurring.upsert(RecurringRuleModel(
      id: uuid.v4(), type: type, amount: amount, accountId: bank.id,
      categoryId: cat(category, 1), memo: memo, startDate: ahead(days), autoPost: auto,
    ));
  }
  await DebtRepository().upsert(DebtLoanModel(
    id: uuid.v4(), isLoan: false, personName: 'Koperasi sekolah',
    totalAmount: 3000000, remainingAmount: 1800000, dueDate: ahead(3),
  ));

  await LedgerService().recomputeAllBalances();
}

/// An illustrative plan for the demo build, kept in memory: it is never
/// stored or synced, and its links point at the demo ledger above.
class DemoPlanService extends MonthlyPlanService {
  DemoPlanService() : super('demo');
  final _saved = <String, PlanSnapshot>{};

  @override
  Future<PlanSnapshot?> cached(String period) async => _saved[period];
  @override
  Future<PlanSnapshot?> remote(String period) async =>
      period == 'template' ? PlanSnapshot(_template(), 1) : _saved[period];
  @override
  Future<void> store(String period, PlanSnapshot snapshot) async => _saved[period] = snapshot;
  @override
  Future<PlanSnapshot> save(String period, PlanSnapshot snapshot) async =>
      _saved[period] = PlanSnapshot(snapshot.plan, snapshot.revision + 1);

  MonthlyPlan _template() {
    String? id<T>(Iterable<T> all, bool Function(T) test, String Function(T) of) {
      for (final e in all) {
        if (test(e)) return of(e);
      }
      return null;
    }
    final food = id(TxCategoryRepository().byType(1), (c) => c.name == 'Makanan', (c) => c.id);
    final wallet = id(AccountRepository().all(), (a) => a.name == 'Dompet digital', (a) => a.id);
    final goal = id(FinancialGoalRepository().all(), (g) => g.title == 'Dana Darurat', (g) => g.id);
    return MonthlyPlan(gross: 9500000, fx: 16500, items: [
      const AllocationItem(id: 'cut', group: 'Potongan gaji', name: 'Iuran koperasi', amount: 500000),
      const AllocationItem(id: 'rent', group: 'Rumah', name: 'Sewa rumah', amount: 1800000, done: true),
      const AllocationItem(id: 'power', group: 'Rumah', name: 'Listrik dan air', amount: 450000),
      AllocationItem(id: 'food', group: 'Rumah', name: 'Belanja dapur', amount: 2000000,
        categoryId: food, accountId: wallet),
      const AllocationItem(id: 'film', group: 'Langganan', name: 'Langganan film', amount: 0,
        rule: PlanRule(kind: 'subscription', price: 120000, taxIncluded: true)),
      const AllocationItem(id: 'cloud', group: 'Langganan', name: 'Penyimpanan awan', amount: 0,
        rule: PlanRule(kind: 'subscription', currency: 'USD', price: 1000, taxBps: 1100)),
      AllocationItem(id: 'safe', group: 'Tabungan', name: 'Dana darurat', amount: 0, goalId: goal,
        rule: const PlanRule(kind: 'saving', target: 800000, weight: 4, priority: 1)),
      const AllocationItem(id: 'school', group: 'Tabungan', name: 'Pendidikan', amount: 0,
        rule: PlanRule(kind: 'saving', target: 600000, weight: 3, priority: 2)),
      const AllocationItem(id: 'trip', group: 'Dana', name: 'Liburan', amount: 300000,
        opening: 900000, rollover: true),
    ]);
  }
}

Future<void> _seedBulk(DateTime now, List<String> baseAccounts, TxCategoryRepository cats) async {
  const uuid = Uuid();
  final accounts = AccountRepository();
  final ids = [...baseAccounts];
  for (var i = 0; i < 30; i++) {
    final a = AccountModel(id: uuid.v4(), name: 'Rekening ${i + 1}', groupCode: AccountGroupType.bank.code, openingBalance: 1000000 * i, colorValue: 0xFF4F46E5);
    await accounts.upsert(a);
    ids.add(a.id);
  }
  final expense = cats.byType(1);
  final income = cats.byType(0);
  final rows = <TxModel>[];
  for (var i = 0; i < 5000; i++) {
    final isIncome = i % 9 == 0;
    final c = isIncome ? income[i % income.length] : expense[i % expense.length];
    rows.add(TxModel(
      id: uuid.v4(),
      type: isIncome ? TxType.income : TxType.expense,
      amount: 10000 + (i * 7919) % 900000,
      accountId: ids[i % ids.length],
      categoryId: c.id,
      date: now.subtract(Duration(hours: 7 * i + 3)),
      memo: 'Catatan ke-$i',
    ));
  }
  await TxRepository().putAllFresh(rows);
}
