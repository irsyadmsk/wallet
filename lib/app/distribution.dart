/// Where this build is distributed, set at build time:
/// `--dart-define=WALLET_CHANNEL=play` for the Google Play bundle; empty for
/// the web app and the APK on GitHub Releases.
const String kDistributionChannel = String.fromEnvironment('WALLET_CHANNEL');

/// Google Play requires its own billing for tips/donations to the
/// developer, so the QRIS donation page exists only outside the Play build.
const bool kDonationsEnabled = kDistributionChannel != 'play';
