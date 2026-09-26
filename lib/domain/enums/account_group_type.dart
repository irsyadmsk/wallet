/// Built-in account groups. Their codes are stored on every account (and
/// synced), so they never change; labels and icons can be customised per
/// user — see `AccountGroupRepository`.
enum AccountGroupType {
  cash(11, 'Tunai', isLiabilityDefault: false, icon: '💵'),
  bank(1, 'Bank', isLiabilityDefault: false, icon: '🏦'),
  card(2, 'Kartu / PayLater', isLiabilityDefault: true, icon: '💳'),
  debitCard(3, 'Kartu Debit', isLiabilityDefault: false, icon: '💳'),
  savings(4, 'Tabungan', isLiabilityDefault: false, icon: '🐷'),
  loan(5, 'Utang / Piutang', isLiabilityDefault: false, icon: '🤝'),
  prepaid(6, 'Kartu Prabayar', isLiabilityDefault: false, icon: '🎫'),
  investment(8, 'Investasi', isLiabilityDefault: false, icon: '📈'),
  crypto(12, 'Kripto', isLiabilityDefault: false, icon: '🪙'),
  minusAccount(9, 'Rekening Minus', isLiabilityDefault: true, icon: '⚠️'),
  insurance(10, 'Asuransi', isLiabilityDefault: false, icon: '🛡️'),
  other(7, 'Lainnya', isLiabilityDefault: false, icon: '📦');

  const AccountGroupType(
    this.code,
    this.label, {
    required this.isLiabilityDefault,
    required this.icon,
  });

  final int code;
  final String label;
  final bool isLiabilityDefault;
  final String icon;

  static AccountGroupType fromCode(int code) {
    return AccountGroupType.values.firstWhere(
      (g) => g.code == code,
      orElse: () => AccountGroupType.other,
    );
  }

  /// Display order on the Accounts screen (cash first, liabilities last).
  static const List<AccountGroupType> displayOrder = [
    cash,
    bank,
    debitCard,
    savings,
    prepaid,
    investment,
    crypto,
    insurance,
    loan,
    other,
    card,
    minusAccount,
  ];
}
