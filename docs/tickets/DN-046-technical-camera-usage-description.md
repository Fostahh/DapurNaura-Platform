---
id: DN-046
type: technical
title: The app has no camera usage description, and opening the camera without one terminates it
status: todo
source: —
branch: ticket/DN-046-camera-usage-description
layer: ios
---

## Rationale

**DN-048 lets a user photograph a paper receipt. The app cannot open a camera today without being
killed for it.**

iOS requires a purpose string before an app may use the camera. Without
`NSCameraUsageDescription`, the system does not show a dialog, refuse politely, or return an error —
**it terminates the process.** The failure arrives as a crash on a real device, and it arrives only
on the code path that opens the camera, which is why it survives every other kind of testing.

**The app has never needed one.** Nothing before this reads the camera; the only image the app
displays comes from a URL. Choosing from the photo library needs no string either — since iOS 14,
`PhotosPicker` runs out of process and returns only what the user picked, so the app never holds
library access and never asks for it. **The camera is the first and only permission this app
requires.**

**Scheduled by the owner on 2026-09-11**, translated: *"The camera will be used"*, having been told
that the library alone would cost nothing and the camera would cost this.

### Why this is not part of DN-048

**It is app-wide configuration, and DN-039 settled that such work gets its own ticket.** That
ticket's reasoning applies unchanged: a pull request titled *the payment flow* must not quietly
change what permissions the whole app declares, across every build variant, where a reviewer looking
at screens would not think to check.

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura.xcodeproj/project.pbxproj` — **four** `XCBuildConfiguration` blocks on
  the app target (Development, Alpha, Beta, Release). The test targets are not involved.
- `docs/tickets/DN-039-technical-light-mode-portrait-lock.md` — the same shape of change, and the
  reason the two obvious homes both lose
- `ios/DapurNaura/CLAUDE.md` — *Build variants*, and how a value reaches code

**DN-039 already proved where this cannot go, and the reasoning carries over exactly:**

- **`Info.plist` cannot win.** `GENERATE_INFOPLIST_FILE = YES`, so Xcode merges its generated keys on
  top of `INFOPLIST_FILE`. A key written there is overwritten by the build setting.
- **An xcconfig cannot win either.** A target-level build setting overrides an xcconfig, and these
  keys are set at target level.

So it goes where the other `INFOPLIST_KEY_*` values already live: the build settings.

## Technical approach

**No Swift. One setting added to four build-configuration blocks in `project.pbxproj`.**

```diff
+INFOPLIST_KEY_NSCameraUsageDescription = "Dapur Naura perlu akses kamera untuk memotret bukti pembayaran Anda.";
```

**Applied to all four — Development, Alpha, Beta and Release.** A variant that crashes where the
others do not is exactly the difference nobody finds until TestFlight.

**The string is Bahasa Indonesia**, because iOS shows it verbatim in the permission dialog and it is
app content. The platform rule applies: app content is never translated.

**It says what it is for, not what it wants.** *"Perlu akses kamera untuk memotret bukti
pembayaran"* answers the question the dialog actually raises in the user's mind. A string that only
names the permission tells them nothing they cannot already see, and App Review rejects purpose
strings that do not state a purpose.

## Public API contract

None. No Swift, no DNLibrary symbols, no library change.

**Version bump implied:** none. No publish, no repin.

## Out of scope

- **Asking for the permission**, and **handling a refusal.** That is DN-048's, on the screen that
  opens the camera. This ticket only makes it legal to ask.
- **Photo library access.** `PhotosPicker` needs no permission and none is added — adding
  `NSPhotoLibraryUsageDescription` speculatively would ask users for something the app does not use.
- **Microphone, location, notifications** or any other permission. None is needed.
- **Any Swift file.** If this ticket touches one, the approach was wrong.

## Test plan

Configuration, so there is nothing to unit test. What proves it:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" -configuration Development \
  -showBuildSettings | grep CAMERA
```

- **Run it for all four configurations.** Each must report the string.
- **Then inspect the built product**, because `-showBuildSettings` proves what the build resolves,
  not what ships: `plutil -p <path>/DapurNaura.app/Info.plist` must show
  `NSCameraUsageDescription`.

**The behaviour cannot be verified until DN-048 exists** — there is no code that opens a camera yet.
That is expected, and it is why this ticket ships ahead of the screen rather than with it.

## Done when

- [ ] All four app-target configurations carry `INFOPLIST_KEY_NSCameraUsageDescription`
- [ ] The string is Bahasa Indonesia and states the purpose
- [ ] The test targets are untouched
- [ ] No Swift file changed
- [ ] `-showBuildSettings` verified for all four, and the built `Info.plist` inspected
- [ ] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034)
- [ ] `project.pbxproj` carries no local package reference
- [ ] Documentation sweep (DN-042) — enumerated with `git ls-files '*.md'`
- [ ] Diff reviewed by the owner
- [ ] Committed
- [ ] PR opened
- [ ] PR merged

## Notes

**This is the app's first permission, and it is worth knowing that it stays the only one.** The
photo library path was chosen partly because it needs none; if the picker were ever replaced with a
hand-built one reading `PHPhotoLibrary` directly, a second purpose string would become necessary and
the app would start asking users for access it currently never needs.
