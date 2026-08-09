---
id: DN-027
type: technical
title: publish-spm.sh can still orphan a tag — no staleness guard, and a non-atomic push
status: in-progress
source: —
branch: ticket/DN-027-publish-atomic-tag-push
layer: tooling
---

## Rationale

**This hazard has already fired once.** On 2026-08-08 `0.5.0` was published from an `ios/SPMDNLibrary`
checkout four commits behind its remote — DN-018 and DN-019 had merged on GitHub in the meantime.
The script rewrote the manifest, committed and tagged **on the stale base**, and then:

```
git push origin HEAD --tags
```

**partly succeeded.** Git pushes refs independently. The branch was rejected as a non-fast-forward;
the tag went through anyway. The result was a published tag on a commit that existed on no branch,
with no release behind it. Repairing it required deleting a tag and a release — both on the `Never`
list, authorised once by the owner — and a by-hand purge of SPM's tag-to-commit fingerprint cache on
every machine that had already resolved `0.5.0`, with Xcode holding a second copy in DerivedData.

**The fix that was applied afterwards was prose.** `CLAUDE.md` gained a rule: fetch and pull both
repositories before every publish. The script was never changed. So the mitigation is a human habit
guarding an irreversible operation, and the failure mode is still fully present.

Three things are wrong, and they are separable:

**1. Nothing checks staleness.** `check_source_repo` verifies a clean tree, an allowed branch, and
that HEAD is contained in some remote branch — precisely the three checks the post-mortem in
`CLAUDE.md` describes as *"none of which notices staleness"*. A branch four commits behind still
passes all three.

**2. It never looks at `SPMDNLibrary` at all.** The preflight is named `check_source_repo` and only
ever inspects `DNLibrary`. The repo that broke `0.5.0` is the one the script rewrites, commits, tags
and pushes — and its only validation is a clean-tree check and a tag-collision check. Adding a
freshness check to `DNLibrary` alone would not have prevented the incident.

**3. The push is not atomic, and this is the structural bug.** A preflight reduces the *likelihood*
of a stale base. It does nothing about the ordering. As long as one command pushes both refs, a
rejected branch with an accepted tag remains a reachable state — including for anyone who overrides
the preflight, runs the non-interactive form, or hits a race between the check and the push.

**Owner's decision, 2026-08-09**, on being shown the two options:

> *A tag can only exist after its commit does — unreachable-by-construction, not merely unlikely.*

That settles the priority. The preflight is worth having, but the push split is the fix: pushing the
commit alone, checking it, and only then pushing the tag makes the orphaned state impossible rather
than improbable. It also survives someone skipping the preflight, which a preflight by definition
cannot.

**A fourth, smaller thing.** When the push failed, the script reported *"GitHub sign-in cancelled or
auth failed"*. Git had actually said `Note about fast-forwards`. The message named a cause the script
had not checked, and the wrong cause was the one everyone chased first. It should print what git
said.

## Context

Read before starting:

- `DNLibrary/scripts/publish-spm.sh` — `check_source_repo` (lines 56–87), `publish_remote`'s
  preflight (203–206) and its push (276–290)
- `CLAUDE.md` → *Publishing the iOS binary*, both indented rules — the incident and the repin rule
- `docs/tickets/DN-005-technical-publish-preflight-provenance.md` — why the preflight exists
- `docs/tickets/DN-023-technical-release-branch-topology.md` — the last time this constant was wrong

Already true, and constraining:

- **`publish` mode is human-triggered and irreversible.** Deleting a tag or a release is on the
  `Never` list, so a wrong outcome cannot be cleanly undone. This is the one script where a hard
  refusal is cheaper than a warning.
- **`preflight` and `dry` modes must keep working without side effects.** They are the rehearsal.
  Adding a `git fetch` makes them touch the network for the first time — acceptable, and noted in
  the help text, but they must still never write.
- **The existing four checks stay.** Clean tree, allowed branch, HEAD-on-a-remote, recorded
  provenance. This ticket adds; it removes nothing.
- **The script must not pull.** Refusing and naming the command is correct; silently pulling would
  change *what is being released* after the human has already read the plan.

## Technical approach

**1. A freshness helper, used for both repositories.**

```sh
# Publishing from a checkout behind its remote is what broke 0.5.0 (2026-08-08).
# Prints a problem line, or nothing. Never mutates the repo — refusing and naming
# the command is correct; pulling would change what is being released after the
# human has already read the plan.
check_behind_remote() {  # $1 = repo dir  $2 = label
  ...
  behind="$(git -C "$dir" rev-list --count "HEAD..origin/$branch")"
  [[ "$behind" -eq 0 ]] || echo "$label: $behind commit(s) behind origin/$branch — git -C $dir pull --ff-only"
}
```

Wired into `check_source_repo` for `DNLibrary`, and into `publish_remote` for `SPMDNLibrary` once
`spm_dir` is resolved. Both fatal under `confirm`, both a visible warning under `dry` — matching how
every existing check already behaves.

**2. The push, split and ordered.**

```sh
git push origin HEAD     # the commit, alone — checked
git push origin "$tag"   # only reachable once the commit is on the remote
```

The local tag is still created before either push; only the remote ordering matters, and that is what
makes the orphan unreachable. A failed branch push now `die`s **before anything is tagged remotely**,
so the release exits non-zero instead of returning 0 with a warning. A failed *tag* push is the safe
failure — the commit is on origin, nothing is orphaned — and prints the one command that finishes it.

**3. Print what git said.** Capture stderr from each push and include it verbatim in the failure
message, instead of asserting a cause that was never checked.

**4. The repin prompt.** After `gh release create`, print the repin checklist — pbxproj, resolve,
build, commit, and the DerivedData note. The rule already exists in `CLAUDE.md`; this puts it in
front of the person at the moment it applies. The script does **not** perform the repin: that needs
an Xcode resolve and a build judgement a shell script cannot make, and it would give this script
write access to a fourth repository.

## Public API contract

**None.** Tooling only — no Kotlin, no Swift, no published symbol.

**Version bump implied:** none. This ticket ships no library code.

## Out of scope

- **Automating the repin.** Printing the checklist is in; doing it is not, for the reason above.
- **Weakening or removing any existing check.**
- **CI.** Deferred by the owner on 2026-08-09 and deliberately unticketed — see the note in
  [`README.md`](README.md).
- **Retro-fixing `0.5.0`.** It was repaired on 2026-08-08 and its tag now points at `development`.

## Test plan

No automated gate — this is a shell script. Verified by running it:

1. `bash -n` and `shellcheck` clean.
2. **`preflight` from a level `development` reports release-clean** — the new fetch does not
   introduce a false positive.
3. **A deliberately stale checkout is refused.** Reset `ios/SPMDNLibrary` one commit behind its
   remote, run a dry run, and confirm it names the repo, the count and the `pull --ff-only` command.
   This is the case that would have prevented the incident and it must fail before the change.
4. **A dirty tree and an unlisted branch are still refused** — the existing checks survive.
5. **The push split is verified by reading the ordering**, not by breaking a real remote: the tag
   push is unreachable unless the branch push returned 0. A live non-fast-forward rehearsal would
   require deliberately corrupting a published repo, which the `Never` list forbids.
6. **Dry run writes nothing** — `git status` in both repos unchanged afterwards except the
   deliberately rewritten `Package.swift`, which the existing preflight already tolerates.

## Done when

- [ ] `check_behind_remote` exists and is applied to **both** `DNLibrary` and `SPMDNLibrary`
- [ ] Staleness is fatal under `confirm`, a visible warning under `dry`
- [ ] `push origin HEAD --tags` is gone; the branch and the tag are pushed separately, in that order
- [ ] A failed branch push exits non-zero **before** the remote is tagged, and prints git's own stderr
- [ ] The repin checklist prints after a successful release
- [ ] `bash -n` + `shellcheck` clean; stale-checkout case verified to refuse
- [ ] Committed on `ticket/DN-027-publish-atomic-tag-push`, not merged

## Notes

**The preflight is the smaller half of this ticket.** It is the half that reads as the fix, because
it is the half the post-mortem asked for — but it only lowers the odds. The push split is what
removes the state from the space of possible outcomes, and it is four lines.

Filed and scheduled in the same step on 2026-08-09, on the owner's instruction to fix the audit
findings, and on their explicit endorsement of the unreachable-by-construction approach over a
preflight alone.
