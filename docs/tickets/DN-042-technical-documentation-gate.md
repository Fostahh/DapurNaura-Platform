---
id: DN-042
type: technical
title: The doc sweep is a list of remembered places rather than an enumeration, and it is not a gate
status: done
source: —
branch: ticket/DN-042-documentation-gate
merge-commit: 4755790
layer: docs
---

## Rationale

**The owner asked whether the rules had been updated. The honest answer had two halves, and the
agent got the first one wrong before checking.**

**A doc sweep rule already existed** — `AGENT-PLAYBOOK.md` §6, *"The doc sweep — after every
change"*, which says plainly: *"After each ticket, check and fix, in the same commit where
possible."* It was not missing. **It was followed badly, and it is built in a way that makes
following it badly the natural outcome.** Four specific faults, each of which caused a real miss in
DN-041:

1. **It is a table of remembered locations, not an instruction to enumerate.** A reader looks where
   the table points and stops there. That is the grep-versus-inventory failure encoded into the
   rule itself: a search finds what you thought of.
2. **It omits READMEs entirely.** It names *"each repo's `CLAUDE.md`"* and no `README.md`. Both
   READMEs were the files DN-041 missed — the umbrella's had said *"two screens run"* and *"the
   recipe screen is still a placeholder"* since DN-021, and `ios/DapurNaura/README.md` had been
   telling readers to build with a bare simulator name since DN-034, which that repository's own
   known issue 2 says fails.
3. **One of its paths is stale.** It points at `DNLibrary/CODEBASE-ARCHITECTURE.md`; DN-017 moved
   those documents into `docs/`. **The doc sweep section is itself a casualty of doc drift**, which
   is either the strongest possible argument for this ticket or the funniest, and probably both.
4. **It is not a gate.** It lives in the playbook and nowhere else. §6 of
   `ARCHITECTURE-AND-WORKFLOW.md` — the Definition of Done, the thing that decides whether work is
   finished — has never mentioned documentation. Nothing makes a ticket unfinished without it.

**Fault 4 is the load-bearing one, and DN-034 is the proof.** The agent could always have run
`xcodebuild`; it did not, reliably, until the Definition of Done said the work was unfinished without
it. Since then it has not been skipped once. Documentation has had a rule the whole time and no gate,
and has been skipped across at least four merged tickets.

**The owner has now given the instruction twice in one day**, 2026-08-11:

> "please synchronize umbrella projects and their repository with tickets or requirements"

and, after the agent committed and pushed with the job half done:

> "I've said that you need synchronize all of the .md before commit and push…"

`CLAUDE.md` already prescribes the response to that: *"If the same feedback comes up twice, write it
into the ticket or the relevant `CLAUDE.md` so it survives the next session."*

## Context

Read before starting:

- `docs/AGENT-PLAYBOOK.md` §6 — the rule that exists and what is wrong with it
- `docs/ARCHITECTURE-AND-WORKFLOW.md` §6 — the Definition of Done, and DN-034's build gate, which is
  the model this follows exactly
- `CLAUDE.md` — *Workflow: Document Driven Development*, the numbered loop
- `docs/tickets/README.md` — the four `## Done when` templates
- `docs/tickets/DN-041-technical-docs-login-drift.md` — the worked example, including its own miss
- `docs/tickets/DN-029-technical-docs-match-reality.md` — the finding this keeps proving

## Technical approach

**Documents only, all in the umbrella. No code and no PR** — `ios/DapurNaura/CLAUDE.md` already sends
the reader to the umbrella before starting a ticket, so duplicating the rule there would create a
second copy to drift.

| Document | What changes |
|---|---|
| `docs/ARCHITECTURE-AND-WORKFLOW.md` §6 | **A documentation gate**, beside the iOS build gate and applying to every layer rather than to `docs` tickets. This is fault 4, and the one that makes the rest bind |
| `docs/AGENT-PLAYBOOK.md` §6 | Leads with `git ls-files '*.md'`. The table is demoted to *"a prompt for what kind of thing goes stale — not the set of files to check"*. Gains READMEs and each repo's `docs/CODEBASE-ARCHITECTURE.md`; the stale `DNLibrary/` path is fixed |
| `CLAUDE.md` | The workflow loop gains the sweep as a numbered step before the review gate, so a session that reads nothing else still meets it. Later steps renumbered |
| `docs/tickets/README.md` | All four `## Done when` templates gain the line, so it is met at the moment it matters |

**The gate, stated once:**

> **A ticket is not finished until the documents match what it did.** Before offering work for
> review, enumerate every tracked `.md` in every repository the ticket touched — `git ls-files
> '*.md'` — and read the ones that could state a fact the ticket changed. Correct what is now false.

**Three rules the sweep follows**, all of them earned:

- **Enumerate, then read. Never grep and call it a sweep.**
- **Leaving a correct sentence alone is part of the job.** The playbook's own worked example carries
  a screen count inside a labelled historical snapshot; rewriting it would destroy the evidence the
  playbook is drawn from. A document that is merely *old* is not wrong.
- **Never write a count, a status or a version into prose.** Facts with no owner go stale between one
  merge and the next. Name the ticket; let the derived index carry the state. This is already
  `CLAUDE.md`'s rule for its own status block — DN-041 applied it to screen inventories, and it
  generalises.

**Requirement documents and `done` tickets stay excluded**, in wording that cannot be read as
permission to edit either. That rule is older than this gate and this gate does not weaken it.

## Public API contract

None. Documentation only.

**Version bump implied:** none.

## Out of scope

- **Automating it.** CI was ruled out by the owner on 2026-08-09 as *"very far off"*, and the ticket
  proposing it was deleted and marked not to be re-proposed. This uses the same compensating control
  as the build gate: a stated step, attested by the agent, in front of a human who reviews every diff.
- **A git hook.** A hook cannot tell whether a `.md` *should* have changed, so it would either pass
  always or nag always — and the second trains people to bypass it.
- **Re-sweeping the documents.** DN-041 did that and its result is current. This ticket changes the
  rules, not the prose.
- **Any code change**, in any repository.

## Test plan

Not code. What the owner is asked to check in the diff:

- §6 of `ARCHITECTURE-AND-WORKFLOW.md` carries the gate, beside the build gate, applying to every
  layer
- The playbook leads with the enumeration and demotes its own table; the `DNLibrary` path is correct
  and READMEs are named
- `CLAUDE.md`'s loop carries the step and **the later steps are correctly renumbered**
- All four `## Done when` templates carry the line
- The four documents agree with each other and none contradicts the DN-034 gate beside them
- Requirement documents and `done` tickets are excluded in unambiguous wording

## Done when

- [x] §6 of `ARCHITECTURE-AND-WORKFLOW.md` carries the documentation gate
- [x] `docs/AGENT-PLAYBOOK.md` §6 leads with the enumeration, names READMEs, and its stale
      `DNLibrary/CODEBASE-ARCHITECTURE.md` path is corrected
- [x] `CLAUDE.md`'s workflow loop carries the step, renumbered 4–8
- [x] All four `## Done when` templates in `docs/tickets/README.md` carry the line
- [x] The four documents agree with each other
- [x] Ticket index regenerated
- [x] Diff reviewed by the owner
- [x] Committed — `9254f0a`
- [x] No PR — every changed file is in the umbrella, which takes none by policy
- [x] Merged into `development` by the owner — `4755790`, 2026-08-11
- [x] Ticket marked `done` by the owner — 2026-09-11, on the grounds that the gate has since
      held: DN-043 and DN-044 each ran the enumeration and corrected five documents between them

## Notes

**The agent answered "no, the rules are not updated" before checking, and that was wrong.** The rule
existed in the playbook; only the gate was missing. The correction is recorded here rather than
quietly folded in, because the difference matters to anyone reading this later: this ticket is not
*"add a missing rule"*, it is *"a rule that existed was built so that following it badly was the
path of least resistance."* Those need different fixes, and only the second one explains why four
tickets' worth of drift got through review.

**Third instance of the same shape.** DN-029 found rules drifting wherever they were prose; DN-034
converted *"build it"* from prose into a gate and it has held since; DN-041 found three documents
stale across four tickets. The evidence is now strong enough to act on structurally rather than to
note again.
