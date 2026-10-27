---
name: irsyads-resilient-delivery
description: Continue Irsyads Wallet batches through interrupted network, quota exhaustion, uncertain writes, helper handoffs, and web or Android update preparation. Use for a Wallet batch or its resumption, not unrelated development.
---

# Wallet batch continuity and recovery

Read the current owner instruction and irsyads/AGENTS.md, active roadmap and latest Wallet handoff. The owner now prioritizes Wallet as its own completed/tested update batch; other ecosystem backlog stays open. A planning request does not itself turn into implementation or publishing.

## Scope and workspace

- Work in Github/wallet, preserving existing dirty files. The web 1.4.2+2 release used a build override; source pubspec/AppConfig may still be 1.4.1. Resolve the target platform/base before choosing a new version. Never infer installed APK version from the website or a README.
- Read only relevant companion skills. Official skill examples are guidance: do not switch model, rewrite architecture/routing, apply global dart fix, install dependencies/MCP or run every example. Keep existing Flutter/GetX/Hive data contracts. Necessary application tests/checks belong to the end of the agreed Wallet batch; repeat affected checks only after changes/failure.
- Reserve helper files explicitly. Codex keeps financial data, actor/ledger, auth, CAS, shared contracts and integration; Antigravity gets bounded presentation files. Never send private financial examples or credentials to web helpers.

## Interruption decisions

| Situation | Next action |
| --- | --- |
| Network/DNS unavailable | Save a local checkpoint and keep source work, cached docs and offline assets useful. Do not turn a read error into an empty ledger. No pub upgrade or SDK reset to repair connectivity. |
| 429/temporary 5xx/read timeout | Respect Retry-After; at most two targeted retries for safe reads, then checkpoint and work locally. Do not poll indefinitely or switch to a paid API. |
| Write/save/upload timeout, outcome unknown | Keep request/batch/revision identifiers and draft. Read receipt/version/manifest first when possible. Do not resubmit, duplicate imports or redeploy blindly. Mark uncertain rather than saved. |
| AI/token/context or free-service allowance exhausted | Record exact file/ID/last verified state and remaining work before context ends. Pause only the affected operation; preserve offline progress. Never auto-purchase/upgrade/top-up or assign another helper to reserved files. |
| SDK/cache unavailable or disk full | Stop build/download, keep prior working artifact and drafts, record the concrete prerequisite. Never wipe build caches, credentials, Hive/IndexedDB, keystores or backups as a generic repair. |
| Helper/browser interrupted | Status remains interrupted/partial until a returned artifact is inspected. A prepared prompt is not sent, and a report is not source integration. Resume one bounded packet, avoiding duplicate work. |

When SDK/dependencies are cached, use the existing lockfile; no network or package changes are implied by this skill. If using --no-pub or offline resolution, first verify the required package configuration/cache exists. MCP absence is not permission to start/install an unreviewed server.

## Update route

- Web update affects browser/PWA; it does not update a separately installed Android APK. Preserve browser drafts/cache data; never clear all site storage to make a new version appear.
- Shorebird OTA requires an actually installed Shorebird base release, matching target version/platform, a compatible Dart-level delta and verified free allowance. Native/plugin/permission/engine/asset/font changes need specific compatibility review; do not force unsupported files into a patch.
- Otherwise prepare a full signed APK/AAB with a compatible applicationId/signing certificate and increasing versionCode. Preserve data with an in-place update, not uninstall/reinstall. A Play publication and a direct APK download are different distribution paths.
- Use local verified artifacts first; do not push main/dispatch Actions just to build. Do not claim keys/billing/installed base verified from file presence. Before the actual release, present the tested Wallet package, route, rollback and relevant quota; follow current owner authorization.
- On interrupted release, reconcile remote version/hash/receipt before retry; keep the prior working artifact. UI version, web artifact and APK/patch version have separate evidence.

## Checkpoint

Record repo, stable task IDs, reserved files, source/base version, actual delta, real checks and failures, unverified items, helper status, chosen update route, last safe next action and release state. Keep private data outside the repo. Resume from this checkpoint, not a full repeated audit.
