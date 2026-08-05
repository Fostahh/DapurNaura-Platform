---
id: DN-005
type: technical
title: publish-spm.sh — validate the source repo and record release provenance
status: in-review
source: —
branch: development
layer: tooling
---

## Rationale

`publish-spm.sh` validated only **SPMDNLibrary's** working tree. It never looked at DNLibrary — the
repo the binary is actually built from. The consequences were not theoretical:

1. **A release could be cut from uncommitted code.** The script assembled the XCFramework from
   whatever was on disk. A dirty tree, a half-finished experiment, or a debug tweak would be zipped,
   checksummed, tagged and published, and nothing recorded it.
2. **A release could be cut from any branch**, including a ticket branch that was never merged.
3. **Nothing tied a published tag back to its source commit.** Two repos, two histories: given a
   released zip there was no path back to the DNLibrary commit that produced it. Reproducing or
   auditing a release was guesswork.

For a binary-distributed library this is the highest-consequence gap in the tooling — a bad publish
is visible to consumers and expensive to withdraw.

**Filed retroactively.** The work was done before the ticket system covered tooling; the ticket
exists so the commit has a traceable id, as the platform rule requires.

## Technical approach

- `read_source_provenance()` — captures `SRC_SHA`, `SRC_SHORT`, `SRC_BRANCH`, `SRC_SLUG` from the
  DNLibrary repo.
- `check_source_repo()` — refuses to publish unless the source tree is clean, on a release branch,
  and its `HEAD` is pushed. Sets `SRC_CLEAN` so callers can distinguish "checked and clean" from
  "checked and reported problems".
- `DNLIB_RELEASE_BRANCHES` (default `main`) — overridable via environment rather than hardcoded.
- Provenance is written into the SPMDNLibrary commit message and the release notes, so a published
  version names the commit it came from.
- The tag is now **annotated** rather than lightweight, so it carries its own metadata.
- New `preflight` subcommand — answers "is this releasable?" without running Gradle.

## Out of scope

- `publish` mode remains **human-triggered only**; this ticket does not change that.
- Signing or notarising the XCFramework.
- Any change to versioning policy.

## Verification

Manual, against the real repos — 6 cases, all confirmed:

- [x] dirty source tree, `dry` → reports, does not publish
- [x] dirty source tree, `confirm` → blocks
- [x] clean tree on a release branch → passes
- [x] wrong branch → blocked
- [x] unpushed `HEAD` → blocked
- [x] `DNLIB_RELEASE_BRANCHES` override respected

One defect was found and fixed during this work: `preflight` printed `✅ release-clean`
immediately after listing problems, because dry-run returns 0 by design. The `SRC_CLEAN` flag
exists to separate those two outcomes.

## Done when

- [x] Source-repo validation, provenance capture and `preflight` implemented
- [x] All six cases verified manually
- [ ] Committed on `development`
- [ ] PR merged, ticket marked `done` by the human
