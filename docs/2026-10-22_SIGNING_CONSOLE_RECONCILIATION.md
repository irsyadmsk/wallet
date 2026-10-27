# Wallet — rekonsiliasi kunci dan Console, 22 Oktober 2026

Pemilik meminta memeriksa GitHub dan Google Console, menyesuaikan, dan menyerahkan pekerjaan sederhana ke Antigravity. Semua perubahan sesi ini lokal/uncommitted. Tidak ada rotasi kunci, commit/push/Actions, upload, OTA, perubahan Google Console atau publikasi.

## Bukti aktual

| Sumber | Hasil |
| --- | --- |
| GitHub Release apk-latest, dibaca melalui konektor | Wallet 1.4.0 build 10400, commit bf799b5, aset diperbarui 29 September. Ini APK unduhan, bukan versi yang pasti terpasang pada HP pemilik. |
| APK lokal existing | applicationId com.irsyads.wallet, versionName 1.4.0, versionCode 10400. SHA-256 6258821c757b06b43d4c3db1439bc8a2d71dc75cd4ccbe3abd509930aa2ea2cb cocok digest aset GitHub. apksigner verify berhasil; sertifikat cocok cadangan. |
| AAB lokal existing | SHA-256 7246b48bbc6ed25f3002b155c12cb96354ac627fbfa83a8d1594164bd0205d7e cocok digest aset GitHub. Sertifikat jarsigner/keytool cocok cadangan. |
| Cadangan privat lokal | Ditemukan lewat rujukan docs/PLAY_STORE.md di folder privat .wallet-signing. keytool berhasil membaca PrivateKeyEntry dengan metadata yang sudah ada. Kunci/password tidak dicetak atau disalin ke dokumentasi. Pernyataan sebelumnya “tidak ditemukan” hanya berlaku pada repo/folder key yang diperiksa. |
| Google Play Console, akun developer irsyads | Wallet com.irsyads.wallet tersedia, status pengujian tertutup, daftar menampilkan pembaruan 1 Oktober. Produksi belum aktif. Tidak mengubah track atau penguji. |
| Sertifikat upload Play | Sertifikat PUBLIK upload_cert.der diunduh melalui tombol Console. Fingerprint SHA-256 EB:1E:72:0D:8E:9A:DE:23:B4:FA:73:BB:B6:BC:20:60:E6:7A:B1:27:F0:98:9D:29:14:5C:D6:B3:6C:6D:1F:08 sama dengan JKS, APK dan AAB di atas. |
| App signing Google | Console menampilkan kunci yang dikelola Google, serta kunci sebelumnya. JSON Digital Asset Links yang ditampilkan memuat A5:78:12:85:22:94:67:7F:33:3F:A6:21:DF:57:63:93:D9:B8:9F:7F:7B:B5:84:CB:0E:84:5F:4C:8F:21:9A:65, berbeda dari upload/direct APK. Sertifikat current/lineage dan APK hasil Play belum diunduh untuk verifikasi lengkap. |

Sumber metadata publik: https://github.com/irsyadmsk/wallet/releases/tag/apk-latest . Mekanisme upload/app signing: https://developer.android.com/studio/publish/app-signing . Fingerprint sertifikat adalah metadata publik; bukan private key.

## Penyesuaian lokal

- android/key.properties dibuat memakai identitas lama dan menunjuk JKS privat di luar repo. git check-ignore mengonfirmasi berkas diabaikan. Jangan menampilkan isinya/mengunggahnya ke helper.
- android/app/build.gradle.kts: release tidak lagi jatuh ke debug signing. Task release berhenti bila properti kunci tidak lengkap atau JKS tidak tersedia. Debug tetap memakai jalurnya sendiri.
- .github/workflows/build-apk.yml: material signing yang hilang menghentikan job, mengganti warning + lanjut debug sebelumnya. Tambah pemicu assets/** dan shorebird.yaml agar perubahan aset/config tidak terlewat. Ini hanya kandidat source lokal, belum mengubah workflow remote.
- Source tetap 1.4.1+1, web override 1.4.2+2. Workflow Shorebird menghitung code semver (1.4.0 -> 10400); mode Flutter tanpa token memakai run number. Dokumen lama “semua build = run number” tidak lagi berlaku umum. Maksimum code semua track Play belum dibaca, maka belum menetapkan nomor kandidat native baru.

## Jalur pembaruan

1. Browser/PWA: paket web produksi sebenarnya terpisah; preview sintetis 4520 tidak boleh dideploy.
2. APK dari GitHub: full APK baru harus memakai kunci upload/direct APK lama yang sudah cocok dan code meningkat. Uji update di tempat tanpa uninstall/clear data pada perangkat yang sesuai.
3. Instalasi dari Play: kirim AAB berkunci upload yang cocok melalui track Play yang disepakati. Jangan menganggap APK direct berkunci upload dapat menimpa instalasi bertanda tangan Google; cek sertifikat/lineage/asal instalasi.
4. OTA: font/aset dan delta Android existing memerlukan full base/compatibility review. Kehadiran shorebird.yaml bukan bukti basis installed atau free allowance. Jangan paksa patch atau menjalankan release jarak jauh untuk mencari tahu.

Belum ada bukti update fisik/versi installed pemilik, max code Play, base/free quota Shorebird, akun nyata/native/SSO atau penerimaan rilis. Pemeriksaan GitHub secrets metadata melalui gh tidak tersedia karena CLI belum login; konektor GitHub tidak mendukung secrets API. Nilai secrets GitHub memang tidak dapat dibaca balik. Tidak login CLI dengan token baru atau menjalankan Actions sebagai jalan pintas.

## Pembantu dan kelanjutan

Skill Computer Use berhasil mengakses Antigravity IDE, menggantikan keterbatasan akses pada handoff sebelumnya. Workspace sudah wallet, model tampak Gemini 3.8 Flash High. Dialog “Do you trust the authors...” masih menahan sesi; pemilik diminta klik sendiri hanya untuk wallet, tanpa trust parent Github. Aturan alat melarang otomatisasi izin keamanan.

AG-10 sudah disiapkan di docs/helper-briefs/AG10-SETTINGS-THEME.md: hanya presentasi Mode Tampilan/Warna Aksen di settings_view.dart dan laporan terkait. BELUM DIKIRIM, tidak ada hasil helper yang diklaim. Setelah dialog selesai, kirim: “Kerjakan docs/helper-briefs/AG10-SETTINGS-THEME.md. Baca batas/skill di sana dan implementasikan hanya berkas yang direservasi. Jangan rilis atau membaca kredensial.” Codex memegang signing/kontrak/data/review akhir. AG-09 lama jangan dikirim ulang. OpenCode/DeepSeek/Argon tambahan belum diperlukan untuk tugas sempit ini.

## Hasil pemeriksaan akhir sesi

- Hash APK/AAB, verifikasi APK apksigner, sertifikat JKS/AAB dan sertifikat upload Play lulus/cocok. key.properties diabaikan Git.
- `gradlew :app:validateSigningRelease --offline --console=plain` tidak selesai: konfigurasi Android berhenti karena NDK preferred `28.2.13676358` belum tersedia. Kotlin Gradle script kandidat terkompilasi (hanya warning deprecated AGP existing), tetapi task validasi signing dan guard kegagalan belum dieksekusi; jangan diklaim lulus. Build memakan sekitar 3 menit, tanpa unduh dependencies atau remote build.
- SDK lokal berisi build-tools/platform-tools/platforms, belum ada NDK atau cmdline-tools; tidak ada paket NDK cache yang ditemukan dalam pencarian nama file Downloads. Ruang C cukup. Tidak mengunduh SDK besar atau menerima lisensi baru dalam sesi pemeriksaan kunci ini.
- `git diff --check` pada perubahan signing/workflow/Play doc lulus. Board HTTP revisi 5 memuat 60 ID yang sama. Pemeriksaan aplikasi 13 tes sebelumnya tidak diulang karena sesi ini tidak mengubah Dart.
- Antigravity masih menunggu dialog trust pemilik. Tidak ada kiriman AG-10 atau hasil helper, tidak memasang OpenCode/AI lain. Koneksi browser berhenti saat sambungan ulang Console, setelah sertifikat upload berhasil diunduh; dua retry baca terbatas tidak berhasil. Maksimum code Play/sertifikat app signing lineage belum selesai; lanjut dari checkpoint, bukan mengulang seluruh audit.

Langkah berikutnya: pemilik menyelesaikan dialog trust Wallet; kirim AG-10 terbatas, review hasilnya. Codex menyiapkan prasyarat NDK/SDK dan memastikan maksimum versionCode Play/asal instalasi sebelum memilih nomor native, kemudian uji kandidat akhir yang berubah. Penerbitan menunggu paket konkret dan konfirmasi pemilik. Jangan menyamakan sertifikat cocok dengan build kandidat native atau penerimaan rilis.
