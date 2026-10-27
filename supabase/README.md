# wallet/supabase — skema proyek Supabase `wallet`

Proyek Supabase **terpisah** dari ekosistem irsyads (`mqesvxweuygplrdxchkv`). Jangan mencampur migrasi atau kunci keduanya.

## Pola tabel sinkron

Tiap box Hive di aplikasi dicerminkan ke satu tabel generik: `id`, `user_id`, `data jsonb` (hasil `toJson()` model Dart apa adanya), `updated_at` (jam server), `deleted_at` (hapus lunak). Klien menarik baris dengan `updated_at > last_sync_at`, termasuk yang terhapus, lalu menggabungkannya ke Hive. Karena itu skema Postgres tidak perlu mengikuti setiap field Dart.

- Keluarga: baris disimpan di bawah `user_id` pemilik buku kas; RLS memakai `private.accessible_ledgers()` (`20260924003923_family_households.sql`) agar anggota keluarga bisa mengakses.
- Realtime: `20260924014736_sync_realtime.sql`.

## Menambah entitas yang disinkron

1. Migrasi baru dengan pola yang sama (contoh `20260925031823_crypto_holdings.sql`).
2. Daftarkan di `lib/data/services/sync/sync_registry.dart`.
3. Tambahkan ke daftar Realtime di `lib/app/sync_controller.dart`.

## Aturan

- Nama berkas migrasi harus sama dengan versi yang tercatat di server. Jangan mengganti nama atau menyunting migrasi yang sudah diterapkan; buat berkas baru.
- Menerapkan migrasi ke produksi butuh persetujuan pemilik. `20260925095244_dedupe_reimported_transactions_20260925.sql` dan `..._wipe_and_delete_account.sql` menyentuh data pengguna; pelajari sebelum meniru.
