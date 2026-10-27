# Keluarga ikon layanan — kandidat lokal

23 Oktober 2026, Asia/Jakarta. Pemilik meminta setiap subdomain/aplikasi mempunyai ikon fungsi sendiri, berbeda dari logo web utama, memakai lima warna persis. **ICON-01** ditambahkan; seluruh 63 ID lama dipertahankan, total64/revisi21. Ini kelanjutan setelah perintah lanjut, bukan izin rilis.

## Hasil untuk ditinjau

Galeri <http://127.0.0.1:4540/> menampilkan 17 ikon, pilihan Navy/Ivory, pencarian, detail makna, contoh16/32px dan unduhan SVG/PNG. Server hanya loopback, GET/HEAD dengan whitelist berkas, tanpa storage, kredensial atau layanan eksternal. Jalankan `node scripts/preview-service-icons.mjs` dari repo jika listener berhenti. Screenshot berada di `scratch/service-icons-20261023`.

Palet ikon: Warm Ivory **#F3EDE2**, Deep Navy **#0B1D35**, Muted Academic Blue **#376A9B**, Soft Beige **#D9CCB9**, Slate Gray **#586574**. Berlaku pada keluarga ikon; tidak menimpa seluruh token tema halaman/preferensi pengguna. Geometri logo utama tetap DEFAULT_BRAND202x600; tidak mengganti logo utama Site dengan ikon dompet/kartu.

| Layanan | Simbol |
| --- | --- |
| Wallet | Dompet dan kantong uang |
| Irsyads ID | Kartu identitas |
| Academy | Topi kelulusan |
| Studio | Papan kerja dan pensil |
| Library | Koleksi buku |
| Toolkit | Kotak alat |
| Curriculum | Kalender pembelajaran |
| LessonCraft | Rencana ajar dan percikan ide |
| Mosque | Bangunan masjid |
| Letters | Amplop |
| Verify | Perisai dan tanda periksa |
| CBT | Layar ujian |
| SMART | Formulir jawaban |
| Upload | Berkas menuju penyimpanan |
| Irsyads Nota | Struk/kuitansi |
| Quran | Mushaf terbuka |
| Hadits | Riwayat/kutipan |

Quran/Hadits tetap dua bagian mandiri, terpisah dari Library. Ikon tidak menyatakan fitur itu sudah tersedia. Nota masih prototipe lokal; label layanan di galeri bukan verifikasi uptime/kelengkapan produk.

## Source dan aset

- Satu kontrak `packages/design-tokens/src/service-icons.ts`: 17 glif SVG asli yang ditulis lokal, dua varian warna, ubin, maskable, foreground adaptif, monokrom dan store. Tidak memakai font, gambar hasil AI berbayar atau referensi luar. Alias ruang/APMA/masjidku/hadis dipetakan eksplisit; nama tak dikenal tidak diam-diam memakai logo utama.
- `sublogo.ts`, `space-icons.ts`, `ServiceNavigation.tsx` dan CSS memakai ikon layanan masing-masing; Site tetap logo pemilik. Urutan, label, URL, return/redirect, bahasa dan kontrak akun dipertahankan. Source adapter `standalone-navigation.js` disesuaikan dan diuji; **ekspor standalone/v1 dan salin ke repo Toolkit/Curriculum/Mosque belum dilakukan**. Jangan menyatakan repo tersebut telah terintegrasi.
- PortalId memakai ikon ID pada emblem dan ikon layanan pada ubin. Prototipe Login/Nota memakai ikonnya; Home tetap logo utama. Perubahan hanya tampilan, tanpa mengubah handler akun/otorisasi. Preview actual component <http://127.0.0.1:4539/?lang=id> telah direstart dengan CSS build terbaru. **Auth/Turnstile tetap sintetis**, bukan login nyata.
- `scripts/generate-service-icons.mjs` menghasilkan SVG terang/gelap, PNG16/32/48/64/180/192/512/1024, maskable192/512 dan ICO di `packages/design-tokens/assets/service-icons`. Manifest mencatat palet dan SHA256. Command default hanya ekspor; `--apply-web`/`--apply-wallet` memasang aset lokal bernama eksplisit.
- Favicon/PWA/touch tujuh app monorepo (ID, Academy, Studio, Verify, Letters, CBT, SMART) diperbarui lokal. Aset Site tidak disentuh.
- Wallet: favicon/PWA, aset SVG, launcher Android5density, foreground108dp, monokromAPI33, XML adaptifAPI26/33, iOS/macOS AppIcon dan WindowsICO disiapkan. Ikon Play512 diperbarui **di berkas lokal**, bukan Console. Latar adaptif Navy; ikon iOS/store opak. `tool/make_icons.py` kini memanggil generator vektor lokal agar generator lama w* tidak menimpa aset baru; membutuhkan Node+repo irsyads berdampingan. Tidak menambah dependency.

Wallet tidak dibangun menjadi APK/AAB/web pada batch ini. Ikon menu/huruf internal Flutter dan integrasi repo eksternal masih perlu rekonsiliasi sebelum rilis seluruh ekosistem. Tidak mengubah versi, signing, ledger, data akun atau nominal. Rilis Wallet/Play sebelumnya tetap riwayat terpisah.

## Verifikasi dan pemulihan

**22 tes unik lulus**:4kontrak SVG/raster/launcher,7PortalId,5interaksi prototipe login,3geometri logo utama,1adapter navigasi,2return link. Satu tes raster awal terlalu ketat terhadap pembulatan RGB pada antialias alfa kecil; diperbaiki untuk memeriksa piksel opak dengan toleransi1tingkat dan diuji ulang lulus. Tes yang diulang tidak dihitung tambahan. Validasi170varian SVG seluruh keluarga memeriksa XML aman/warna; tes memeriksa keunikan glif, ukuran PNG, area aman foreground Wallet, ikon iOS opak, rujukan Android/ICO serta logo utama/route terjaga.

ID `astro check`:23berkas,0error/0warning,2hint existing (FormEvent dan SITUS_UTAMA). Build ID7halaman berhasil. Output build di `scratch/id-login-integration-20261023/build` memakai environment sintetis dan network guard: **DILARANG DEPLOY**. Tidak membangun ulang semua aplikasi/Wallet.

Browser: galeri desktop dan390px tidak bergulir horizontal,17aset tampil termasuk mainSVG, pilih Nota/Hadits, pencarian, varian terang/gelap berfungsi. Screenshot `desktop-gallery.png`, `icon-family.png`, `mobile-390.png`. PortalId desktop: ikon68×68, satu form dan tanpa gulir horizontal; `id-service-icon.png`. Ini bukti UI lokal, bukan acceptance pemilik/native/perangkat/Play/cache instalasi.

Generator menyimpan byte asli sebelum mengganti aset di `scratch/service-icons-20261023/backups/{irsyads,wallet}`. Receipt `receipt-*.json` mencatat hash. Percobaan pertama berhenti pada nama iOS berkarakter@ setelah web/Android selesai; guard diperbaiki secara terbatas, pengulangan melewati aset identik dan berhasil (100entri tujuan, termasuk pengulangan filename macOS). `beforeBackup` pada entri retry adalah hash backup yang tersedia; null tidak menyatakan asal berkas baru. Tidak menghapus backup atau data perangkat. `make_icons.py` lama juga dicadangkan. Kembalikan hanya tujuan tertentu dari backup bila diperlukan; jangan reset seluruh worktree yang kotor.

## Berikutnya

1. Review pemilik terhadap ikon di4540. Koreksi masuk ICON-01, tidak membuang backlog lama.
2. **ATT-04**: pemeriksaan browser dan berkas OS untuk unduh cadangan/pemulihan sebagai buku baru; pertahankan buku asal/jurnal/draf dan uji dengan data sintetis lokal. Lanjutkan gap catatan privat/manual-CBT sesuai kontrak, lalu native/akun/role/remote evidence secara terpisah.
3. Sebelum rilis ikon: rekonsiliasi konsumen eksternal/Flutter internal, tinjauan pemilik, build kandidat yang diperlukan dan konfirmasi rilis baru. HP asal Google Play memerlukan pembaruan Play pada jalur yang cocok; perubahan berkas launcher bukan pembaruan HP.

**Tidak deploy/commit/push/PR/Actions/SQL atau data produksi. Kedua remote attendance flags tetapfalse.** Tidak mengirim helper otomatis atau memakai layanan berbayar. Semua backlog lain, receipt Wallet dan rilis Studio dipertahankan.
