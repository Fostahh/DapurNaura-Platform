---
id: DN-024
type: technical
title: publish-spm.sh can release from a branch that is behind its remote
status: todo
source: —
branch: —
layer: tooling
---

## Rationale

Publishing `0.5.0` on 2026-08-08 half-failed, and cost a tag deletion to repair — an operation on the
workspace's `Never` list, which the owner had to authorise as a one-time exception.

**What happened.** `publish-spm.sh` was run with `SPMDNLibrary` checked out on `development` at the
`0.4.0` release commit. In the meantime DN-018 and DN-019 had merged into that branch **on GitHub**.
The local branch was therefore four commits behind, and the script:

1. passed its preflight — the branch name was allowed, the tree was clean, HEAD was on a remote branch
2. rewrote `Package.swift`, committed, and tagged **on the stale base**
3. pushed — and `git push origin HEAD --tags` **partially succeeded**

Git pushes refs independently. The branch update was rejected as a non-fast-forward; **the tag push
succeeded.** The result was a published tag pointing at a commit that existed on no branch, with no
release behind it.

**The script then misdiagnosed it.** Its failure message reads *"GitHub sign-in cancelled or auth
failed"*, while git's own output said `Note about fast-forwards`. Anyone following that message would
retry the auth path and never find the problem.

**Why the existing preflight did not catch it.** DN-005's `check_source_clean` verifies three things
about the *source* repo, `DNLibrary`: clean tree, allowed branch, HEAD on some remote branch. All
three were true. **Two gaps:** none of them checks whether the branch is *up to date* with its
remote, and none of them examines the **target** repo, `SPMDNLibrary`, which is where the commit and
tag actually land.

**Why it matters more than the tidying it cost.** A moved tag is not a cosmetic problem. Swift
Package Manager records a tag-to-commit fingerprint and refuses to resolve when it changes:

```
error: Revision 041ba4c… for version 0.5.0 does not match
       previously recorded value e8399bd…
```

That is tamper detection working correctly — it exists to catch exactly the case where a released tag
is silently repointed at different code. Every machine that had resolved the old tag must clear its
fingerprint cache by hand, and Xcode caches a second copy in DerivedData that `Package.resolved`
alone does not fix. This time the blast radius was one machine. With consumers, it is every developer
and every CI runner.

## Context

Read before starting:

- `DNLibrary/scripts/publish-spm.sh` — `check_source_clean` (the current preflight), `publish_remote`
  (the commit/tag/push sequence), and the failure message near the push
- `docs/tickets/DN-005-technical-publish-preflight-provenance.md` — why the preflight exists
- `docs/tickets/DN-023-technical-release-branch-topology.md` — the previous correction to the same
  check, and the reason `development` is a release branch at all

Already true, and constraining:

- **The preflight is not wrong, only incomplete.** Every check it performs is worth keeping. This
  ticket adds to it; it must not weaken clean-tree, allowed-branch or provenance.
- **`SPMDNLibrary` is a second repository with its own state.** The script already takes its path as
  an argument and commits into it, but never inspects it before doing so.
- **The `Never` list still forbids deleting a tag or release.** The point of this ticket is that the
  situation requiring one should not arise. The 2026-08-08 deletion was an explicit one-time
  exception from the owner and sets no precedent.

## Technical approach

Three additions, in the order they would have caught this:

1. **Fetch and compare both repos against their remotes.** For each of `DNLibrary` and the target
   `SPMDNLibrary`: `git fetch`, then refuse if the checked-out branch is behind or has diverged from
   its upstream. Being *ahead* is fine for the target — that is what the release commit is.
2. **Extend the preflight to the target repo.** Clean tree and correct branch, the same standard
   already applied to the source.
3. **Do not tag before the branch push succeeds.** Push the branch first; only tag and push the tag
   once that returns 0. A failed branch push should leave **no** tag anywhere. This alone converts
   the failure from "published tag on an orphan commit" into "nothing happened."

Also correct the misleading failure message: report git's actual error rather than assuming
authentication.

## Public API contract

**None.** Tooling only.

**Version bump implied:** none.

## Out of scope

- **Weakening any existing check.**
- **Automating tag deletion or repair.** If a release goes wrong, a human decides — that is the
  `Never` rule, and this ticket exists so the decision is rarely needed.
- **CI.** A deliberate deferral the owner has asked not to have re-raised.

## Test plan

No automated gate; verified by running the script.

1. **Behind-remote is refused.** Reset the target's `development` one commit back, run a dry publish,
   and confirm it stops with a message naming staleness — this is the exact 2026-08-08 condition.
2. **Dirty target is refused**, matching how a dirty source already behaves.
3. **A rejected branch push leaves no tag.** Simulate by pointing the target at a branch that cannot
   fast-forward; assert `git tag --list` is unchanged locally and nothing new appears on the remote.
4. **The happy path still publishes**, and the existing checks still refuse a dirty tree and an
   unlisted branch.

## Done when

- [ ] Both repos fetched and checked against their upstreams before anything is written
- [ ] Target repo gets clean-tree and branch checks
- [ ] Branch push precedes tagging; a failed push leaves no tag
- [ ] Failure message reports git's actual error
- [ ] Verified by running the four cases above
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` on the owner's word

## Notes

**Filed by the agent at `status: todo` on 2026-08-08 — filing is autonomous, scheduling is not.**

The mistake was the agent's: it published from a local checkout it had not refreshed. But a release
script that can be handed a stale branch and will tag it anyway is a tooling gap, not only an
operator error — and the operator here has no way to notice, because the script reports success
right up until the push.
