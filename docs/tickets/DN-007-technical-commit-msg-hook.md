---
id: DN-007
type: technical
title: Enforce the DN-XXX commit-message convention with a commit-msg hook
status: todo
source: —
branch: ticket/DN-007-commit-msg-hook
layer: tooling
---

## Rationale

The projects are separate git repositories, and the `DN-XXX` id in the commit message is the
**only** thread linking a ticket to the commits that satisfy it — the architecture doc calls the
convention load-bearing, not cosmetic. It is currently enforced by nothing. A forgotten id is
silent at commit time and unrecoverable later: the reviewer loses the cross-repo trail exactly
when they need it.

`ARCHITECTURE-AND-WORKFLOW.md` §2 has carried this as an `[OPEN]` item ("~5 lines, currently
unenforced"). This ticket turns the note into schedulable work.

## Context

- The convention: every commit in a **project repo** starts `DN-XXX: `.
- Legitimate exceptions exist and must not be blocked: merge commits, the release commits written
  by `publish-spm.sh` (`Release X.Y.Z …`), and pre-existing history.
- Hooks live in `.git/hooks/`, which is per-clone and never committed — so installation must be
  repeatable, and `bootstrap.sh` is the natural place to do it.
- The change itself lives in the **umbrella repo** (the hook script plus the `bootstrap.sh` edit);
  the effect lands in each project repo's local configuration.
- The umbrella repo's own commits (`docs: …`) are out of scope — the convention exists for the
  project repos, where the cross-repo link is needed.

## Technical approach

To be settled at implementation, but the shape:

- One hook script tracked in the umbrella (e.g. `hooks/commit-msg`), ~10 lines: reject a commit
  message that neither starts with `DN-[0-9]+: ` nor matches the allowed exceptions (merge,
  release). The rejection message states the convention and names this file.
- `bootstrap.sh` installs it into each project repo — copy into `.git/hooks/` or set
  `git config core.hooksPath` — and stays safe to re-run, per its existing contract. A re-run also
  covers repos that were cloned before the hook existed.

## Out of scope

- Server-side enforcement (GitHub rulesets) — nothing to configure until pushes and PRs are routine
- Any change to the commit-message format itself
- Enforcing anything in the umbrella repo

## Test plan

Tooling Definition of Done — behaviour demonstrated, including the failure paths:

1. A commit with no ticket id is rejected, and the error states the convention
2. `DN-123: some change` is accepted
3. A merge commit and a `Release 1.2.3 …` message are accepted
4. Re-running `bootstrap.sh` neither duplicates nor breaks the installation

## Done when

- [ ] Hook implemented; installed in `DNLibrary`, `ios/DapurNaura`, `ios/SPMDNLibrary`
- [ ] `bootstrap.sh` installs it for fresh clones and is still safe to re-run
- [ ] All four cases above demonstrated
- [ ] Committed on `ticket/DN-007-commit-msg-hook`, not merged
- [ ] PR merged, ticket marked `done` by the human
