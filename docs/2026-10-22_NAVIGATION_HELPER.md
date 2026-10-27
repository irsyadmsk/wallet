# Wallet navigation local candidate — 22 October 2026

Scope: WALLET-01 presentation, prepared by an internal Codex helper under the root agent's explicit file reservation. This is not an Antigravity dispatch or a release.

Files changed by this helper:
- `lib/shared/responsive/adaptive_scaffold.dart`
- This report.

The shell now measures its allocated width with `LayoutBuilder`. Below 600 logical pixels it retains the existing phone bar, swipe actions and More sheet; unselected phone buttons have 48-pixel width. From 600 pixels it uses an 80-pixel icon rail; expanded navigation is available from 840 pixels and is the default from 1024 pixels. Collapse/expand buttons have accessible labels/tooltips and 48-pixel targets. Every existing destination, selected index, selection callback and quick action remains supplied by the caller.

Mode fokus hides desktop/tablet navigation and leaves an always-visible `Tampilkan navigasi` button above the current page. The page remains in the same tree position during desktop compact/expanded/focus changes. Sidebar rows have minimum height 48, keyboard focus uses the existing Pressable behavior, directional borders respect RTL, and hover movement respects reduced motion. No new dependency or token definition was introduced.

Expanded navigation displays the app identity once and one Ruang Irsyads launcher. The rail also has one service launcher. Both display the existing account/sync state and theme control; compact account details appear in its tooltip/semantic label with a visible sync indicator. Rail destinations, service and account footer share a scrollable region so short windows can reach them. No auth, ledger, route, financial, sync-controller or storage behavior was changed.

Collapse and focus preferences are widget RAM only: no disk/server preference or account information is persisted. Resizing below the phone breakpoint still uses the incumbent phone widget tree; retention of page-local state across that breakpoint has not been demonstrated.

Verification: source and bounded diff reviewed only. No formatter, analyzer, widget test, build, browser/native check or remote operation was run by this helper; the root agent owns the single end-of-batch check. Actual window resizing, populated data, keyboard/screen-reader operation, RTL, reduced motion, More-sheet behavior, and page draft retention remain to be verified. Other pre-existing dirty changes were preserved. No commit, push, deploy or production write.
