> **Status sesudah persetujuan:** web live; Alpha dikirim untuk review. Baca [laporan rilis](2026-10-23_WALLET_WEB_ALPHA_RELEASE.md). Dokumen di bawah mempertahankan paket dan bukti sebelum rilis.

# Wallet 1.4.3+10403 — kandidat pembaruan lokal

Tanggal: 23 Oktober 2026. Tema, font, navigasi ringkas/mode fokus, pencarian dan filter daftar bulanan, serta Pengaturan responsif AG-10 sudah terintegrasi. Pemilik mengonfirmasi instalasi HP berasal dari Google Play. Belum ada unggahan atau rilis pada batch ini.

## Paket yang tersedia

| Paket | Lokasi di repo Wallet | Bukti |
|---|---|---|
| AAB untuk pengujian Play | `build/candidate-1.4.3-10403/wallet-1.4.3-10403.aab` | 81.020.319 byte; build dan validasi struktur lulus |
| APK referensi lokal | `build/candidate-1.4.3-10403/wallet-1.4.3-10403.apk` | 99.684.012 byte; tanda tangan, metadata dan zipalign lulus |
| Web sumber utama | `build/brand-wallet-release-20261023` | Build `lib/main.dart` lulus; version.json 1.4.3+10403 |

Identitas Android: `com.irsyads.wallet`, minSdk 24/targetSdk 36. Izin dan kedua SDK sama dengan APK 1.4.0+10400. APK/AAB memuat lima font, tiga lisensi OFL dan SOURCES.md; AAB juga memuat enam entri simbol native.

Hash SHA256:

- AAB: `57499E06F9E168BDBB047C82D073BC7423ADCF1DDBF786B180BEE849DE691815`
- APK: `41D165B760743EF16C2D7944CC1150508C6399BB5D4F769B0D35CCEAEE9E959F`
- Web main.dart.js: `4233A3CFC3DF306236E2DD151F88977F07C2E7BB0484D567F57C8754258EAD95`

Sertifikat upload cocok dengan cadangan, APK lama dan Play: SHA256 `EB1E720D8E9ADE23B4FA73BBB6BC2060E67AB127F0989D29145CD6B36C6D1F08`. Tanda tangan akhir aplikasi Play berbeda. Untuk HP pemilik, gunakan AAB melalui track pengujian Play yang sama. APK referensi tidak dipakai mengganti instalasi Play. Build ini plain Flutter, bukan base atau patch Shorebird.

## Pemeriksaan

- 13 tes batch awal dan tujuh tes tambahan lulus. Tiga tes tambahan memakai SettingsView sebenarnya pada 320px/teks besar/LTR, 390px/teks besar/RTL dan desktop; empat lainnya memeriksa versi/listing/order. Ini tes terarah dengan preferensi RAM dan Auth/Sync sintetis, bukan pengujian seluruh backend.
- Analyze target berubah: nol error, nol warning, dua info deprecation Radio yang sudah ada. Diff-check dan pemeriksaan YAML/nomor pubspec workflow lulus; Actions tidak dijalankan.
- AAB: build Flutter, manifest dan `bundletool validate` lulus. Seluruh 476 payload dibaca dan diverifikasi bertanda tangan dengan sertifikat upload; nol payload tanpa tanda tangan. Jarsigner memberi peringatan sertifikat self-signed, tanpa TSA dan urutan manifest JarInputStream; validasi JarFile menyeluruh serta struktur bundle lulus.
- APK: `apksigner verify` dan zipalign 4/16KB lulus. Ini pemeriksaan paket, belum pengujian perangkat 16KB.
- Web: versi, lima font dan tiga OFL diperiksa pada hasil build terbaru. Browser acceptance build terbaru belum dilakukan.

AG-10 benar-benar dikerjakan Antigravity Gemini 3.8 Flash High di folder Wallet. Codex meninjau diff dan memperbaiki kontras indikator aksen kustom. AG-09 usang; AG-08/ARGON-04 tetap antrean sesudah Wallet. Tidak perlu mengirim ulang paket yang selesai.

Kegagalan prasyarat build dan perbaikannya dicatat dalam [handoff proses](2026-10-23_AG10_NATIVE_CONTINUATION.md). Lint/pemeriksaan simbol tetap aktif; tidak ada upgrade dependency aplikasi untuk menutupi galat. Receipt JSON dan manifest tersedia bersama paket Android.

## Yang masih perlu diterima

Pratinjau localhost 4520 masih komponen sintetis batch awal, mendahului Pengaturan AG-10. Akun nyata, penyimpanan server, persistensi lintas perangkat dan pembaruan fisik Play kandidat ini belum diterima. Jangan menerbitkan entrypoint `tool/wallet_ui_preview.dart`.

## Langkah rilis setelah konfirmasi pemilik

1. Pastikan konfirmasi mencakup AAB pada track pengujian Play yang sama dan/atau web Wallet. Verifikasi track, allowance layanan yang relevan dan receipt rilis terakhir. Snapshot Play 23 Oktober: produksi belum aktif, tujuh penguji, maksimum versionCode 10400 dari empat bundle; periksa status relevan saat publikasi.
2. Unggah AAB dengan hash di atas; gunakan `docs/play-store/whatsnew-id-ID.txt`. Jika hasil upload timeout, baca receipt dahulu sebelum mencoba ulang.
3. Perbarui HP melalui Play tanpa uninstall/clear storage. Periksa versi 1.4.3+10403, data existing, tema, navigasi, Pengaturan, bulanan, draf dan simpan yang relevan. Catat penerimaan perangkat.
4. Bila web ikut disetujui, direct deploy hasil build sumber utama yang hash-nya cocok. Tidak perlu migrasi Supabase atau impor data baru. Build lokal memakai nol menit Actions/build remote.
5. Jika gagal, pertahankan rilis sebelumnya dan draf; hentikan rollout sesuai kewenangan. Cadangan `build/recovery-1.4.0-10400` adalah backup artefak, bukan rollback data yang telah diuji. Jangan downgrade instalasi/data; perbaikan berikutnya memakai versionCode meningkat.

Repo tetap lokal dan uncommitted; perubahan lama dipertahankan. Papan rencana localhost 4515 tetap memuat 60 ID, termasuk Studio/Toolkit/Portal dan bagian Quran/Hadits terpisah dari Library.