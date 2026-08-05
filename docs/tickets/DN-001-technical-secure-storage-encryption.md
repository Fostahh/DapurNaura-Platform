---
id: DN-001
type: technical
title: SecureStorage stores plaintext on Android
status: in-review
source: —
branch: ticket/DN-001-secure-storage-encryption
layer: data
---

## Rationale

`SecureStorage` promises encrypted storage by its name. On iOS it delivers — the actual uses the
Keychain (`SecItemAdd`, `platform.Security.*`). **On Android it does not.**

`sharedLogic/src/androidMain/.../SecureStorage.android.kt` is plain Preferences DataStore:

```kotlin
private val Context.dnSecureStorage by preferencesDataStore(name = "dn_library_secure_storage")

actual class SecureStorage(context: Context) : ISecureStorage {
    private val dataStore = context.applicationContext.dnSecureStorage
    actual override suspend fun putString(key: String, value: String) {
        dataStore.edit { it[stringPreferencesKey(key)] = value }   // plaintext on disk
    }
}
```

Values are written unencrypted to app-private storage. The Android sandbox keeps other apps out,
but the file is readable on a rooted device and via ADB backup when `allowBackup` is on. That is
not equivalent to the Keychain guarantee the iOS side provides.

**The name is the real hazard.** A developer storing an auth token here will reasonably believe it
is encrypted, because the class says so. The two platforms currently offer materially different
security for the same API.

**Fixing now is free.** Nothing is stored in `SecureStorage` yet — no feature uses it. Once real
tokens are written, changing the storage backend requires a migration path for existing installs.
This is the cheapest moment this fix will ever be.

Payments (Midtrans) are planned for later and will introduce exactly the kind of credential this
class is meant to hold.

## Context

Read before starting:

- `sharedLogic/src/commonMain/.../local/SecureStorage.kt` — the `expect class` and `ISecureStorage`
- `sharedLogic/src/androidMain/.../local/SecureStorage.android.kt` — the defective actual
- `sharedLogic/src/iosMain/.../local/SecureStorage.ios.kt` — the Keychain actual, the behaviour to match
- `CODEBASE-STANDARD.md` §9 — storage rules
- `sharedLogic/build.gradle.kts` — `withHostTest { isIncludeAndroidResources = true }` is already
  set, so host tests can use an Android `Context`

Constraint already true: the Android actual takes a `Context` and the iOS actual takes none, so
`commonMain` cannot construct either. Both are injected from the platform edge. Do not change that.

## Technical approach

Replace the plaintext DataStore backing with encrypted-at-rest storage on Android. Options, to be
chosen during implementation:

1. **Android Keystore–derived key + encrypted values in the existing DataStore.** No new
   dependency; keeps the current storage mechanism; the encrypt/decrypt step is ours.
2. **`EncryptedSharedPreferences`** (`androidx.security:security-crypto`). Less code, but adds a
   dependency whose maintenance status should be checked before adopting.

Option 1 is preferred on the dependency-minimisation rule, but verify the Keystore handling is
correct rather than hand-rolling crypto beyond key storage.

`ISecureStorage` and the `expect class` do not change. `PreferenceStorage` is out of scope and
stays plaintext — that is deliberate and documented.

## Public API contract

**No change.** `SecureStorage` and `ISecureStorage` keep their current shape; only the Android
implementation changes.

**Version bump implied:** patch — behaviour fix, no API movement.

## Out of scope

- `PreferenceStorage` — plaintext by design, for non-sensitive flags
- Any migration path for existing stored values (there are none)
- Certificate pinning, root detection, or any other hardening
- The `NetworkManager` issues — see DN-002

## Test plan

Android host tests (`./gradlew :sharedLogic:testDebugUnitTest`):

1. `putString` then `getString` returns the original value
2. `getString` for an absent key returns `null`
3. `remove` deletes a single key, leaving others intact
4. `clear` empties the store
5. **The encryption check:** write a known plaintext value, then read the backing file's raw bytes
   and assert the plaintext does **not** appear in them. This is the test that would fail today and
   is the point of the ticket.

iOS (`./gradlew :sharedLogic:iosSimulatorArm64Test`): the same round-trip cases, to confirm the
Keychain actual is unaffected.

Gate: `./gradlew :sharedLogic:check`.

## Implementation notes (2026-08-06)

- Option 1 taken: AES-GCM with an Android Keystore key, IV prepended, Base64 into the existing
  DataStore. No new runtime dependency; test-only additions are Robolectric, androidx.test:core
  and kotlinx-coroutines-test.
- Robolectric has no Android Keystore, so the cipher and the DataStore are an **internal
  constructor seam** — host tests inject a locally generated AES key and a per-test backing file.
  The Keystore path itself runs only on a device.
- Test 5 was run against the old implementation first and failed with "plaintext value found in
  the backing file", then passed after the change.
- **Deviation from the test plan:** the iOS round-trip cases are written but `@Ignore`d — the
  hostless simulator test process has no keychain (`errSecNotAvailable`, −25291). The Keychain
  actual is untouched by this ticket; its verification stays manual on a device.
- The documented Android host-test task `testDebugUnitTest` does not exist; the real task is
  `testAndroidHostTest`. Docs corrected.

## Done when

- [x] Android `SecureStorage` encrypts values at rest
- [x] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [x] Test 5 above demonstrably fails against the current implementation and passes after
- [x] `CODEBASE-STANDARD.md` known-violations table updated
- [x] Committed on `ticket/DN-001-secure-storage-encryption` (`f263523`), not merged
- [ ] PR merged, ticket marked `done` by the human
