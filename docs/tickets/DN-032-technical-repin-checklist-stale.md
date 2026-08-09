---
id: DN-032
type: technical
title: The repin checklist tells you to hand-edit project.pbxproj, which DN-030 made wrong
status: in-review
source: —
branch: ticket/DN-032-repin-checklist-stale
layer: tooling
---

## Rationale

`publish-spm.sh` ends a successful release by printing the repin checklist DN-027 added. Its first
step is now wrong:

```
1. project.pbxproj   → version = 0.7.0   (kind = exactVersion)
2. Package.resolved  → resolve, and confirm the revision moved
3. Build the app     → it must compile against 0.7.0
4. Commit            → "DN-XXX: Bump SPMDNLibrary to 0.7.0, …"
```

**Step 1 describes the exact pin DN-030 replaced with a range.** The app now declares
`upToNextMajorVersion` from `0.6.0`, so `0.7.0` is already inside the range and `project.pbxproj`
needs no edit at all — the entire repin is `Package.resolved`. That was verified on the `0.7.0`
release: the project file was confirmed untouched, and the build succeeded.

**Why it matters more than a stale comment usually would.** This text prints at the exact moment
someone is repinning, and it instructs them to hand-edit the one file whose editing DN-030 removed.
An agent following it literally would rewrite `requirement` back to `kind = exactVersion`, silently
undoing DN-030 and restoring the friction it was filed to remove — and the diff would look
deliberate, because the checklist told them to do it.

**Cause: two tickets landed the same day in the wrong order for this text.** DN-027 wrote the
checklist while the exact pin was still the rule; DN-030 changed the rule hours later and swept the
documents that *state* it, but not this string, which is tooling output rather than documentation.
It is the same class of miss as DN-018's dead `GETTING-STARTED.md` link in `bootstrap.sh` — a sweep
that looked at Markdown and skipped a shell script.

**Found by using it.** The `0.7.0` release printed the checklist, and the step was already false by
the time it was read.

## Context

Read before starting:

- `DNLibrary/scripts/publish-spm.sh` — the `NOT DONE YET — REPIN THE APP` heredoc at the end of
  `publish_remote`
- `docs/tickets/DN-030-technical-range-pin-ios.md` — the decision that invalidated step 1
- `docs/tickets/DN-027-technical-publish-atomic-tag-push.md` — where the checklist came from
- `CLAUDE.md` → *Versioning*, for the wording the checklist should agree with

Already true, and constraining:

- **Steps 2, 3 and 4 are still correct** and were followed exactly on the `0.7.0` release. Only step
  1 is wrong.
- **The DerivedData note stays.** Xcode caching package state in `SourcePackages` as well as
  `Package.resolved` is independent of how the dependency is declared.
- **The checklist must stay printed on success.** It exists because a two-minute gap on 2026-08-09
  was long enough for the owner to repin by hand; that hazard is unchanged.
- **`1.0.0` will invert this again.** At `1.0.0` the range moves to `.upToNextMajor` from a `1.x`
  floor and a major release *will* need a project edit. Whatever replaces step 1 should not have to
  be rewritten then — prefer wording that describes the goal rather than the mechanism.

## Technical approach

Replace step 1 with the range reality, and phrase it so the `1.0.0` switch does not falsify it
again — something closer to *"resolve the package forward; the project file needs no edit while the
declared range already covers this version"* than to a literal key/value instruction.

Then check the rest of the script for the same assumption. `publish_local`'s closing text also
describes swapping the remote dependency by hand in Xcode, which is still accurate for local
testing but should be read once against the range.

## Public API contract

**None.** Tooling output only.

**Version bump implied:** none.

## Out of scope

- **Automating the repin.** DN-027 settled that: the script prints the checklist and does not perform
  it, because the resolve and the build need a judgement a shell script cannot make.
- **Changing the pin strategy.** DN-030 is the decision; this ticket only stops the tooling
  contradicting it.

## Test plan

1. Run a **dry run** and confirm the checklist is not printed (it belongs to a real release only).
2. Read the new step 1 against a working tree pinned by range and confirm it describes what actually
   happened on `0.7.0`: `Package.resolved` changed, `project.pbxproj` did not.
3. `bash -n` clean.

## Done when

- [x] Step 1 no longer instructs a `project.pbxproj` edit — it states the goal, *resolve forward*
- [x] Wording survives the `1.0.0` switch: *"edit the project file only if the tag falls outside the
      declared range"* stays correct when the range moves to a `1.x` floor
- [x] `publish_local`'s closing text checked against the range — accurate, but it omitted that the
      local wiring must never be committed and that the step deletes `Package.resolved`. Both now
      carry the revert command and the index check
- [x] `bash -n` clean; `preflight` still reports correctly

## Notes

**Filed autonomously at `status: todo` — a noticed problem, not a request.** Scheduled by the owner
on 2026-08-09, in the same instruction that closed out the DN-026 batch.

Low urgency: the next repin is not imminent, and the range means a reader who ignores step 1 entirely
still gets the right result. It is filed rather than left in conversation because that is the whole
argument of DN-029 — a finding that lives only in a chat log is a finding that has to be rediscovered.
