---
id: DN-023
type: technical
title: publish-spm.sh refuses to release — its branch rule encodes the old topology
status: in-progress
source: —
branch: ticket/DN-023-release-branch-topology
layer: tooling
---

## Rationale

`publish-spm.sh` refuses every publish. The first real release attempt — `0.1.0`, on 2026-08-07 —
failed its own preflight:

```
⚠️  DNLibrary source is not release-clean:
     • on branch 'development' — releases are cut from: main
❌ Refusing to publish: a tagged binary must be traceable to a pushed release commit.
```

The check is DN-005's and it is doing exactly what it was built to do. What changed is the topology
underneath it:

```sh
# Branches a release may be cut from. `main` is the project standard; `development`
# is the integration branch and is deliberately NOT a release branch.
DNLIB_RELEASE_BRANCHES="${DNLIB_RELEASE_BRANCHES:-main}"
```

**Owner's instruction, 2026-08-07** — agent's English translation per DN-010 is unnecessary; it was
given in English: *"for development process, push into development, later on if the app already
version 1.0.0, then merged development into main."*

All four repositories now work on `development`. **`main` is frozen until the app reaches `1.0.0`**,
when `development` merges into it once. Under that rule the current default makes a release
*impossible* — the only permitted release branch receives no commits until the moment the project
no longer needs its first release.

**The guard is not wrong; it is out of date.** Deleting it would be the wrong fix — provenance
still matters, and the other three checks it performs (clean tree, HEAD pushed to a remote, source
SHA recorded) all passed. Only the branch list is stale.

**Why not just override it per run.** `DNLIB_RELEASE_BRANCHES=development ./scripts/publish-spm.sh`
works today and was rejected deliberately. It leaves a script whose comment states the opposite of
what the project does, and every future publish silently defeats a guard that still *reads* as
enforced. That is the same failure DN-002's RCA describes — `CODEBASE-STANDARD.md` claimed
`explicitApi()` was enabled while it was not, so no check ever ran and nobody looked. A stale comment
that contradicts practice is worse than no comment.

## Context

Read before starting:

- `DNLibrary/scripts/publish-spm.sh` — lines 32–37 (the constant) and `check_source_clean`
- `docs/tickets/DN-005-technical-publish-preflight-provenance.md` — why the preflight exists
- `CLAUDE.md` → *Publishing the iOS binary* and *Versioning*

Already true, and constraining:

- **The override mechanism already exists** and is documented in the script's own comment
  (`DNLIB_RELEASE_BRANCHES="main release" ./scripts/publish-spm.sh`). This ticket changes the
  **default**, not the mechanism.
- **The other three preflight checks pass** on `development` and must keep working: clean working
  tree, HEAD contained in a remote branch, and source SHA/branch recorded in the release notes.
- **`main` must stay a valid release branch.** At `1.0.0` the topology inverts and releases are cut
  from `main` again. Replacing `main` with `development` would only move the same bug.

## Technical approach

One constant and its comment:

```sh
# Branches a release may be cut from. `development` is where all four repositories
# work; `main` is frozen until the app reaches 1.0.0, when development merges into
# it once and releases are cut from main again. Both are therefore valid.
# Override if the topology changes:
#   DNLIB_RELEASE_BRANCHES="main release" ./scripts/publish-spm.sh
DNLIB_RELEASE_BRANCHES="${DNLIB_RELEASE_BRANCHES:-development main}"
```

Nothing else changes. `check_source_clean` iterates the list already.

## Public API contract

**None.** Tooling only — no Kotlin, no Swift, no published symbol.

**Version bump implied:** none. This ticket ships no library code; it is what *allows* a version to
be published at all.

## Out of scope

- **Removing or weakening any other preflight check.** Clean tree, pushed HEAD and recorded
  provenance all stay.
- **The release itself.** `0.1.0` is published after this merges — owner-triggered, per `CLAUDE.md`.
- **Branch protection rules on GitHub.** Not configured, and the token cannot set them.

## Test plan

No automated gate — this is a shell constant. Verified by running the script:

1. **Dry run from `development` passes the preflight** with no "not release-clean" warning. Before
   this change it warned; before it, a real publish died.
2. **A real publish from `development` is accepted** — proven by `0.1.0` shipping.
3. **A dirty working tree is still refused**, so the change did not weaken the other checks.
4. `main` remains accepted — grep the constant; both names present.

## Done when

- [ ] `DNLIB_RELEASE_BRANCHES` defaults to `development main`, comment rewritten to match
- [ ] Dry run from `development` reports release-clean
- [ ] Committed on `ticket/DN-023-release-branch-topology`, not merged
- [ ] PR merged, ticket marked `done` on the owner's word

## Notes

**Found by the tooling refusing to run, which is the good outcome.** The preflight was added by
DN-005 precisely so a release could not be cut from an untraceable source, and the first time it
mattered it stopped a publish and named the reason. The fix is to teach it the new topology, not to
route around it.

Filed and started in the same step on 2026-08-07 — the owner's instruction (*"Do 2"*) scheduled it,
as with DN-010, DN-019 and DN-022.
