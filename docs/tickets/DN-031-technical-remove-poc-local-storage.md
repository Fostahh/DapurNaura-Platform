---
id: DN-031
type: technical
title: Delete the POC local storage — four public types, zero consumers
status: in-progress
source: —
branch: ticket/DN-031-remove-poc-local-storage
layer: data
---

## Rationale

**Owner's instruction, 2026-08-09** — given in Indonesian, recorded as the agent's English
translation per DN-010:

> *"Let's just delete it, to keep code quality."*

**Why this code exists at all, which nothing in the repository recorded until now.** The owner
supplied the missing history on 2026-08-09:

> *"This was originally my POC to prove that KMP can be exported as a library and then consumed by
> an iOS native project — both local and remote can be used. That's it. That's why LocalDataSource
> exists."*

`LocalDataSource` is the *local* half of that proof. **The proof succeeded and is finished**: DNLibrary
ships as an XCFramework through SPMDNLibrary, six versions are published, and the app builds against
it. The scaffolding's job is done. There is no requirement for local storage, and **the owner has
deliberately not implemented it** — this was never a forgotten integration.

**What the code actually is today:**

| | |
|---|---|
| Public types | `ISecureStorage`, `SecureStorage`, `IPreferenceStorage`, `PreferenceStorage` |
| Occurrences in the generated Swift header | **20** |
| Consumers in `DNDataLayer`, any repository, or Swift | **none** |
| Published since | `0.1.0` — every release so far |

So four types sit in the **binary contract**, appear in the Swift API the app compiles against, and
nothing anywhere calls them. `CODEBASE-ARCHITECTURE.md` §2 opens *"Public API — this is a binary
contract"*, and its own checklist asks *"Nothing newly `public` that should be `internal`"*. These
predate the standard, so the checklist never tripped on them — but they are exactly the case it
describes.

**This reverts DN-001, and that is worth stating plainly rather than glossing.** DN-001 encrypted the
Android `SecureStorage` with AES-GCM under an Android Keystore key, because a class named
`SecureStorage` was storing plaintext. That work was correct and the ticket stays `done`; what
changed is that the class it protected has no future consumer scheduled. The encryption is preserved
in git history and can be restored the day authentication lands.

**Alternative considered and rejected by the owner.** The agent recommended demoting the types to
`internal` instead — keeping the code, the tests and DN-001's encryption while withdrawing the public
promise. The owner chose deletion for code quality. Recorded because the reasoning may matter later:
if authentication arrives, `git log` is where the implementation lives, not a stale `internal` class.

## Context

Read before starting:

- `sharedLogic/src/*/kotlin/id/dn/fostah/dnlibrary/datasource/local/` — all eight files
- `sharedLogic/build.gradle.kts` lines 75–91 — the dependency blocks that go with them
- `docs/CODEBASE-ARCHITECTURE.md` §2 (binary contract) and `## Known violations`
- `docs/tickets/DN-001-technical-secure-storage-encryption.md` — the work being removed
- `docs/tickets/DN-004-technical-remove-scaffolding-dtos.md` — the precedent: the same sweep, done once before

Already true, and constraining:

- **This is a breaking public API change.** Per the `0.x` scheme it is a **minor** bump, not a major:
  `0.6.0` → `0.7.0`. DN-004, DN-006 and DN-008 each removed public symbols on the same terms.
- **The app pins by range since DN-030** (`>= 0.6.0, < 1.0.0`), so the next *Update to Latest* pulls
  this. The app never referenced these types, so nothing breaks — but the release must still happen
  before the app resolves forward.
- **`androidHostTest` contains exactly one file**, `SecureStorageTest.kt`. Deleting it empties the
  whole source set, and Robolectric exists solely to give that test an Android `Context` — the
  build file says so in its own comment.
- **DataStore is used by nothing else**, verified by grep across `sharedLogic/src`.
- **The four `@Ignore`d iOS Keychain cases disappear with it.** They were `@Ignore`d because the
  hostless iOS test process has no keychain; every document that explains that caveat must stop
  explaining it.
- **DN-001 stays `done` and its prose is not rewritten.** The record of what was asked and fixed on
  2026-08-06 stands; this ticket carries the correction, per the source-of-truth rule.

## Technical approach

**Delete**, in one commit:

```
commonMain/…/datasource/local/SecureStorage.kt          PreferenceStorage.kt
androidMain/…/datasource/local/SecureStorage.android.kt PreferenceStorage.android.kt
iosMain/…/datasource/local/SecureStorage.ios.kt         PreferenceStorage.ios.kt
androidHostTest/…/datasource/local/SecureStorageTest.kt
iosTest/…/datasource/local/SecureStorageIosTest.kt
```

**Then the dependencies they existed for**, which is the half a deletion usually forgets:

- `androidMain` — `libs.androidx.datastore.preferences`
- `androidHostTest` — the whole block: `robolectric`, `androidx.test.core`, `kotlinx.coroutines.test`
- `gradle/libs.versions.toml` — `datastoreVersion`, `robolectricVersion`, and the entries pointing at
  them, plus `androidx-test-core` if nothing else claims it

**Then the documents that describe them.** `DNLibrary/CLAUDE.md` loses its *Local layer* section;
`docs/CODEBASE-ARCHITECTURE.md` loses the bare-`Exception` known-violations row — **the table becomes
empty, which is the correct outcome and should be shown as such rather than deleted**; the umbrella
`CLAUDE.md` and `ARCHITECTURE-AND-WORKFLOW.md` lose the "SecureStorage is referenced by nothing"
observations, which stop being true when the class stops existing.

## Public API contract

**Removed:** `ISecureStorage`, `SecureStorage`, `IPreferenceStorage`, `PreferenceStorage`, and the
`androidMain`/`iosMain` actuals of the two `expect` classes.

**Added:** nothing.

**Version bump implied:** **minor → `0.7.0`.** A removed public symbol is a minor for the whole of
`0.x`; `1.0.0` stays reserved for the App Store release.

## Out of scope

- **Re-implementing storage anywhere.** There is no requirement, and the owner has deliberately
  deferred it. Do not reintroduce it "ready for later".
- **Rewriting DN-001.** It stays `done`, prose untouched.
- **The iOS app.** It never referenced these types; no Swift changes.
- **Publishing `0.7.0`.** Owner-triggered, after this merges.

## Test plan

1. **`./gradlew :sharedLogic:check` green** after the deletion — the gate, both platforms.
2. **Test count moves as predicted, and the delta is explained.** Before: 58 iOS + 59 Android = 117,
   of which 54 are `commonTest` counted on both. After: **54 + 54 = 108**. The 9 lost are the 5
   Android `SecureStorageTest` cases and the 4 `@Ignore`d iOS Keychain cases. **No `commonTest` case
   may disappear** — if the common count moves, something unintended was deleted.
3. **`assemble` succeeds and the generated header no longer names them** — `grep -c` for
   `SecureStorage|PreferenceStorage` in `DNLibrary.h` goes from **20 to 0**. This is the check that
   proves the public surface actually shrank, rather than the source merely moving.
4. **No orphaned dependency remains** — grep `datastore`, `robolectric` across
   `libs.versions.toml` and `build.gradle.kts` returns nothing.
5. **No dangling reference in any document** — grep `SecureStorage|PreferenceStorage` across all
   `.md` returns only the historical record: DN-001, DN-004 and this ticket.

## Done when

- [ ] All eight files deleted
- [ ] DataStore, Robolectric and the `androidHostTest` block removed; version catalog cleaned
- [ ] `:sharedLogic:check` green at **108 tests**, with `commonTest` unchanged at 54
- [ ] Generated header names them **0** times, down from 20
- [ ] `DNLibrary/CLAUDE.md`, `docs/CODEBASE-ARCHITECTURE.md`, umbrella `CLAUDE.md` and
      `ARCHITECTURE-AND-WORKFLOW.md` no longer describe storage that does not exist
- [ ] Known-violations table shown as empty rather than removed
- [ ] Committed on `ticket/DN-031-remove-poc-local-storage`, not merged

## Notes

**The POC context is the finding, more than the deletion is.** Nothing in the repository recorded
*why* these classes existed. What a cold agent saw was encrypted, tested, well-formed storage that
nothing calls — and the natural conclusion is *"someone forgot to wire this up"*, which leads either
to wiring up something deliberately deferred, or to filing a duplicate ticket, or to asking a
question that was answered months earlier. The known-violations row made it worse by promising
*"when storage gains real consumers"*, implying consumers were on the way.

That is the argument for recording deliberate divergence, and it is why the deletion is cheaper than
the alternative: **code that exists only to be explained is more expensive than code that is gone.**

Filed and scheduled on 2026-08-09, on the owner's instruction, after the agent recommended demoting
to `internal` and the owner chose deletion.
