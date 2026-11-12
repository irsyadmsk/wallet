import 'package:financial_recording/domain/enums/account_group_type.dart';

/// A one-tap starting point for a new account: name, group and colour, plus
/// the bundled logo when one exists. Colours approximate each brand; a preset
/// without [logo] shows a monogram instead of an unlicensed mark.
class AccountPreset {
  const AccountPreset(this.name, this.group, this.color, [this.logo]);
  final String name;
  final AccountGroupType group;
  final int color;

  /// Key into `assets/icon_pack/bank_logo/`, or null for a monogram.
  final String? logo;
}

const accountPresets = <AccountPreset>[
  AccountPreset('GoPay', AccountGroupType.ewallet, 0xFF00AED6, 'gopay'),
  AccountPreset('OVO', AccountGroupType.ewallet, 0xFF4C2A86, 'ovo'),
  AccountPreset('DANA', AccountGroupType.ewallet, 0xFF118EEA, 'dana'),
  AccountPreset('ShopeePay', AccountGroupType.ewallet, 0xFFEE4D2D, 'shopeepay'),
  AccountPreset('LinkAja', AccountGroupType.ewallet, 0xFFE82529, 'linkaja'),
  AccountPreset('JakOne Pay', AccountGroupType.ewallet, 0xFFC8102E),
  AccountPreset('Bank DKI', AccountGroupType.bank, 0xFFC8102E),
  AccountPreset('Bank Jakarta', AccountGroupType.bank, 0xFFC8102E),
  AccountPreset('BCA', AccountGroupType.bank, 0xFF0060AF, 'bca'),
  AccountPreset('Mandiri', AccountGroupType.bank, 0xFF003D79, 'mandiri'),
  AccountPreset('BRI', AccountGroupType.bank, 0xFF00529C, 'bri'),
  AccountPreset('BNI', AccountGroupType.bank, 0xFFF15A23, 'bni'),
  AccountPreset('BSI', AccountGroupType.bank, 0xFF00A39D, 'bank syariah indonesia'),
];

List<AccountPreset> accountPresetsFor(int groupCode) =>
    [for (final p in accountPresets) if (p.group.code == groupCode) p];

/// Up to two letters for an account without a logo: "JakOne Pay" → "JP",
/// "Bank DKI" → "BD", "OVO" → "OV".
String accountMonogram(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
  if (words.length == 1) {
    final r = words.first.runes.take(2);
    return String.fromCharCodes(r).toUpperCase();
  }
  return first(words[0]) + first(words[1]);
}
