---
id: DN-013
type: technical
title: Lower IPHONEOS_DEPLOYMENT_TARGET from 26.2 to 17.0 across every build configuration
status: in-review
source: —
branch: ticket/DN-013-lower-deployment-target
layer: ios
---

## Rationale

`ios/DapurNaura/DapurNaura.xcodeproj/project.pbxproj` sets `IPHONEOS_DEPLOYMENT_TARGET = 26.2` in
**all eight** build configurations (four variants × Debug/Release). That number is wrong in two
separate ways, and the owner instructed the fix directly on 2026-08-06:

> "iPhoneOS deployment target semuanya diturunkan menjadi 17 saja ya"
>
> — lower all of the iPhoneOS deployment targets to just 17.

~~**It blocks the CLI build.**~~ **This leg of the rationale turned out to be stale — see
`## Implementation notes`.** It was written from known issue 2 in `ios/DapurNaura/CLAUDE.md`, which
records that the installed simulators ran iOS 26.0 and a 26.2 floor therefore left `xcodebuild` with
no destination. The installed runtimes are now iOS 18.3, 26.0 **and 26.3**, and 26.3 satisfies a
26.2 floor, so that failure had already resolved itself before this ticket was started. It is left
here struck through rather than deleted, because a rationale that quietly loses a leg is worth
seeing.

**It excludes the audience.** A 26.2 floor ships an app almost no real device can install. Dapur
Naura's students are home cooks paying for a class, on whatever phone they already own — a high
floor locks paying customers out of content they bought. 17.0 is the lowest version that still
supports SwiftUI's `@Observable`, which the existing screen is built on, so it is the floor that
costs nothing.

Nothing about this is urgent in isolation, but it is nearly free now and gets more expensive the
more screens are written against an untested floor.

## Context

Read before starting:

- `ios/DapurNaura/CLAUDE.md` — known issue 2 (the `xcodebuild` override), the build-variant layout,
  and **the local package rule**
- The umbrella `CLAUDE.md` — `git add -A` and `git commit -a` are forbidden in `ios/DapurNaura`
- `ios/SPMDNLibrary/Package.swift` — declares `platforms: [.iOS(.v15)]`

Already true, and constraining:

- **`project.pbxproj` already carries a deliberate uncommitted diff** — roughly 21 lines wiring the
  app to `ios/DNLibraryLocal`. This ticket edits the same file. The local wiring must not reach the
  index: grep the staged version before committing, exactly as DN-009 did.
- **The library does not need to move.** `SPMDNLibrary` already declares iOS 15, below the new
  floor. But a Swift Package's declared platform and the actual `MinimumOSVersion` inside the built
  XCFramework are two different things, so the real proof is a successful link, not the manifest.
- iOS work stacks on `ticket/DN-009-cooking-class-list-ui`, the current tip in that repo.

## Technical approach

Replace all eight `IPHONEOS_DEPLOYMENT_TARGET = 26.2;` occurrences with `17.0`. Xcode writes the
value with a minor component, so `17.0` rather than the bare `17` the instruction used — the same
version, in the format the tooling produces.

Then remove known issue 2 from `ios/DapurNaura/CLAUDE.md`, including the `xcodebuild` override note
that only existed because of it.

Nothing else changes. In particular **`API_BASE_URL` is not touched** — the owner's standing rule is
that the stale value stays exactly as it is until a real backend exists, and this ticket edits build
configuration, which is precisely where the temptation would arise.

## Public API contract

None — no DNLibrary change, no version bump, `publish-spm.sh` is not run.

## Out of scope

- **`API_BASE_URL`** and every other xcconfig value. Standing owner rule.
- **Updating the simulator runtimes** — the alternative fix, not chosen.
- **Any Swift source change.** If lowering the floor turns out to break compilation, that is a
  finding to report, not a licence to start rewriting screens.

## Test plan

`layer: ios` — build configuration, so the proof is that the build works and the previous
workaround is no longer needed:

1. `xcodebuild` with **no** `IPHONEOS_DEPLOYMENT_TARGET` override now offers simulator destinations
   and builds "DapurNaura Dev" — this is the failure the ticket exists to remove, so confirm it
   fails first with the current 26.2 value, then passes after
2. All four variants still build
3. The app links against `ios/DNLibraryLocal` successfully at the lower floor — proving the
   XCFramework's real minimum, not just the manifest's claim
4. The class-list screen still runs on the simulator, verified by the human
5. `git show :DapurNaura.xcodeproj/project.pbxproj | grep -n "DNLibraryLocal\|XCLocalSwiftPackageReference"`
   returns nothing before committing

## Implementation notes (2026-08-06)

- **All eight configurations now read `17.0`** — the count was checked before and after, not
  assumed.
- **The "no simulator destinations" leg of the rationale was stale and is struck through above.**
  The installed runtimes are iOS 18.3, 26.0 and 26.3; 26.3 satisfies a 26.2 floor, so that failure
  had already gone away on its own. The test plan's "prove it fails first" step was therefore
  **not** performed — there was no failure left to reproduce, and claiming one would have been a
  fabricated result. What still justifies the ticket is the second leg: a 26.2 floor excludes
  essentially every phone the owner's students actually own.
- **What was proven.** A simulator build linked the arm64 slice at
  `-target arm64-apple-ios17.0-simulator`, pulling in `-framework DNLibrary` from
  `ios/DNLibraryLocal`. That answers the one real risk this ticket carried: the XCFramework's
  *actual* minimum OS version — as opposed to `SPMDNLibrary`'s `.iOS(.v15)` manifest claim — is low
  enough for a 17.0 floor. `@Observable`, which the DN-009 screen depends on, is iOS 17.0.
- **What was not proven, and is the owner's to run.** The full build on a concrete simulator, the
  other three variants, and the app actually running. The owner stopped the build process to do
  this manually.
- **Discovery: `DNLibrary.xcframework` has no x86_64 simulator slice** (`iosArm64` +
  `iosSimulatorArm64` only). The first build attempt used
  `-destination 'generic/platform=iOS Simulator'`, which asks for both architectures, and failed on
  the x86_64 pass while arm64 succeeded. **That failure was caused by the destination, not by this
  ticket's change.** Recorded as known issue 2 in `ios/DapurNaura/CLAUDE.md`, replacing the stale
  deployment-target note.
- **⚠️ Commit-time hazard, worth reading before staging.** `project.pbxproj` now carries **two
  unrelated sets of changes at once**: this ticket's eight deployment-target lines, and the
  uncommitted `XCLocalSwiftPackageReference "../DNLibraryLocal"` wiring that must never be
  committed. Staging the file wholesale would commit the local wiring — the exact mistake that was
  already made once on DN-009 and had to be amended out. Stage the deployment-target hunks only,
  then run the grep in the checklist below before committing.

## Done when

- [x] All eight configurations read `17.0`
- [ ] Builds from the CLI with no deployment-target override; all four variants build
- [x] Known issue 2 replaced in `ios/DapurNaura/CLAUDE.md` (the stale note is gone; the x86_64
      finding took its place)
- [ ] App verified running on the simulator by the human
- [x] Local package wiring confirmed absent from the staged index — the file was reset to HEAD, the
      eight lines reapplied alone, and `git show :…project.pbxproj | grep DNLibraryLocal` returned
      nothing before committing; the wiring was restored to the working tree afterwards
- [x] Committed, not merged — iOS `b756689`, umbrella `c4e7f98`, both on
      `ticket/DN-013-lower-deployment-target`

Always:
- [ ] PR merged, ticket marked `done` by the human
