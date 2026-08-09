---
id: DN-028
type: technical
title: bootstrap.sh — the umbrella never gets the hook, and three of its facts are stale
status: in-progress
source: —
branch: ticket/DN-028-bootstrap-stale-facts
layer: tooling
---

## Rationale

`bootstrap.sh` is the first thing a new clone runs, so anything wrong in it is wrong at the moment
the workspace is least understood. Four things are.

**1. The umbrella repository never gets the commit-msg hook.** DN-007 built the hook to enforce the
`DN-XXX:` convention — the only thread linking a commit to its ticket across four repositories — and
the install loop iterates `REPOS` and `NO_REMOTE_YET`. Both list *project* repos. The umbrella is in
neither, so the one repository that **stores the hook** and receives **every ticket and docs commit**
is the only one not checked against the convention it defines.

Compliance there is currently perfect, which is the point: it is perfect by discipline, verified by
audit on 2026-08-09 rather than by the mechanism that exists for exactly this. Every other repo has
the mechanism.

**2. `ios/DapurNaura` is listed as having no remote.** It is `github.com/Fostahh/DapurNaura-iOS` and
has been since before DN-003 was pushed; eleven of its PRs are merged. `NO_REMOTE_YET` still
describes it as *"local-only repo, no remote configured yet"*, so `bootstrap.sh` **does not clone the
iOS app**. A new machine following the documented setup gets two of the three project repos and no
error — the app is reported as merely "not present", which reads as expected rather than broken.

**3. It points at a file DN-018 deleted.** The closing text says *"Read docs/GETTING-STARTED.md"*.
DN-018 folded that document into the umbrella `README.md` and `git rm`'d it. That ticket's own
done-criteria included **"No dead links, in either direction — the renamed file, the deleted
`GETTING-STARTED.md`"**; `bootstrap.sh` was missed because the sweep looked at Markdown.

**4. The hook install prints a path, not a repo.** Cosmetic, but with the umbrella added the output
`✓ .` would be meaningless.

**Why one ticket rather than four.** Same file, same review, same reason — every item is a statement
in `bootstrap.sh` that was true when written and is not true now. Splitting them would produce four
PRs against one file with no independent value.

## Context

Read before starting:

- `bootstrap.sh` — `REPOS` / `NO_REMOTE_YET` (27–36), the hook loop (71–86), the closing text (88–100)
- `hooks/commit-msg` — the exempt prefixes, which decide whether the umbrella's history stays valid
- `docs/tickets/DN-007-technical-commit-msg-hook.md` — why the hook exists and where it installs
- `docs/tickets/DN-018-technical-per-repo-readme.md` — the deletion this ticket cleans up after

Already true, and constraining:

- **The umbrella's existing history must stay valid under the hook.** It does: every commit is
  `DN-XXX: …`, `Merge …` or `docs: …`, and the hook exempts the last two. Verified across all 33
  umbrella commits on 2026-08-09. The one non-conforming subject, `Initialise umbrella repo`, is the
  root commit and cannot be re-checked.
- **Hooks live in `.git/hooks/` and are never committed.** Installation must stay idempotent and
  safe to re-run — `install -m 0755` already is.
- **The script must stay safe to re-run on a populated workspace.** Anything already cloned is left
  untouched, and that behaviour is load-bearing for everyone who already has the workspace.
- **Adding `ios/DapurNaura` to `REPOS` changes nothing for existing clones** — the loop skips any
  path that already has a `.git`.

## Technical approach

**The hook install becomes a function, called once for the umbrella and once per project repo:**

```sh
install_hook() {  # $1 = repo dir, $2 = label
  [[ -d "$1/.git" ]] || return 0
  mkdir -p "$1/.git/hooks"
  install -m 0755 "$HOOK_SRC" "$1/.git/hooks/commit-msg"
  echo "✓ $2 — commit-msg hook installed"
}

install_hook "$ROOT" "DapurNaura-Platform (umbrella)"
```

The umbrella is passed explicitly rather than added to `REPOS`, because `REPOS` is *"things to
clone"* and the umbrella is the thing you are standing in. Conflating them would make the clone loop
try to clone the workspace into itself.

**`ios/DapurNaura` moves into `REPOS`**, leaving `android` alone in `NO_REMOTE_YET` — which is now
accurate, since Android genuinely does not exist.

**The closing text points at `README.md`**, the document that absorbed `GETTING-STARTED.md`.

## Public API contract

**None.** Tooling only.

**Version bump implied:** none.

## Out of scope

- **Changing the hook's rules or its exempt prefixes.** This ticket installs it in one more place;
  what it enforces is DN-007's and is not reopened here.
- **Retroactively checking umbrella history.** The hook is `commit-msg` — it runs on new commits.
- **Adding Android.** It stays in `NO_REMOTE_YET` until it exists.

## Test plan

No automated gate — shell. Verified by running it:

1. `bash -n` and `shellcheck` clean.
2. **Re-run on this populated workspace**: reports all four repos already cloned, installs the hook
   into four repos including the umbrella, and clones nothing.
3. **The umbrella hook actually fires** — attempt a commit with a non-conforming message in the
   umbrella and confirm it is rejected, then confirm `docs: …` and `DN-029: …` both pass.
4. **`ios/DapurNaura` is no longer reported as remote-less**, and its entry names the real URL.
5. **No dead link** — `grep -rn 'GETTING-STARTED' bootstrap.sh` returns nothing.

## Done when

- [ ] The umbrella repo receives the commit-msg hook, with a labelled line in the output
- [ ] `ios/DapurNaura` sits in `REPOS` with its real remote; `android` alone in `NO_REMOTE_YET`
- [ ] The closing text points at `README.md`, not the deleted `GETTING-STARTED.md`
- [ ] Hook rejection verified live in the umbrella, and the `docs:` exemption still passes
- [ ] `bash -n` + `shellcheck` clean; re-run on a populated workspace clones nothing
- [ ] Committed on `ticket/DN-028-bootstrap-stale-facts`, not merged

## Notes

**The umbrella gap is the interesting one.** Every rule in this workspace that was encoded held
across 27 merged PRs; every rule left as prose drifted somewhere. The commit-msg hook is the clearest
example of the first kind — and it was never pointed at the repository that defines it. That is not a
failure of the rule, it is a failure of reach.

Filed and scheduled on 2026-08-09 as part of the audit fix-up.
