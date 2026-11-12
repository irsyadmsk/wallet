# Wallet motion

Remotion sources for Wallet's three videos. This folder is **not** part of the
Flutter build; only the rendered files in `web/media/` ship with the web app.

| Composition | Size | Length | Output | Use |
|---|---|---|---|---|
| `Welcome` | 1920×1080 | 10 s, seamless loop | `web/media/welcome.mp4` | Background of the welcome screen (`welcome_view.dart`) |
| `Tur` | 1080×1920 | 29 s | `web/media/tur.mp4` | Portrait feature tour for phones and social posts |
| `PlayStore` | 1920×1080 | 29 s | `web/media/playstore.mp4` | Landscape promo for the store listing |

The screens in `Tur` and `PlayStore` are drawn in React from the app's design
tokens (`src/theme.ts` mirrors `lib/shared/theme/app_colors.dart`); they are
not recordings of the running app. Every figure is synthetic. Fonts and the
app icon are read from `../assets`, so nothing is duplicated here. No bank or
e-wallet logo appears in any video.

## Render

```bash
npm install
```

```bash
npm run render
```

`npm run studio` opens the timeline for editing. Rendering needs a headless
Chrome; pass `--browser-executable=<path>` if Remotion cannot download one.

## Notes

- A Play Store promo video is supplied as a YouTube link, so `playstore.mp4`
  has to be uploaded to YouTube by the account owner first.
- Remotion is free for individuals and small teams; check its licence terms
  before using it in a larger organisation.
- Re-rendering replaces the files in `web/media/`. Keep them small: the
  welcome loop is fetched on first paint.
