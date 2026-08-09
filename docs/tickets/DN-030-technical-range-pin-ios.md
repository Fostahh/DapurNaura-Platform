---
id: DN-030
type: technical
title: Pin SPMDNLibrary by range, not exactly — so a release needs no manual dependency edit
status: in-progress
source: —
branch: ticket/DN-030-range-pin-ios
layer: ios
---

## Rationale

**Owner's instruction, 2026-08-09** — given in Indonesian, recorded here as the agent's English
translation per DN-010:

> *"The standard I want for the iOS project is: instead of using `exactVersion`, let's move to a
> version range from 0.0 to 1.0, SO THAT no significant changes to package dependencies are needed —
> just update to the latest package version rather than changing it manually."*

Today the app names an exact version in `project.pbxproj`, so **every release requires a hand-edit
of the project file**. That edit is pure friction, it is easy to typo, and it is the step that
produced the only near-miss in the release flow so far: on 2026-08-09 the `0.6.0` release landed at
03:04 and the repin at 03:07, and in that gap the owner opened Xcode and resolved the project by
hand. Two people editing one dependency declaration is how a conflict starts. A range removes the
edit entirely — *Update to Latest Package Versions* does it.

**This restores the original design rather than inventing a new one.** §7 of
`ARCHITECTURE-AND-WORKFLOW.md` read, until DN-029 corrected it against the code:

> *"The app depends on SPMDNLibrary by **version range** (`.upToNextMajor`), **not** an exact pin.
> Therefore `Package.resolved` must be committed."*

The exact pin arrived later, in `becac5f` (DN-022). So the document was not merely stale — it was
describing a superseded decision, and the owner's instruction returns to it for the reason the
original design gave.

**What the exact-pin rule was protecting against, and why it is weaker now.** Its argument was that
`0.x` makes no compatibility promise, and that DN-004, DN-006 and DN-008 each removed public symbols
and would silently break an app on a range. That was true of the early scaffolding removals. Every
release since has been additive — `0.4.0` added `DNFormat`, `0.5.0` added the recipe models, `0.6.0`
added the category API — and none removed a symbol. The risk is real but it is now the exception,
and **when it does happen the build fails loudly at a moment the developer chose**, by pressing
*Update*. That is a controlled failure, not a silent one.

**The floor is `0.6.0`, not `0.0.0`.** The instruction says "from 0.0", and `0.0.0` would satisfy it
literally, but it also permits resolving *backwards* to a version that predates the category API the
app already calls. `0.6.0` is the first release containing it. The upper bound is unchanged by the
choice, so nothing is lost: `0.7.0`, `0.8.0` and every later `0.x` still resolve automatically.
Agreed with the owner before implementation.

**A property worth naming:** SPM does not special-case `0.x` the way npm and Cargo do. There,
`^0.6.0` means `< 0.7.0`; in SPM, `.upToNextMajor(from: "0.6.0")` means **`>= 0.6.0, < 1.0.0`** —
exactly the range asked for. It also stops below `1.0.0` on its own, which makes *"`1.0.0` is
reserved for the App Store release"* a rule the resolver enforces rather than one someone has to
remember.

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura.xcodeproj/project.pbxproj` — the `XCRemoteSwiftPackageReference` block
- `ios/DapurNaura/CLAUDE.md` → *The rules below are ACTIVE* — the local package rule sits next to this
- `CLAUDE.md` → *Versioning*, the paragraph this ticket rewrites
- `docs/tickets/DN-022-technical-agent-opens-prs.md` — where the exact-pin rule was introduced

Already true, and constraining:

- **`Package.resolved` must still be committed, and matters more now, not less.** With an exact pin
  the version is in `project.pbxproj` and resolution is deterministic anyway. With a range,
  `Package.resolved` is the *only* thing that makes a build reproducible — without it, two people
  building the same commit can resolve different library versions.
- **The local package rule is untouched.** Development still builds against `ios/DNLibraryLocal`,
  that wiring is still never committed, and both files still go dirty when switching. This ticket
  changes what the *committed remote reference* says, nothing about the local one.
- **`1.0.0` is still reserved** for the App Store release. The range stops below it by construction.
- **The library's own versioning does not change.** `0.MINOR.PATCH`, minor for any public API change,
  derived from the tickets merged since the last tag.
- **No Swift source changes.** The app compiles against `0.6.0` today and the range still resolves to
  `0.6.0`, so this is a dependency-declaration change only.

## Technical approach

`project.pbxproj`, one requirement block:

```diff
   requirement = {
-    kind = exactVersion;
-    version = 0.6.0;
+    kind = upToNextMajorVersion;
+    minimumVersion = 0.6.0;
   };
```

`Package.resolved` is expected to be **byte-identical afterwards**: `0.6.0` is both the pinned
version and the newest published release, so the resolver's answer does not move. That is the
verification, not an assumption — if the file changes, something else moved and the diff must be
explained.

Then the three documents that state the rule: `CLAUDE.md` → *Versioning*,
`docs/ARCHITECTURE-AND-WORKFLOW.md` §7 → *The iOS dependency*, and `ios/DapurNaura/CLAUDE.md` →
*The rules below are ACTIVE*. Each records what the new rule is, that it supersedes DN-022's exact
pin, and **why the `Package.resolved` obligation tightens rather than relaxes** — that is the part a
reader is most likely to get wrong.

## Public API contract

**None.** No Kotlin, no Swift, no published symbol — a dependency declaration and the documents
describing it.

**Version bump implied:** none. This ticket ships no library code.

## Out of scope

- **Changing how the library is versioned.** `0.MINOR.PATCH` stands.
- **Automating the repin.** *Update to Latest Package Versions* is a deliberate human action, and it
  stays one. `publish-spm.sh` still only prints the checklist (DN-027).
- **Moving to `.upToNextMinor` or a branch dependency.** Neither was asked for; a branch dependency
  would also defeat the reproducibility `Package.resolved` provides.
- **Anything about `1.0.0`.** When the app reaches it, the floor and the bound are revisited then.

## Test plan

1. **`project.pbxproj` parses and the project opens** — Xcode reads the requirement as
   *Up to Next Major Version · 0.6.0 < 1.0.0*.
2. **Resolution does not move.** `Package.resolved` is unchanged after a resolve — same revision,
   same `0.6.0`. Verified by diff, not by eye.
3. **The app builds** against the range exactly as it did against the exact pin.
4. **The committed reference is still remote.** `grep` for `DNLibraryLocal` and
   `XCLocalSwiftPackageReference` in the staged `project.pbxproj` returns nothing — the local
   package rule is unaffected and must be proven so.
5. **The three documents agree** with each other and with the file on: range not exact, floor
   `0.6.0`, bound below `1.0.0`, and `Package.resolved` still committed.

## Done when

- [ ] `project.pbxproj` uses `upToNextMajorVersion` with `minimumVersion = 0.6.0`
- [ ] `Package.resolved` verified unchanged, and still committed
- [ ] App builds; no Swift source touched
- [ ] No local-package wiring anywhere in the staged project file
- [ ] `CLAUDE.md`, §7 and `ios/DapurNaura/CLAUDE.md` all state the new rule and name what it supersedes
- [ ] Committed on `ticket/DN-030-range-pin-ios`, not merged

## Notes

**This is the second rule this audit cycle has moved from prose to mechanism**, and it is worth
noticing that it moves in the opposite direction from the others. DN-027 added a guard because a
human habit was protecting an irreversible operation. DN-030 *removes* a manual step because the
protection it offered — catching a removed symbol at bump time — is worth less than the friction it
charged on every single release. Both are the same judgement applied honestly: put the mechanism
where the cost actually falls.

Filed and scheduled on 2026-08-09, on the owner's instruction and after their explicit approval of
the `0.6.0` floor.
