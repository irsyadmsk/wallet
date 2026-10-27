# AG-10 — Pengaturan tema Wallet

Pemilik meminta Antigravity Gemini 3.8 Flash High mengerjakan pekerjaan sederhana. Workspace WAJIB `C:\Users\T6N0CV02S35823C\Github\wallet`, bukan irsyads. Ini implementasi lokal, belum izin rilis. Koordinator Codex.

## Baca dan batas

Baca AGENTS.md, docs/2026-10-22_BRAND_NAVIGATION_LOCAL.md, DESIGN.md bagian mandat terbaru, .agents/skills/irsyads-resilient-delivery/SKILL.md, lalu skill flutter-fix-layout-issues atau flutter-build-responsive-layout sesuai kebutuhan. Jangan baca kredensial, .wallet-signing, .env, data pemilik, token atau Console. Jangan gunakan MCP yang bermasalah/instal pengganti. Gunakan source langsung dan alat lokal yang tersedia.

## Reservasi berkas

Hanya boleh mengubah `lib/presentation/settings/view/settings_view.dart` pada bagian Mode Tampilan dan Warna Aksen beserta helper presentasi terkait; boleh menambah widget presentasi murni di folder yang sama bila perlu. Laporan `docs/2026-10-22_AG10_SETTINGS_REPORT.md`. Semua berkas lain milik Codex; jangan edit navigasi yang telah selesai, auth, controller/storage, ledger, monthly, Android/workflow, pubspec, test existing atau shared theme tokens. Pertahankan semua dirty changes.

## Kerjakan

1. Kontrol Sistem/Terang/Gelap harus tetap terbaca dan dapat dipilih pada lebar 320/390 serta text scale 1.5, tanpa overflow. Tata letak desktop tetap ringkas. Gunakan LayoutBuilder/Wrap/tata alternatif sederhana jika diperlukan, callback dan pilihan ThemeController tetap sama.
2. Label preset pertama saat ini “Tinta Hutan”, padahal presetIrsyads sekarang academic blue. Sesuaikan label menjadi “Tinta Akademik” dan kalimat pembuka warna yang jelas. Jangan mengubah warna/preset atau menghapus pilihan aksen tersimpan. Status terpilih jangan bergantung warna saja, target sentuh minimal 48, logical RTL.
3. Jangan menyentuh bagian keamanan/PIN/account/danger zone atau mengubah perilaku simpan. Jangan merapikan seluruh file tanpa alasan.

## Bukti dan laporan

Implementasikan lalu format hanya file yang berubah. Satu analyze terarah bila SDK tersedia (lokasi SDK cari docs lokal; Flutter tidak di PATH bukan alasan install). Jangan menjalankan full build/suite/remote; uji batch akhir dikelola Codex setelah integrasi. Jika validasi tidak dapat dijalankan, laporkan pending dengan jujur. Laporan singkat berisi file/delta/pemeriksaan/keterbatasan, tidak ada data privat. Bila jaringan/kuota habis, simpan checkpoint dan hentikan operasi itu tanpa paid fallback. Tanpa commit/push/PR/Actions/deploy/upload/OTA/migrasi atau mengirim pesan ke pihak lain.
