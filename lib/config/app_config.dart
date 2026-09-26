/// Konfigurasi Utama Aplikasi Money Manager
/// Dikelola dan Dimiliki oleh Muhammad Irsyad Sirojul Khoeir
class AppConfig {
  static const String appName = "Wallet";
  /// Must match `version:` in pubspec.yaml (guarded by test/version_test.dart).
  static const String appVersion = "1.3.0";
  static const String appAuthor = "Muhammad Irsyad Sirojul Khoeir";
  static const String appAuthorEmail = "irsyad.msk@gmail.com";

  // Mata Uang & Lokalisasi
  static const String defaultCurrency = "IDR";
  static const String currencySymbol = "Rp";
  static const String localeId = "id_ID";

  // Konfigurasi Backend / Remote API
  /// Ubah menjadi `true` jika ingin menghubungkan data ke server backend (Laravel, Express, Supabase, dll.)
  static const bool useRemoteApi = false;

  /// Base URL endpoint REST API
  static const String apiBaseUrl = "https://api.moneymanager.local/v1";

  /// Waktu tunggu permintaan API (dalam milidetik)
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Nama Box Hive Lokal
  static const String walletBoxName = 'walletBox';
  static const String categoryBoxName = 'categories';
  static const String transactionBoxName = 'transactions';
  static const String settingsBoxName = 'settingsBox';
}
