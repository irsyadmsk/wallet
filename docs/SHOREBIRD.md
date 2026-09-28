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
2. Di Console, **buat aplikasi** bernama `Wallet`. Salin **App ID**-nya
   (bukan rahasia) dan kirim ke Claude. Claude akan menambahkan
   `shorebird.yaml` ke repo.
3. Di Console buka **Account → API Keys → buat kunci baru**. Salin kuncinya
   (ini **rahasia**, jangan dikirim ke siapa pun, termasuk ke chat).
4. Buka <https://github.com/irsyadmsk/wallet/settings/secrets/actions> →
   **New repository secret** → Name: `SHOREBIRD_TOKEN`, Secret: tempel
   kunci tadi → **Add secret**.
5. Beri tahu Claude. Claude akan menaikkan versi agar build berikutnya
   menjadi rilis Shorebird pertama, lalu memeriksa hasilnya.
6. Unggah `wallet.aab` dari rilis `apk-latest` ke Play Console seperti
   biasa, dan pasang ulang `wallet.apk` di HP. Mulai saat itu perbaikan
   kecil datang sendiri.

## Biaya

Paket gratis Shorebird cukup untuk pemakaian pribadi/kecil (ribuan
pemasangan patch per bulan). Cek angka terbaru di <https://shorebird.dev/pricing>.
