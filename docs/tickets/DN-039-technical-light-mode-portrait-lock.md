---
id: DN-039
type: technical
title: Lock the app to light mode and portrait — the owner believes both are already enforced, and neither is
status: done
source: —
branch: ticket/DN-039-light-mode-portrait-lock
commit: 4869dca
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/19
layer: ios
---

## Rationale

**The owner stated on 2026-08-10 that both are current fact:**

> "Currently this app forces Light Mode, no darkmode ya. And only portrait app, no landscape, FOR
> NOW. This can be changed in the future if owner wants to develop it."

**Neither is true of the app as it stands.** Checked before the sentence was recorded:

| | Believed | Actual |
|---|---|---|
| Colour scheme | forced light | **nothing sets one.** No `UIUserInterfaceStyle`, no `preferredColorScheme` anywhere in the project — the app follows the phone |
| Orientation | portrait only | **Xcode's default.** iPhone allows portrait plus both landscapes; iPad allows all four |

Nothing has gone wrong yet, and that is exactly why the belief survived. Every screen built so far
draws from **adaptive** system colours — `Color(.systemGroupedBackground)`, default label colours —
so all four look correct in dark mode by construction rather than by decision. Nobody has run the app
in dark mode and had a reason to notice.

**DN-040 ends that.** The login screen is the first built from fixed values: a white background and a
palette of hex colours, per the owner's instruction of 2026-08-10 that colours be stored as variables
in `DesignConstants`. On a phone in dark mode that screen is a white background under text the system
has turned white — invisible, on the first screen the app shows. The gap becomes a defect the moment
DN-040 lands.

**Scheduled by the owner ahead of DN-040 on 2026-08-10**, having been given the choice: *"Its own
technical ticket, done first."* It is app-wide configuration touching every screen, so it does not
belong inside a product ticket about login — a PR titled *the login screen* must not quietly change
how the whole app rotates and renders.

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura.xcodeproj/project.pbxproj` — **four** `XCBuildConfiguration` blocks on
  the app target carry `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` and `_iPad`, one per
  variant (Development, Alpha, Beta, Release). The test targets carry neither.
- `ios/DapurNaura/DapurNaura/Info.plist` — four keys, all `$(VAR)` placeholders
- `ios/DapurNaura/DapurNaura/Config/*.xcconfig` — one per variant, each self-contained
- `ios/DapurNaura/CLAUDE.md` — *Build variants*, and how a value reaches code
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §9

**The two obvious homes for this both lose, and the reason is worth knowing before trying either.**

- **`Info.plist` cannot win.** `GENERATE_INFOPLIST_FILE = YES`, and Xcode merges its generated keys
  *on top of* `INFOPLIST_FILE`. The repo's own xcconfig comment states it: *"Xcode merges its
  generated keys on top, so that file only holds what we substitute ourselves."* A
  `UISupportedInterfaceOrientations` array written into `Info.plist` would be overwritten by the
  build setting that already exists.
- **The xcconfigs cannot win either.** A target-level build setting overrides an xcconfig, and these
  keys are set at target level in all four configurations.

So the change has to be made where the values already live: the build settings.

## Technical approach

**No Swift. Four build-configuration blocks in `project.pbxproj`, each gaining one setting and having
two rewritten.**

```diff
-INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
-INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
+INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait;
+INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
+INFOPLIST_KEY_UIUserInterfaceStyle = Light;
```

Applied to all four — **Development, Alpha, Beta and Release**. A variant that rotates when the
others do not is the kind of difference nobody finds until TestFlight.

**Why `UIUserInterfaceStyle` rather than `.preferredColorScheme(.light)` on the root view.** The
build setting is app-wide and system-level; the modifier only reaches the SwiftUI view tree. What
sits outside that tree is the **keyboard**, system alerts and share sheets — and DN-040 puts a
keyboard on screen for the first time in this app's life. A dark keyboard rising under a white login
screen is precisely the case the SwiftUI-level modifier does not cover.

It also means the existing four screens need no edit at all. They keep their adaptive colours and
simply always resolve light, which is what they have always looked like in practice.

**`UIRequiresFullScreen` is deliberately not added** — see *Out of scope*.

## Public API contract

None. No Swift changes, no DNLibrary symbols touched.

**Version bump implied:** none. No library change, no release, no repin.

## Out of scope

- **Dark mode.** Supporting it is a design pass over five screens — a palette with two values per
  colour, and the owner choosing both. Nobody has asked for it. This ticket makes the app honestly
  light rather than accidentally adaptive; it does not close the door.
- **Landscape layouts.** Same reasoning. The screens have never been laid out for it.
- **`UIRequiresFullScreen`.** An iPad app that supports only portrait and does not declare full
  screen can draw attention at App Store review, because Slide Over and Split View expect all four
  orientations. **Recorded, not solved** — `main` is frozen until `1.0.0`, nothing has been submitted,
  and adding a multitasking opt-out on the owner's behalf is a product decision nobody has made. It
  belongs to whichever ticket first prepares a submission.
- **Dropping iPad.** `TARGETED_DEVICE_FAMILY` stays `1,2`. The owner asked for portrait, not for
  iPhone only.
- **Any Swift file.** If this ticket touches one, the approach was wrong.

## Test plan

Configuration, so there is nothing to unit test. What proves it:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" -configuration Development \
  -showBuildSettings | grep -E "ORIENTATION|INTERFACE_STYLE"
```

- **Run it for all four configurations.** Each must report portrait alone for both device families,
  and `UIUserInterfaceStyle = Light`.
- **Then check the built product, not just the settings** — `-showBuildSettings` proves what the
  build resolves, not what ships. `plutil -p <path>/DapurNaura.app/Info.plist` must show the same
  three keys.

What the owner is asked to check on the running app:

| Check | Expected |
|---|---|
| Set the phone to dark mode, launch the app | Every screen still light — unchanged from today |
| Rotate the phone on any screen | Nothing rotates |
| Rotate on iPad | Nothing rotates |
| The four existing screens | Identical to before in light mode; nothing has shifted |

`swiftlint lint` must report 0 violations — trivially, since no Swift changes.

## Done when

- [x] All four app-target configurations carry portrait-only for both `_iPhone` and `_iPad`
- [x] All four carry `INFOPLIST_KEY_UIUserInterfaceStyle = Light`
- [x] The test targets are untouched
- [x] No Swift file changed
- [x] `-showBuildSettings` verified for all four configurations, and the built `Info.plist`
      inspected — `plutil` reports one orientation per device family and `UIUserInterfaceStyle`
      `Light`, 2026-08-10
- [x] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034) — `DapurNaura Dev`, simulator
      `4C82AD15-1365-4200-977C-C5DF10E11B1B` (iPhone 16 Pro), 2026-08-10
- [x] `project.pbxproj` carries no local package reference — nothing here needs one
- [x] Owner has verified the running app in dark mode and rotated it — approved 2026-08-11
- [x] Committed, not merged — `4869dca`
- [x] PR opened — [DapurNaura-iOS#19](https://github.com/Fostahh/DapurNaura-iOS/pull/19)
- [x] PR merged — [DapurNaura-iOS#19](https://github.com/Fostahh/DapurNaura-iOS/pull/19),
      merge commit `8105423`, 2026-08-11

## Notes

**Filed and scheduled in the same exchange**, the shape DN-010 and DN-034 already set: the agent
noticed the gap while drafting the login requirement, filing was autonomous, and the owner chose
where it runs — *"Its own technical ticket, done first."*

**The finding came from checking a statement rather than recording it.** The owner described light
mode and portrait as settled fact; the platform rule is that for *what the code does today*, the code
wins. Had the sentence been transcribed into the requirement as given, DN-040 would have been built
against a guarantee nothing provides, and the failure would have surfaced as an invisible login
screen on somebody's phone rather than as a ticket.
