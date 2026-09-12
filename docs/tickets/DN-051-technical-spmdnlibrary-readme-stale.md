---
id: DN-051
type: technical
title: SPMDNLibrary's README says the package has no tags and does not resolve, and both are false
status: todo
source: —
branch: —
layer: docs
---

## Rationale

Noticed during DN-050's documentation sweep, on the first read of this file since it was written.
**It is not DN-050's doing** — nothing in that ticket touches `ios/SPMDNLibrary` — so it is filed
rather than folded in, and left `todo` for the owner to schedule.

`ios/SPMDNLibrary/README.md` carries a section headed **"⚠️ This package does not currently
resolve"**, dated *Verified 2026-08-06*. Every factual claim in it is now wrong:

| The README says | Actually |
|---|---|
| *"The repository has no tags."* | Tags `0.5.0`, `0.6.0`, `0.7.0`, `0.8.0`, `0.9.0` exist |
| *"There are no GitHub releases"*, and the binary URL 404s | Every one of those tags has a release behind it |
| *"`Package.swift` … the `1.4.0` it names"* | The manifest names `0.9.0`, rewritten by `publish-spm.sh` |
| *"the app … has never pinned a remote version"* | The app pins **by range**, `upToNextMajorVersion` from `0.6.0` (DN-030) |
| The install snippet reads `from: "1.0.0"` | `1.0.0` is **reserved for the App Store release** and must not be used before it |

**The last row is the one that can cause harm.** A reader following the snippet writes a requirement
the resolver cannot satisfy today, and which — when `1.0.0` eventually exists — would pin them to the
App Store release rather than the range the app actually uses.

**Why it went unnoticed for five weeks.** The file is the only tracked `.md` in a repository that
holds one generated manifest and nothing else, so no ticket has had reason to open it since
2026-08-06. Six releases have shipped in that window, each one making the warning more wrong. DN-042
requires a sweep to *enumerate then read*; this file is the case that rule exists for, and it was
enumerated but not read until now.

## Technical approach

- **Delete the "does not currently resolve" section.** It documents a condition that ended with the
  `0.5.0` release and its own date makes that visible.
- **Correct the install snippet** to the range the app actually uses, and say plainly that `1.0.0` is
  reserved.
- **Say what the current version is without naming it.** DN-029's rule: a version number written into
  prose is stale at the next release. Point at the tags, or at `Package.swift`, rather than copying a
  number into the text.
- Leave everything else. *"Do not edit `Package.swift` by hand"*, the separate-repository rationale
  and the release instructions are all still correct and well written.

## Out of scope

- `Package.swift` itself — it is generated, correct, and must not be hand-edited.
- Any release, tag or version change. This is a documentation fix only.

## Done when

- [ ] No claim in the README contradicts the repository's actual tags and releases
- [ ] The install snippet matches how the app really depends on the package, with `1.0.0` flagged as reserved
- [ ] No hardcoded current version in the prose (DN-029)
- [ ] Diff reviewed by the owner
- [ ] Committed
- [ ] PR opened
- [ ] PR merged
