---
id: DN-003
type: technical
title: iOS build variants — Development / Alpha / Beta / Release via xcconfig
status: in-review
source: —
branch: ticket/DN-003-ios-build-variants
layer: ios
---

## Rationale

The app had a single build configuration pair (Debug/Release from the Xcode template) and read its
backend URL and API key from **literals compiled into `DapurNauraApp.swift`**. Two problems:

1. **An API key was committed in source.** It was scrubbed from history in the same session that
   filed this ticket (`git reset --mixed` back to `5ae41dd Initial Commit`), but nothing stopped it
   being re-committed — there was no uncommitted place for a key to live.
2. **There was no way to point a build at a different environment.** Shipping to testers meant
   editing source, and an environment switch left no trace in review.

Four audiences need four builds, and the value that differs between them must come from
configuration rather than code.

| Variant | Backend | Logging | Audience | Distribution |
|---|---|---|---|---|
| Development | staging | on | developers, QA | Xcode only — never uploaded |
| Alpha | staging | on | family members | TestFlight → "Alpha" group |
| Beta | production | off | family + selected users | TestFlight → "Beta" group |
| Release | production | off | public | App Store |

Alpha is the earlier, less stable tier; Beta comes after it. This inverts the human's initial
description and was agreed explicitly before implementation.

## Technical approach

`Config/<Variant>.xcconfig` → `$(VAR)` placeholder in `DapurNaura/Info.plist` → `AppConfig.swift`
reads it via `Bundle.main.object(forInfoDictionaryKey:)`.

The layout is deliberately **flat**: four self-contained variant files, each with one
`#include "Secrets.xcconfig"`. An earlier `Base.xcconfig` holding shared settings, plus
`$(BASE_BUNDLE_ID)` indirection, was removed — reading a variant now takes no hops, at the cost of
repeating `INFOPLIST_FILE` and the bundle id four times. That duplication is intentional.

`Secrets.xcconfig` is gitignored (matched by **name**, so moving the folder cannot silently
un-ignore it) and holds only `STAGING_API_KEY` and `PROD_API_KEY`. URLs, bundle ids and flags stay
committed so a variant changing environment shows up in a diff.

Alpha, Beta and Release share one bundle id — they are one App Store Connect record separated by
TestFlight groups. Only Development differs (`.dev`) so a developer build can sit alongside an
installed TestFlight build.

## Out of scope

- `enableNetworkLogging` is surfaced to Swift but consumed by nothing — the app has no data layer.
  Wiring it is data-layer work; see DN-002.
- Anything consuming `AppConfig`. The plumbing is verified end to end, but no Swift code reads it
  yet, so a regression in it would currently be silent.
- Restoring the DNLibrary package reference. It was removed from `project.pbxproj` alongside this
  work — the local `../DNLibraryLocal` wiring must never be committed, and no published
  SPMDNLibrary version matches the app anyway. The app is now a **standalone SwiftUI project** and
  builds clean without it. Re-adding it is the first step of the next data-layer ticket.
- TestFlight group setup in App Store Connect.

## Verification

Manual — this is UI/tooling work, and per the platform Definition of Done unit tests are required
for the data layer only.

- [x] `DapurNaura Dev` scheme builds — `** BUILD SUCCEEDED **`
- [x] All four configurations resolve correctly via `xcodebuild -showBuildSettings`:
      bundle id `…DapurNaura.dev` / `…DapurNaura` ×3, logging `YES/YES/NO/NO`
- [x] Built `.app` bundle contains **no `.xcconfig`** — verified by inspecting the build product,
      not the settings dump. An earlier revision shipped all seven xcconfigs, `Secrets.xcconfig`
      included, inside the bundle
- [x] `Info.plist` substitution confirmed in the built product
- [x] `git status -uall` on `Config/` lists only the four variant files
- [ ] Human verifies the running app on device

## Notes for whoever picks this up

`DapurNaura/` is a **PBXFileSystemSynchronizedRootGroup** — every file added under it joins the
target automatically and gets copied into the `.app`. Anything in `Config/` must be listed in the
target's `membershipExceptions`. **Adding a file to `Config/` means unticking its Target
Membership**, or it ships inside the app.

Setting a value at target level silently defeats the xcconfig. Clearing a field's *text* in Xcode
leaves an empty-string override, which is still an override — select the **row** and press Delete.

## Done when

- [x] Committed on `ticket/DN-003-ios-build-variants`, not merged
- [ ] Human verifies the running app
- [ ] PR merged, ticket marked `done` by the human
