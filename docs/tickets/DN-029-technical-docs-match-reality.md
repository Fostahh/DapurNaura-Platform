---
id: DN-029
type: technical
title: The workspace documents describe a project that no longer exists
status: in-progress
source: —
branch: —
layer: docs
---

## Rationale

A compliance audit on 2026-08-09 checked every documented rule against 27 merged PRs, 6 releases and
four repositories. **The rules held.** What did not hold is the documentation of what the project
*is*: `CLAUDE.md` and `docs/ARCHITECTURE-AND-WORKFLOW.md` between them make roughly twenty statements
that were true when written and are false now.

This matters more than ordinary staleness for one reason: **`CLAUDE.md` is the only file loaded into
every session automatically**, and `ARCHITECTURE-AND-WORKFLOW.md` is the file it points at for the
ticket lifecycle. An agent starting cold reads both and acts on them. Today they disagree with the
repository, with each other, and in two places with themselves.

### The contradictions that change behaviour

**`ARCHITECTURE-AND-WORKFLOW.md` contradicts itself about DN-022.** §5 line 328 records the decision
correctly — the agent may push `ticket/*` and open PRs. But the §3 loop still reads *"Push + PR (the
human opens the PR; no gh)"*, the §4 lifecycle table still assigns `done` to **"Human, manually"**,
§5's own stop-and-wait list still contains *"Marking a ticket `done`"*, and §7's sequence table
repeats both. **An agent reading the §4 table waits for the owner to mark tickets done; an agent
reading `CLAUDE.md` does it itself.** Both believe they are compliant.

**The `Never` list forbids something the owner has explicitly permitted.** `CLAUDE.md` line 128 and
§5 line 322 both say an approved requirement is never edited, absolutely. `docs/requirements/README.md`
grants one exception — a `corrected-by:` frontmatter pointer, the owner's decision of 2026-08-07 —
and it has been used twice, correctly, prose untouched both times. A `Never` list with one
known-false entry teaches the reader that the rest are approximate.

**§7 states the opposite of the pinning rule.** It says the app depends on SPMDNLibrary *"by version
range (`.upToNextMajor`), not an exact pin"*. `CLAUDE.md` says exact for the whole of `0.x`, and the
committed `project.pbxproj` reads `kind = exactVersion; version = 0.6.0`. The document is wrong
against both the rule and the code.

**§7's versioning rule contradicts the settled scheme.** It describes *"a changed/removed public
symbol is a major"*. The scheme settled with the owner on 2026-08-07 is `0.MINOR.PATCH` — **minor for
any public API change**, patch for a behaviour fix — precisely because `0.x` makes no compatibility
promise. DN-004, DN-006 and DN-008 each removed public symbols and each shipped as a minor.

### The statements that are simply false

| Where | Says | Actually |
|---|---|---|
| `CLAUDE.md` status block | through DN-021, `0.5.0` published, DN-024/025 in flight | through DN-025, `0.6.0`, all trees clean |
| `CLAUDE.md` blockers | iOS `main` is a shell with four build variants | `main` is one `Initial Commit`, stock template |
| §1 | nothing merged, stacked branches, 89 tests, two screens | 27 PRs merged, 117 tests, three screens |
| §7 branches | the renames are local only; GitHub still shows `master` | all four repos have `origin/main` + `origin/development` |
| §7 versioning | tags `1.0.0`–`1.4.0` exist and need deleting | no `1.x` tag exists; only `0.1.0`–`0.6.0` |
| §7 iOS dependency | `Package.resolved` is deleted and must be restored | committed, pinning `0.6.0` |
| §7 sequence | release is cut `development` → `main` | DN-023 settled: cut from `development`; `main` frozen |
| §7 preflight | DN-005 is `in-review` | `done` |
| §9 item 6 | 89 tests, 45 Android / 44 iOS | 117 tests, 59 Android / 58 iOS |
| §9 item 10 | SPMDNLibrary has no tags, no releases, manifest 404s | 6 tags, 6 releases, resolves |
| §10 item 4 | the release half has never executed | it has run six times |
| §10 item 5 | 27 commits stacked, nothing merged — the largest risk | cleared 2026-08-08 |
| §10 item 6 | the recipe screen is unticketed | DN-020/DN-021, merged |

§10 also numbers two different items `5`.

### Why it drifted, which decides the fix

Both files hand-store **volatile state** — which tickets merged, which version is published, what is
in flight. That has to be rewritten by hand every time anything happens, so it is correct only for as
long as someone remembers. `docs/tickets/README.md`, which is explicitly labelled *derived*, is
perfectly current: updating it is part of the work.

**So the fix is not to rewrite the stale sentences. It is to stop keeping them.** Where a fact can be
read from `git log`, the ticket index, or the code, the document should point at it rather than
mirror it. Where a decision is restated in four places — as DN-022 is — propagating a change means
remembering all four, which is exactly what failed. Restating it once and linking is the durable fix.

The durable content stays: the domain, the entity relationships, the reasoning behind each rule, the
incident write-ups. None of that drifts, and it is what a cold-start agent actually needs.

## Context

Read before starting:

- `CLAUDE.md` — the status block, *Current known blockers*, the `Never` list
- `docs/ARCHITECTURE-AND-WORKFLOW.md` — §1, §3, §4, §5, §7, §9, §10
- `docs/requirements/README.md` §*The one permitted edit* — the wording the `Never` list must match
- `docs/tickets/README.md` — the derived index that stayed accurate, and the model to point at

Already true, and constraining:

- **Requirement documents are not touched by this ticket.** Their prose is frozen; the `corrected-by:`
  pointers already in place are correct and stay.
- **The rules themselves are not being changed.** Every correction here brings a *description* into
  line with a decision the owner already made — DN-022, DN-023, the `0.x` pin, the versioning scheme,
  the `corrected-by:` exception. Anything that would be a new decision belongs in its own ticket.
- **`AGENT-PLAYBOOK.md` is deliberately out of scope.** The audit found no false statement in it, and
  DN-019 already settled the split between it and `CLAUDE.md`.
- **`[OPEN]` markers that are genuinely still open must stay open.** Two are not: the branch renames
  and the `1.x` tags are both resolved. The publish-cadence question is answered by six releases of
  practice and is recorded as decided.

## Technical approach

**`CLAUDE.md`**

- The status block loses its volatile half. The domain paragraph stays; the "as of DATE / in flight"
  sentences are replaced by a pointer to `docs/tickets/README.md` and `git log`, with an explicit
  note that this file must not restate them.
- *Current known blockers* — the iOS `main` description corrected to what `main` actually contains.
- The `Never` list — *edit a requirement document* becomes *edit the **prose** of a requirement
  document*, with the `corrected-by:` exception named and linked.

**`ios/DapurNaura/CLAUDE.md`** — found during the sweep, not in the original audit, and carrying the
same range-vs-exact contradiction §7 had. Its *known issue 1* also still described the committed app
as not compiling for want of a package dependency; that has been false since DN-025 pinned `0.6.0`,
and it is the kind of statement that makes a healthy repository read as broken. Corrected, with the
version itself replaced by a pointer to `project.pbxproj`.

**`docs/ARCHITECTURE-AND-WORKFLOW.md`**

- **§1** rewritten against the repository as it stands, and dated.
- **§3** loop and **§4** table corrected for DN-022; the `done` row records that the owner's word is
  what authorises it and the agent sets it.
- **§5** stop-and-wait list corrected for DN-022; the duplicated *"Merging anything"* removed; the
  requirements line matched to the `corrected-by:` exception.
- **§7** — `main`'s role, the two resolved `[OPEN]`s struck, the versioning rule replaced with the
  settled `0.MINOR.PATCH` scheme, the dependency corrected against the code (**and then changed to a
  range by DN-030 — see *Done when***), the sequence
  table corrected for DN-022 and DN-023, DN-005 marked `done`.
- **§9** and **§10** rewritten: resolved items struck with what resolved them, the duplicate
  numbering fixed, and what actually remains open stated plainly.

**No new rules are introduced.** Every edit either records a decision already made or deletes a claim
the repository disproves.

## Public API contract

**None.** Documentation only.

**Version bump implied:** none.

## Out of scope

- **`AGENT-PLAYBOOK.md`** — checked; its only dated figures sit inside an explicitly historical
  session narrative, which is a record rather than a claim about today.
- **`DNLibrary/CLAUDE.md`** — checked clean against the code; it already describes DN-024's category
  work correctly.
- **`README.md` and `docs/contracts/README.md`** — checked clean.
- **Merged PR bodies.** They are the historical record and are not retro-edited, for the same reason
  approved requirements are not.
- **Any change to a rule.** Descriptions are corrected; decisions are not reopened.

## Test plan

Documentation, so the gate is cross-reading rather than execution:

1. **Every statement of fact re-derived from the repository** — `git log`, `git tag`,
   `gh release list`, the committed `project.pbxproj`, and a live `:sharedLogic:check` for the test
   count. No number copied from another document.
2. **No dead links** — every relative link in both files resolves to a file that exists.
3. **The two files agree with each other** on: who opens PRs, who marks `done`, how the app pins the
   library, how versions are chosen, and what may be edited in an approved requirement.
4. **`docs/requirements/README.md` and the `Never` lists agree** on the `corrected-by:` exception.
5. **Nothing in `docs/requirements/` is modified** — `git status` proves it.

## Done when

- [ ] `CLAUDE.md` holds no derivable state; the pointer replaces the status block
- [ ] Both `Never` lists carry the `corrected-by:` exception
- [ ] iOS `main` described as what it contains
- [ ] §1, §9, §10 rewritten against the repository and dated
- [ ] §3, §4, §5, §7 corrected for DN-022 and DN-023; both resolved `[OPEN]`s struck
- [ ] ~~§7 states the exact pin~~ **superseded by DN-030 the same day** — the owner changed the rule
      to a range before this ticket merged, so §7 now states the range and names what it replaced.
      The correction is recorded here rather than by rewriting the rationale above, which was true
      when written. §7 still states the `0.MINOR.PATCH` scheme, unchanged
- [ ] Every fact re-derived from the repo; no dead links; the two files agree
- [ ] `docs/requirements/` untouched

## Notes

**The audit's own finding is the argument for the approach.** Sorted by what backs them, the rules
separate cleanly: the commit-msg hook — 27 PRs, zero violations. `explicitApi()` — zero DTO leaks.
The token's scope — merging stayed the owner's, because the credential agrees with the policy. Every
one of those is encoded. Every rule that drifted was prose.

Documentation cannot be encoded the way a hook can. The next best thing is to write down less of it —
specifically, to stop writing down what a command can answer.

Filed and scheduled on 2026-08-09, on the owner's instruction to fix the audit findings and to bring
the documents into line with what the PRs actually did.
