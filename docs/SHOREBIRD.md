# Update tanpa Play Store (Shorebird)

Shorebird mengirim perbaikan kode Dart (tampilan, logika, teks) langsung ke
aplikasi yang sudah terpasang. Aplikasi mengunduhnya diam-diam, dan
perbaikan aktif saat **aplikasi dibuka berikutnya**. Cara ini diizinkan
kebijakan Google Play.

Yang **tidak bisa** dikirim lewat Shorebird dan tetap butuh rilis Play
Store: perubahan di `android/` (izin, NFC, manifest), plugin baru, atau
versi Flutter baru.

## Cara kerjanya di repo ini

Semua otomatis lewat `.github/workflows/build-apk.yml` setiap ada merge ke
`main`:

| Keadaan | Yang terjadi |
| --- | --- |
| Shorebird belum aktif | Build biasa seperti sebelumnya. |
| `version:` di `pubspec.yaml` **baru** | **Rilis penuh**: APK & AAB baru di rilis `apk-latest`. AAB diunggah manual ke Play Console. Ditandai tag `release-v<versi>`. |
| `version:` **sama** dengan rilis terakhir | **Patch**: dikirim ke HP pengguna tanpa Play Store. APK di GitHub tidak berubah. |
| Versi sama, tapi ada perubahan native | Job gagal dengan pesan "naikkan version". |

Setiap patch, naikkan `appPatch` di `lib/config/app_config.dart` (dan
kembalikan ke 0 saat versi naik). Pengaturan lalu menampilkan
*v1.3.1 (pembaruan 1)* dst., tanda patch sudah terpasang.

Jadi aturannya sederhana:
- **Perbaikan kecil** → jangan naikkan versi → otomatis jadi patch.
- **Fitur besar / ubah Android** → naikkan versi → rilis baru ke Play Store.

Patch hanya sampai ke aplikasi yang dipasang dari rilis Shorebird. Rilis
pertama setelah aktivasi tetap harus dipasang/diunggah sekali secara biasa.

Build Play dan APK GitHub sekarang memakai kode yang sama; halaman donasi
QRIS disembunyikan otomatis bila aplikasi dipasang dari Play Store
(`lib/app/distribution.dart`).

## Langkah aktivasi (sekali saja)

1. **Buat akun** di <https://console.shorebird.dev> (masuk dengan Google).
2. Di Console buka **Account → API Keys → buat kunci baru**. Salin kuncinya
   (ini **rahasia**, jangan dikirim ke siapa pun, termasuk ke chat).
3. Buka <https://github.com/irsyadmsk/wallet/settings/secrets/actions> →
   **New repository secret** → Name: `SHOREBIRD_TOKEN`, Secret: tempel
   kunci tadi → **Add secret**.
4. Aplikasi tidak dibuat lewat tombol di Console, tapi lewat perintah
   `shorebird init`. Jalankan workflow **Actions → "Daftarkan ke
   Shorebird" → Run workflow** (`.github/workflows/shorebird-init.yml`):
   Wallet terdaftar di Console dan `shorebird.yaml` didorong ke branch
   `chore/shorebird-init`. Gabungkan branch itu lewat pull request.
5. Build pertama setelah `shorebird.yaml` masuk ke `main` otomatis menjadi
   rilis Shorebird untuk versi saat itu (belum ada tag `release-v<versi>`).
6. Unggah `wallet.aab` dari rilis `apk-latest` ke Play Console seperti
   biasa, dan pasang ulang `wallet.apk` di HP. Mulai saat itu perbaikan
   kecil datang sendiri.

## Biaya

Paket gratis Shorebird cukup untuk pemakaian pribadi/kecil (ribuan
pemasangan patch per bulan). Cek angka terbaru di <https://shorebird.dev/pricing>.
