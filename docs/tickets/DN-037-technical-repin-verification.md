---
id: DN-037
type: technical
title: A repin can silently land on the old version — verify the resolved version instead of trusting it
status: done
source: —
branch: ticket/DN-037-repin-verification
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/16
layer: tooling
---

## Rationale

**Resolving the app forward can succeed and still leave it on the previous version, reporting
nothing.** Hit during the `0.8.0` repin on 2026-08-10.

After deleting `Package.resolved` and running `xcodebuild -resolvePackageDependencies`, the app
resolved to **`0.7.0`** — with `0.8.0` already tagged and released. The cached clone under
`~/Library/Caches/org.swift.swiftpm/repositories/SPMDNLibrary-<hash>` had never fetched the new tag,
and SPM does not treat that as an error: the resolve succeeds, writes a well-formed
`Package.resolved`, and exits zero.

**The failure looks exactly like success.** When the resolve lands on the version already pinned,
`Package.resolved` does not change at all — `git status` comes back clean. That reads as *nothing to
do*, and there is a documented sentence one short step away from making that conclusion sound
right: DN-030 established that a repin needs **no edit to `project.pbxproj`**. Going from *"no
project edit"* to *"no change at all"* is a single wrong inference, and the evidence on screen
supports it.

**What caught it this time was luck, not process.** `0.8.0` added `getOfflineClassScheduleUseCase`
and the new screen calls it, so a stale `0.7.0` failed to compile. The compiler was an accidental
safety net.

**A behaviour-only release has no such net.** A rounding fix, or a reworded `DNFormat` string, would
compile perfectly against the older version — green build, clean lint, a PR that looks finished —
and the fix would simply never reach anyone. It would stay that way until some later release added
API, by which point the trail is cold.

Every release since `0.4.0` has been additive, which is why this has not fired before. That is a
property of what has been released so far, not a property of the process.

**Related, and not the same:** DN-032 corrected this checklist once already, when DN-030 made its
first step wrong. This is the second time the printed instructions have been behind reality — the
text names `DerivedData/SourcePackages` and neither of the two `org.swift.swiftpm` caches.

## Context

Read before starting:

- `DNLibrary/scripts/publish-spm.sh` — the `NOT DONE YET — REPIN THE APP` heredoc at the end of
  `publish_remote`, and DN-027's decision about what it may and may not do
- `docs/tickets/DN-027-technical-publish-atomic-tag-push.md` — **the script prints the checklist and
  deliberately does not perform the repin**, because the resolve and the build need a judgement a
  shell script cannot make
- `docs/tickets/DN-030-technical-range-pin-ios.md` — the range, and why no project edit is needed
- `docs/tickets/DN-032-technical-repin-checklist-stale.md` — the last time this text was wrong
- `ios/DapurNaura/CLAUDE.md` — known issue 5, rewritten on 2026-08-10 with all three cache locations

Already true, and constraining:

- **`ios/DapurNaura` has no `scripts/` directory.** This ticket creates the first one.
- **`xcodebuild` has no update flag.** `-resolvePackageDependencies` honours `Package.resolved` and
  will not move past it; Xcode's *Update to Latest Package Versions* is the supported way to move a
  range forward, and it fetches. **An agent cannot use a menu**, so the command-line path is the one
  that will always be taken here — which is exactly why it is worth encoding.
- **DN-027's boundary holds.** Deciding *that* a repin happens stays human; this only makes the
  mechanical part verifiable once that decision is made.

## Technical approach

**Two repositories, not one.**

### 1. `ios/DapurNaura/scripts/repin.sh <version>` — new

The mechanical, checkable part, in one command:

1. Clear the two caches that can hold a stale answer — the cached clone under
   `~/Library/Caches/org.swift.swiftpm/repositories/` and any leftover artifact under
   `~/Library/Caches/org.swift.swiftpm/artifacts/`
2. Delete `Package.resolved` and resolve
3. **Assert `Package.resolved` reports exactly `<version>`, and exit non-zero if it does not**
4. Build, and fail on a failed build

**Step 3 is the ticket.** Steps 1, 2 and 4 are conveniences; the assertion is the thing that turns a
silent wrong answer into a loud one. Clearing caches is something a person has to remember, and this
is the second release running where remembering was what stood between the project and a wrong pin.
Checking the number afterwards needs no memory at all.

It must also print the resolved **revision** and say plainly that it should match the release tag's
commit — the `0.5.0` incident is the standing reminder that a tag and a commit can come apart.

**It does not decide to repin, and does not commit.** Both stay with whoever ran the release.

### 2. `DNLibrary/scripts/publish-spm.sh` — the closing checklist

Point step 1 at `scripts/repin.sh <tag>` rather than describing the manual sequence, and correct the
DerivedData note, which names one of three caches. Keep the wording goal-shaped rather than
mechanism-shaped, as DN-032 settled — so the `1.0.0` range change does not falsify it again.

## Public API contract

None. Tooling only.

**Version bump implied:** none.

## Out of scope

- **Performing the repin from `publish-spm.sh`.** DN-027 settled that and nothing here reopens it —
  this gives the human a better tool for the step, it does not take the step away from them.
- **Committing the bump.** The script verifies; a person commits.
- **CI.** Ruled out by the owner and not to be re-proposed.
- **Teaching the script to pick the version.** It is given one and checks it. Choosing the number is
  derived from the merged tickets and stays where it is.

## Test plan

Not a unit-tested layer, so the demonstration is the gate — **including the failure paths, which is
what DN-027's Definition of Done asks for**:

| Case | Expected |
|---|---|
| Repin to the version just released | Resolves, asserts, builds, exits 0 |
| Repin to a version that does not exist | Fails at the resolve, non-zero |
| **Repin with a deliberately warmed stale clone** | Either resolves correctly anyway, or fails the assertion — **never exits 0 on the wrong version** |
| Repin to a version outside the declared range | Fails the assertion with a message naming the range |
| `bash -n` | Clean |

The third row is the whole point and must be demonstrated, not reasoned about: warm the cache at the
old tag, then run the script and confirm it cannot report success.

## Done when

- [x] `ios/DapurNaura/scripts/repin.sh` exists and fails non-zero when the resolved version is not
      the one asked for
- [x] The stale-clone case is demonstrated, not argued
- [x] The resolved revision is printed alongside the version
- [x] `publish-spm.sh`'s checklist points at the script and no longer names only one cache
- [x] `bash -n` clean on both scripts
- [x] Committed, not merged — [DapurNaura-iOS#16](https://github.com/Fostahh/DapurNaura-iOS/pull/16)
      and [DNLibrary#20](https://github.com/Fostahh/DNLibrary/pull/20)
- [x] **Known issue 5 gained the fourth cache location** — held back until DN-036 merged, because
      that ticket rewrote the entry into a table and editing it earlier would have collided.
      Landed as [DapurNaura-iOS#17](https://github.com/Fostahh/DapurNaura-iOS/pull/17).
- [x] PR merged — DapurNaura-iOS#16 + DNLibrary#20, merge commit `58ed3eb`, 2026-08-10

## Demonstration (2026-08-10)

| Case | Result |
|---|---|
| Repin to the published `0.8.0` | exits 0, lands on `0.8.0`, builds |
| Repin to `0.5.0`, outside the declared range | exits 1, prints the range read from the project |
| Caches deliberately warmed at `0.7.0`, then repin `0.8.0` | still lands on `0.8.0`, exits 0 |
| `bash -n` on both scripts | clean |

**The strongest evidence was not planned.** On its very first run the script cleared three caches,
asked for `0.8.0`, and resolved to `0.7.0` — and its own assertion caught it. The cause was a
**fourth** location nobody had recorded: `DerivedData/SourcePackages/workspace-state.json` stores
the resolved version, and `xcodebuild` restores from it even with `Package.resolved` deleted and
every `org.swift.swiftpm` cache cleared. Known issue 5 had listed `SourcePackages` only under a
*missing symbol* symptom.

So the script would have shipped doing the wrong thing, and the check it exists to perform is what
stopped it. That is the argument for the ticket, made by the ticket.

**One incidental finding, now warned about in the script:** `xcodebuild` normalises
`project.pbxproj` while resolving — it strips empty `exceptions = ()` blocks. Harmless, but it is
churn that must be reverted rather than committed as part of a repin, and it would otherwise look
like the repin had edited the project file, which DN-030 says it must not need to.

## Notes

**Filed autonomously at `status: todo` — a problem met while doing DN-036's repin, not a request.**
The owner asked what the impact was before scheduling it; the answer recorded here is that the
exposure is narrow (a repin, from the command line, on a release that adds no API the app calls) and
the cost of it firing is a release that silently never ships.

**The documentation half is already done** — known issue 5 in `ios/DapurNaura/CLAUDE.md` now carries
all three caches as a symptom-to-fix table, landed with DN-036's repin commit. This ticket is the
part that documentation cannot do: DN-029's finding was that rules hold where they are encoded and
drift where they are prose, and known issue 5 was prose that had already gone stale once.
