/// Box names for the v2 (id-based) data layer. Kept separate from the
/// legacy `walletBox`/`categories`/`transactions` boxes so both can coexist
/// safely; see [lib/data/models/hive_type_ids.dart].
abstract class AppBoxes {
  static const accounts = 'accounts_v2';
  static const categories = 'categories_v2';
  static const transactions = 'transactions_v2';
  static const tags = 'tags_v2';
  static const budgets = 'budgets_v2';
  static const recurring = 'recurring_v2';
  static const settings = 'settings_v2';
  static const goals = 'goals_v2';
  static const templates = 'templates_v2';
  static const debts = 'debts_v2';
  static const memos = 'memos_v2';
}
