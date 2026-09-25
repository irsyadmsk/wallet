/// Registry of every Hive `typeId` used across the app.
///
/// typeId 0-3 are the legacy (pre-v2) models and are retired: never reuse
/// them and never delete this comment block, so a future model always picks
/// a free id.
///
/// | typeId | Class                 | Box            |
/// |--------|-----------------------|----------------|
/// | 0      | UserModel (legacy)    | (unused)       |
/// | 1      | CategoryModel (legacy)| (unused)       |
/// | 2      | WalletModel (legacy)  | (unused)       |
/// | 3      | TransactionModel (legacy) | (unused)   |
/// | 4      | AccountModel          | accounts_v2    |
/// | 5      | TxCategoryModel       | categories_v2  |
/// | 6      | TxModel               | transactions_v2|
/// | 7      | TxItemModel           | (embedded)     |
/// | 8      | TagModel              | tags_v2        |
/// | 9      | BudgetModel           | budgets_v2     |
/// | 10     | RecurringRuleModel    | recurring_v2   |
/// | 11     | AppSettingsModel      | settings_v2    |
/// | 12     | TxType (enum)         | -              |
/// | 13     | BudgetPeriod (enum)   | -               |
/// | 14     | RecurrenceFreq (enum) | -               |
/// | 15     | FinancialGoalModel    | goals_v2        |
/// | 16     | QuickTemplateModel    | templates_v2    |
/// | 17     | DebtLoanModel         | debts_v2        |
/// | 18     | MemoModel             | memos_v2        |
/// | 19     | CryptoHoldingModel    | crypto_v2       |
library;
