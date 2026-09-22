/// Best-effort match from an account's free-text name (as typed by the user
/// in Money Manager, e.g. "CC BRI Visa", "Blu BCA", "TikTok Paylater ") to
/// one of the bundled bank/e-wallet logos in `assets/icon_pack/bank_logo/`.
/// Pure Dart, no Flutter import, so it can run from the mapper on any
/// platform (including the `tool/mmbak_to_json.dart` CLI).
abstract class BankLogoMatcher {
  static const _basePath = 'assets/icon_pack/bank_logo';

  static const Map<String, String> _substringKeywords = {
    'bank syariah indonesia': 'bank syariah indonesia.png',
    'bsi': 'bank syariah indonesia.png',
    'standard chartered': 'standard chartered.png',
    'shopeepay': 'shopeepay.png',
    'spaylater': 'shopeepay.png',
    'shopee paylater': 'shopeepay.png',
    'gopay': 'gopay.png',
    'gpay': 'gpay.png',
    'ovo': 'ovo.png',
    'linkaja': 'linkaja.png',
    'kredivo': 'kredivo.png',
    'akulaku': 'akulaku.png',
    'homecredit': 'homecredit.png',
    'home credit': 'homecredit.png',
    'jenius': 'jenius.png',
    'jago': 'jago.png',
    'bareksa': 'bareksa.png',
    'bibit': 'bibit.png',
    'pluang': 'pluang.png',
    'bca': 'bca.png',
    'mandiri': 'mandiri.png',
    'bri': 'bri.png',
    'bni': 'bni.png',
    'cimb': 'cimb.png',
    'danamon': 'danamon.png',
    'permata': 'permata.png',
    'panin': 'panin.png',
    'btn': 'btn.png',
    'bjb': 'bjb.png',
    'bukopin': 'bukopin.png',
    'maybank': 'maybank.png',
    'uob': 'uob.png',
    'ocbc': 'ocbc.png',
    'hsbc': 'hsbc.png',
    'citibank': 'citi.png',
    'anz': 'anz.png',
    'digibank': 'digibank.png',
    'dbs': 'digibank.png',
    'amex': 'amex.png',
    'mastercard': 'mastercard.png',
    'jcb': 'jcb.png',
    'paypal': 'paypal.png',
    'applepay': 'applepay.png',
    'apple pay': 'applepay.png',
    'xendit': 'xendit.png',
    'midtrans': 'midtrans.png',
    'uangku': 'uangku.png',
    'paytren': 'paytren.png',
  };

  /// Short or otherwise-ambiguous keywords (common Indonesian words, or
  /// names that collide with unrelated account labels like "Dana Darurat")
  /// — only matched when they are the *entire* account name, not merely a
  /// substring of it.
  static const Map<String, String> _exactKeywords = {
    'dana': 'dana.png',
    'bi': 'bi.png',
    'mega': 'mega.png',
    'flip': 'flip.png',
    'visa': 'visa.png',
    'citi': 'citi.png',
    'doku': 'doku.png',
  };

  /// Returns an asset path like `assets/icon_pack/bank_logo/bri.png`, or
  /// null if nothing matched (caller should fall back to a plain icon).
  static String? match(String accountName) {
    final normalized = accountName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final exactFile = _exactKeywords[normalized];
    if (exactFile != null) return '$_basePath/$exactFile';

    // Longest keyword first, so e.g. "bank syariah indonesia" beats "bsi"
    // and no short keyword can ever shadow a more specific one.
    final matches = _substringKeywords.entries.where((e) => normalized.contains(e.key)).toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    if (matches.isEmpty) return null;
    return '$_basePath/${matches.first.value}';
  }
}
