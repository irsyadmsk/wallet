# Wallet — Design System

## Rencana Bulanan layout — 12 November 2026

Owner approved a redesign of the existing page (own design; ARUS stays a
reference). Presentation only: model, storage, RLS, revision checks and every
calculation are unchanged, and ticking an item still never posts a transaction.

Order: period tabs → month switcher → save status → three summary cards
(available on ink, allocated with its share bar, remainder or a named deficit)
→ "Arus alokasi", one bar split into Tetap / Langganan / Tabungan otomatis /
Dana bergulir / Sisa → actions → item list in one card per user group.
The kind is derived from the stored rule and rollover flag
(`widget/plan_kind.dart`); it is never persisted. Choosing a part in the flow
legend filters the list; the chip "Bagian: …" clears it. Salary deductions have
no kind and stay out of the bar.

Motion: amounts tween (`AnimatedMoney`), bars grow (`AnimatedProgress`), the
flow bar animates five fixed slots together so it cannot overflow mid-change,
groups fold with `AnimatedSize`. All of it is in-surface and honours
`AppMotion.reduced`; page-level motion on the web stays off. Segment colours
differ in lightness as well as hue, and a deficit carries an icon and label.

## One Wallet planner — 12 November 2026

ARUS is a visual reference, not another navigation destination. All personal
planning remains in Rencana Bulanan: fixed allocations, subscription prices
(IDR/USD, tax included or added, monthly/annual), flexible savings priorities
and weighted surplus, actual allocations and carried fund balances. Anggaran
continues tracking real category spending limits; Transaksi remains the only
ledger recording path. Do not duplicate those features under an ARUS tab.

Salary received overrides estimated net salary, and bonus is added once.
Fixed items remain fixed. Automatic savings receive base targets by priority,
then surplus by normalized weights; integer remainders are allocated stably.
Deficits are visible and automatic allocations never become negative.

Months store their own prices, FX and rules. A new month uses the saved template
(or prior month when no template exists), resets actual/checks/bonus/spending,
and snapshots matching funds' balances from the previous month. Corrections to
older months do not silently rewrite later opening balances. Salin ke template
creates a reviewable personal draft; an existing pending template is preserved.

The existing personal_monthly_plans namespace, RLS and revision-checked RPC are
retained; no new database, schema or ledger writes. New JSON properties are
additive, and old documents load with defaults. Older native clients do not
understand the added planner metadata: use the updated web planner for these
fields until native delivery is separately prepared. Financial records remain
private runtime data; never add the owner's salary or allocation examples here.

## Wallet / ARUS refresh — 12 November 2026

Owner requested the ARUS visual direction in the existing Wallet application.
This supersedes the October colour/heading direction: cool ivory `#F5F6F0`,
white cards, forest `#0C6C58`, green ink `#192E28`, and locally bundled
Plus Jakarta Sans headings and numbers. Existing visitor accent preferences
remain available; no stored preference is rewritten by this refresh.

Dashboard balance, monthly income and monthly expense have separate cards.
The three-card layout uses available content width (900px); smaller windows
stack the balance above the flow cards. Flow cards stack at narrow widths or
large text sizes. The existing hide-balance control also hides both flow totals.
Monthly planning and budget shortcuts use the existing navigation callbacks.
All figures continue to come from the existing ledger/controller.

Default card radii are 20px; overview cards use 24px. Navigation selection uses
a quiet accent tint. Existing keyboard, focus, reduced-motion and theme controls
remain. Authentication, storage, CAS, imports and transaction semantics are unchanged.

Web publication uses `[web-only]` in its commit message to skip APK publication;
analysis, targeted layout/planning tests and the web build must pass before deploy.
The published `wallet-release.json` identifies the deployed source commit.

## Previous owner mandate — 22 October 2026

The local Flutter candidate now uses IRSYADS Academic Editorial: paper
`#F4EADF`, ink `#141720`, academic blue `#2D3C57`, powder blue `#8BA2CE`,
paper shadow `#CFBEAF`. Default accent is academic blue; existing saved
visitor accent choices and named palettes remain valid. Light surfaces are
warm paper; dark surfaces are ink/slate-blue. Status colours keep their
semantic meaning. Text on visitor accents chooses a readable ink (4.5:1
minimum in the targeted palette checks), including neutral fallback when
both warm brand inks would miss it.

Playfair Display headings, Plus Jakarta Sans interface/numbers and Libre
Baskerville quotation accents are bundled in `assets/brand_fonts`, with OFL
licenses, so no runtime font fetch is required. Screen title styles are
serif; dense labels and currency remain sans. Existing icon, Arabic/CJK
fallback and reduced-motion behavior remain.

Navigation supports desktop compact/expanded and reversible focus; controls
remain 48dp. Desktop toggles retain the current form's widget state.
Preferences are widget RAM only, not persisted. Mobile keeps its existing
bottom navigation/More pattern. Monthly allocations use search/filter and
collapsible groups, without changing save/CAS/actor or financial semantics.

Implementation/evidence: `docs/2026-10-22_BRAND_NAVIGATION_LOCAL.md`.
This is a local candidate; native/update delivery and owner acceptance are
separate gates. The following design is historical, superseded for colours
and typography by this section.

## Historical direction before the owner mandate

Editorial, warm, quiet. A ledger you would keep on a good paper notebook:
ink on paper, one green accent, earthy signal colours, big confident type,
and motion that feels physical rather than decorative.

Source of truth in code: `lib/shared/theme/` (tokens) and
`lib/shared/widget/motion/` (interactive primitives).

## Colour (`app_colors.dart`)

| Token | Light | Dark | Use |
|---|---|---|---|
| `surfaceAlt` (paper) | `#F6F8F5` | `#0D1614` | page background |
| `surface` | `#FCFDFB` | `#141E1C` | cards |
| `textPrimary` (ink) | `#17272B` | `#ECEBDD` | text, primary buttons, selected nav |
| `textSecondary` | `#55615F` | `#AFB6AE` | supporting text (≥ 4.5:1 on paper) |
| `textTertiary` | `#7B8482` | `#808A84` | meta only, never body copy |
| `primary` (seed) | `#134E4A` forest | lifted automatically | accent |
| `income` / `success` | `#2F7A5B` | `#7FC8A2` | money in |
| `expense` / `danger` | `#B4452A` clay | `#EE9274` | money out, destructive |
| `warning` | `#9C6F1C` ochre | `#E5B85C` | spikes, near-limit |
| `cream` | `#E1E0CC` | — | text on the cinematic hero |

Dark mode is its own set of steps, not an inversion. A dark seed colour is
lightened until it reads as an accent on the dark ground.

Charts use `chart_palette.dart`: eight categorical hues in fixed order,
validated (lightness band, chroma, CVD and normal-vision separation) for
both modes. Magnitude bars use one hue (ink). Status is never colour alone —
always icon + label.

## Type (`app_typography.dart`)

- **Inter Tight**, medium, tracking −0.02 to −0.035em — display, headings,
  money (tabular figures).
- **DM Sans** — interface and reading text.
- **Instrument Serif** italic — one editorial accent per surface (a name
  in the greeting, the year in a report heading). Never for data.

Fonts are bundled in `assets/google_fonts/` (SIL OFL 1.1) so they render
offline and without a flash of fallback type.

## Shape & space

Cards 16px radius with a single 1px hairline border (no border + shadow
"ghost cards"). Pills only for small controls. Spacing scale 4/8/12/16/24/32/48.

## Motion (`app_motion.dart`)

| Token | Value | Use |
|---|---|---|
| `emphasized` | `cubic-bezier(0.16, 1, 0.3, 1)` | entrances, reveals |
| `standard` | `cubic-bezier(0.2, 0.8, 0.2, 1)` | hover, press, tabs |
| `morph` | `cubic-bezier(0.65, 0, 0.35, 1)` | layout rearrangement |
| `press` / `hover` / `base` / `reveal` | 120 / 180 / 240 / 700 ms | |

Rules: interaction feedback ≤ 200ms; animate transform and opacity first;
every animation checks `AppMotion.reduced(context)` and collapses to an
instant state when the OS asks for reduced motion. Looping background motion
(the hero video) always has a pause control.

## Interactive primitives (`widget/motion/`)

- **`Pressable`** — the behaviour behind every custom tappable surface:
  2px hover lift, 0.97 press sink, keyboard focus ring, haptic tick,
  semantics. Wrap anything tappable in it.
- **`WButton`** — pill button in 7 variants and 3 sizes, loading state, and
  the optional *arrow orb* (rotates −35° and pulls away from the label on
  hover) for the one main call to action on a surface.
- **`WIconButton`** — round icon button; its required `tooltip` is also the
  accessible label.
- **`PillTabs`** — segmented topic selector with an ink-filled active item.
- **`Reveal`** / **`WordsPullUp`** — one staged entrance per screen; words
  rise with an 80ms stagger.
- **`AnimatedMoney`** — tweens between amounts with tabular digits.
- **`InertiaTile`** — drag it and it springs home carrying your velocity
  ("cards have inertia", designspells.com).

Material buttons that don't use these still get hover/press/focus states
from the theme (`app_theme.dart`).

## Signature surfaces

- **Welcome** — full-bleed video hero, black nav capsule hanging from the
  top edge, `Wallet*` wordmark bottom-left, hover-reveal CTA bottom-right.
- **Feature tour** — topic selector + four insight cards; the active card
  darkens over a slow, out-of-focus gradient "photograph".
- **Dashboard** — ink net-worth card, the report's lead sentences beside it.
- **Smart report** — facts first (ledger row, projection track), then the
  narrative, then next steps.
