# Wallet — Design System

## Current owner mandate — 22 October 2026

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
