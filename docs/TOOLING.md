# Alat pengembangan & skill AI

Semua alat di bawah ini sudah dipasang atau dikonfigurasi di repositori.
Jalankan perintah dari akar repositori.

## Skill Claude Code (`.claude/skills/`, terkunci di `skills-lock.json`)

| Paket | Kegunaan di proyek ini |
|---|---|
| `Athevon/genjutsu` (`cast`, `paint`, `ui-ux-pro-max`, motion/graphics sub-skill) | arah visual & mikro-interaksi |
| `zanwei/design-dna` | ekstraksi token desain dari referensi |
| `greensock/gsap-skills` | referensi pola animasi (timeline, stagger, ScrollTrigger) |
| `CloudAI-X/threejs-skills` | efek 3D/WebGL bila dibutuhkan |
| `LottieFiles/motion-design-skill` | prinsip timing, easing, koreografi |
| `pbakaus/impeccable` | desain, `polish`, `audit`, `critique` |
| `ibelick/ui-skills` → `baseline-ui` | bersih-bersih tata letak & tipografi |
| `vercel-labs/agent-skills` → `web-design-guidelines` | cek pra-rilis |
| `supabase/agent-skills` | praktik terbaik Supabase & Postgres |
| `usestrix/strix` | pentest & pemindaian keamanan |
| `playwright-cli` | otomasi browser |

Pulihkan di mesin lain: `npx skills experimental_install`.

> **Catatan framer-motion:** aplikasi ini Flutter, bukan React, sehingga
> `npm i framer-motion` tidak dapat dipakai. Padanannya adalah
> `flutter_animate` (sudah menjadi dependensi) plus primitif di
> `lib/shared/widget/motion/` — pull-up per kata, stagger, spring, hover-reveal,
> dan inersia diterjemahkan langsung dari pola framer-motion pada referensi.

## Server MCP (`.mcp.json`)

- **Context7** — dokumentasi pustaka terkini (`https://mcp.context7.com/mcp`).
- **Supabase** — proyek `wallet` (`bqeqcfglpijegxnpncvg`): skema, migrasi,
  log, advisor. Pertama kali dipakai akan meminta login OAuth Supabase.

## Playwright CLI

```bash
npm install -g @playwright/cli@latest
playwright-cli install --skills          # skill + unduh browser
flutter build web --release --dart-define=WALLET_DEMO=true -o build/web_demo
cd build/web_demo && python3 -m http.server 8767 &
playwright-cli open http://localhost:8767
playwright-cli resize 390 844 && playwright-cli screenshot
```

`WALLET_DEMO=true` melewati login dan mengisi data contoh lokal — hanya untuk
tinjauan desain; konstanta ini terbuang dari build normal.

## Supabase

Migrasi ada di `supabase/migrations/` dan sudah diterapkan ke proyek:
- `20260924000000_family_households.sql` — tabel keluarga, RPC undangan,
  RLS "buku kas sendiri atau buku kas keluarga".
- `20260924000100_sync_realtime.sql` — publikasi Realtime untuk sinkron langsung.

Disarankan: aktifkan **Leaked password protection** di Dashboard → Authentication
→ Password Security (advisor keamanan Supabase menandainya nonaktif).

## Strix (pentest)

Butuh Docker dan kunci API LLM milik Anda sendiri:

```bash
curl -sSL https://strix.ai/install | bash
export STRIX_LLM="<penyedia/model>" LLM_API_KEY="<kunci>"
strix --target ./                            # white-box: kode sumber
strix --target https://wallet.irsyads.com    # black-box: aplikasi web
```

Hasil tersimpan di `strix_runs/` (diabaikan git karena bisa berisi payload PoC).

## SkillUI

Mengekstrak sistem desain sebuah situs menjadi skill Claude:

```bash
npx skillui --url https://situs-referensi.com
```
