---
id: DN-009
type: product
title: iOS — cooking-class list screen (SwiftUI + MVVM) on GET /classes
status: done
source: — (verbal instruction from the owner, 2026-08-06 — see below)
branch: ticket/DN-009-cooking-class-list-ui
layer: both
---

## Requirement (traced)

> "Create 1 screen on DapurNaura using SwiftUI and MVVM, showing the data based on
> GET /classes API call."
> — the owner, verbally, 2026-08-06.

**Process deviation, flagged (same as DN-008):** requirement documents are deliberately deferred;
this quote is the requirement until one is backfilled.

## Context

- The data-layer slice exists: DN-008's `DNDataLayer` → `GetCookingClassesUseCase` →
  `CookingClassesResult` (in-review, branch `ticket/DN-008-cooking-class-list`).
- **No backend exists.** `docs/contracts/README.md` names the mechanism for exactly this moment:
  *"DNLibrary's stub engine replays [the contracts], so the UI is built against the real
  serialization path with no backend."* That stub path did not exist yet — this ticket adds it.
- The app has no DNLibrary dependency (removed in DN-003). Re-adding it is the first step here,
  against `ios/DNLibraryLocal` — **that wiring is never committed**.
- iOS work stacks on `ticket/DN-003-ios-build-variants` (the variants/AppConfig work is only on
  that branch). DNLibrary work stacks on `ticket/DN-008-cooking-class-list`.
- Content is Bahasa Indonesia — user-facing strings on this screen are Indonesian.

## Technical approach

**DNLibrary** — the stub data path:

- `DNDataLayer` gains an internal `IRemoteDataSource` constructor; the public config constructor
  is unchanged. New `DNDataLayer.stub()` returns an instance backed by `StubRemoteDataSource`
  (internal), which replays the contract JSON verbatim through the real DTO decoding path with a
  simulated latency, so loading states are visible.

**DapurNaura** — MVVM:

- `CookingClassListViewModel` (`@Observable`, `@MainActor`): `state` = `loading / loaded / failed`,
  `load()` awaits the use case via SKIE's async bridge, maps `DNError` to Indonesian messages.
- `CookingClassListView`: loading spinner, error + retry ("Coba Lagi"), and a list — image
  (`AsyncImage`), name, description, price as `Rp150.000`, recipe count, and a `purchaseStatus`
  badge (Sudah Dibeli / Menunggu Verifikasi / Belum Dibeli). Status is a **UI hint, never a gate**.
- `DapurNauraApp` shows the screen, constructing the ViewModel with `DNDataLayer.stub()` at the
  composition root. `[ASSUMPTION]` Switching to the live `DNDataLayer(config:)` fed from
  `AppConfig` happens when a backend exists — note that `Development.xcconfig`'s `API_BASE_URL`
  still carries the stale RAWG scaffolding URL and must be replaced at that moment.

## Public API contract

DNLibrary adds `DNDataLayer.Companion.stub()`. Nothing else moves.

**Version bump implied:** minor under `0.x` on top of DN-008's major — additive API.

## Out of scope

- Class detail / recipe screens; navigation beyond this single screen
- Purchase flow, entitlement UI beyond showing the status badge
- Swift unit/UI tests — per the platform DoD, UI is verified manually by the human
- Replacing the stale `API_BASE_URL` values in the xcconfigs (needs a real backend)

## Test plan

Data layer (`./gradlew :sharedLogic:check`): `DNDataLayer.stub()` returns `Success` with the three
contract classes through the real decoding path.

UI: built with `xcodebuild` ("DapurNaura Dev"), run on the iOS simulator, screenshot captured.
**Human verifies the running app** — the platform's UI gate.

## Implementation notes (2026-08-06)

- **Verified by the owner on the running app** (iPhone 17 Pro Max simulator, iOS 26.0) before
  anything was committed — the UI gate ran as designed; owner's verdict: beyond expectations.
- Discovery: `IPHONEOS_DEPLOYMENT_TARGET` is 26.2 while the installed simulators run 26.0, so
  `xcodebuild` offers no simulator destinations from the CLI without an override. Recorded in
  `ios/DapurNaura/CLAUDE.md` known issues; lowering the target vs updating the runtime is the
  owner's call.
- SKIE bridging notes captured in the app's CLAUDE.md: Kotlin `description` → `description_`,
  sealed results via `onEnum(of:)`, `try await useCase.invoke()`, `DNDataLayer.companion.stub()`.
- Commits: DNLibrary `fc4d233` (stub path) on `ticket/DN-009-cooking-class-list-ui` stacked on
  DN-008; iOS **`7070b55`** (screen) on `ticket/DN-009-cooking-class-list-ui` stacked on DN-003.
  The local package wiring (21-line `project.pbxproj` diff) is not committed, and remains in the
  working tree only.
- **Correction (2026-08-06).** The iOS commit was originally recorded here as `e8d9d9e`. It has
  since been amended twice by the owner — the local package reference had reached the commit, and
  the owner removed it — so the SHA above is the third and current one. Verified against
  `git show HEAD:DapurNaura.xcodeproj/project.pbxproj`, which now contains no
  `XCLocalSwiftPackageReference`. The branch is unpushed, so the rewrite cost nothing.

## Done when

- [x] Stub path implemented in DNLibrary; tests green on both platforms
- [x] `publish-spm.sh local` run; app builds against `ios/DNLibraryLocal`
- [x] Screen shows the three contract classes with loading/error states
- [x] Human verified the running app — nothing was committed until then, and the local package
      wiring is never committed
- [ ] PR merged, ticket marked `done` by the human
