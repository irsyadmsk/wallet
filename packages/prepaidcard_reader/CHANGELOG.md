## 0.0.1

* TODO: Describe initial release.

## 0.0.4+wallet.1 (vendored in Wallet)

- Every method call replies (`stopSession`/`startSession` never did, so an awaited stop hung forever).
- `Nfc#isAvailable` implemented; new `status()` and `openSettings()`.
- No crash on phones without NFC; clear error when NFC is off.
- Read failures (unknown card, card moved away, non-IsoDep tag) reach Dart through `onError`, which was never wired.
- Flazz card number and balance are returned instead of dropped.
