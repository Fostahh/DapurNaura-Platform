---
id: DN-019
type: technical
title: Settle where truth lives — the hierarchy, how a wrong requirement is corrected, and the CLAUDE.md/playbook boundary
status: done
source: —
branch: ticket/DN-019-source-of-truth
layer: docs
---

## In plain language

When two documents disagree — or a document disagrees with the code — which one is right?

Nothing in this workspace answers that. This ticket writes the answer into every document:
**the requirement is the source of truth; where no requirement exists, the ticket is.**

Nothing about the app changes. No code is touched.

## Rationale

Owner's instruction, 2026-08-07, given in Bahasa Indonesia and recorded as the agent's English
translation per DN-010:

> "The note that must be placed in all markdown is: requirement is the source of truth; if there is
> no requirement, then TICKETS are the source of truth. Put this into the context of our markdowns."

**What forced it.** On 2026-08-07 the owner supplied the first real recipe and the shape turned out
different from the approved requirement — a recipe is a list of components, not a flat ingredient
list with group labels. The agent's response was to revise the requirement in place, which
**violated the standing rule that an approved requirement is immutable**. The owner reverted it and
restated the rule: corrections go in the ticket, never into the requirement.

The failure was not a missing rule — `CLAUDE.md` and four other documents already said it. The
failure was that no document said **which artefact wins** when they conflict, so "put the correction
in the ticket" read as bookkeeping rather than as the answer to "where does truth live".

**Why it needs stating in every document rather than one.** An agent starts every session cold and
may open any single file first. A precedence rule that exists in one document is a rule the reader
has to already know about in order to find.

**The distinction this must not blur.** `AGENT-PLAYBOOK.md` §0 already says *"believe files over
documents — docs drift; code and git history do not."* That is about **facts**: what the code
currently does. The new rule is about **intent**: what was asked for. They do not conflict, but
stated carelessly they appear to, so both must name which of the two they govern.

## Context

- **`docs/AGENT-PLAYBOOK.md` §0** — carries the "believe files over documents" rule. Must be
  extended, not contradicted.
- **`docs/requirements/README.md`** — carries the immutability rule this reinforces.
- **`docs/contracts/README.md`** — contracts are approved but revisable, so they sit *below* the
  requirement in the hierarchy and the note must not imply otherwise.

Already true, and constraining:

- **Requirement documents are not edited by this ticket.** They are the source of truth being
  described; adding a banner to one would be editing an approved document to make a point about not
  editing approved documents.
- **Ticket files are not back-edited either.** They are records.

## Technical approach

One block, worded the same everywhere, adapted only in scope:

> **Source of truth.** For *what was asked for*, `docs/requirements/` wins — over the code, over any
> other document, over a commit message. Where no requirement exists, **the ticket is the source of
> truth** and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

Applied to 13 documents — the umbrella's five, the three contract/ticket/requirement indexes, and
each project repo's `README.md`, `CLAUDE.md` and `CODEBASE-ARCHITECTURE.md`.

**Not applied to:** files under `docs/requirements/` (frozen, and they *are* the source of truth) or
`docs/tickets/DN-0XX-*.md` (records of past work).

### The `CLAUDE.md` / `AGENT-PLAYBOOK.md` boundary

Asked by the owner on 2026-08-07: *what makes them different, and why is the playbook needed?*
Answering it exposed a leak, so the fix lands here.

**The distinction that actually justifies two files is mechanical, and neither document stated it.**
`CLAUDE.md` is loaded automatically at the start of every session; `AGENT-PLAYBOOK.md` is only read
if the agent obeys an instruction to read it. Therefore:

| | `CLAUDE.md` | `AGENT-PLAYBOOK.md` |
|---|---|---|
| Loading | guaranteed | depends on compliance |
| Holds | anything whose absence could **do damage** | anything that **raises quality** |
| Cost | paid every session — must stay short | read once per ticket — may be long |
| Content | this project's facts and permissions | transferable craft |

**The leak.** §7 *Stop conditions* listed four stops and then closed with *"anything in `CLAUDE.md`'s
lists → exactly that"* — so the four were a second copy of a list that already existed. §1 restated
DN-010's Bahasa Indonesia translation rule almost in full. That is exactly the failure DN-014's test
plan names: *a rule written twice is a rule that will disagree with itself later.*

**Fixed by making both sections point rather than copy.** §1 keeps only what `CLAUDE.md` does not
say — *why* the confirmation gate exists, and that "no assumptions" is a claim to be earned. §7 keeps
the habit (stop early, a blocker is a stop not a puzzle, UI work stops for eyes) and names
`CLAUDE.md` as the authoritative list.

**One rule was in the wrong file and moved.** *"A destructive or irreversible act you were not
explicitly asked for → ask first"* lived only in §7 — a permission rule sitting in the file with no
guaranteed loading. It is now in `CLAUDE.md`'s **Stop and wait** list, broadened to name what it
means: deleting, overwriting or rewriting something you did not create, whether or not it appears on
the `Never` list.

**Two overlaps were checked and deliberately left.** `git add -A` appears in both — `CLAUDE.md`
forbids it, the playbook explains why (`-A` sweeps in what must never be committed; `-u` silently
misses new files) and records the incident. That is rule versus reason, which is the split working.
`force-push` in §8 is a clause inside the honesty rule about repairing a mistake, not a restatement.

## Public API contract

None. Markdown only.

### Two additions to `docs/requirements/README.md`

Both follow from the same incident, and the owner chose both on 2026-08-07.

**1. One permitted edit: a `corrected-by:` pointer.** When part of an approved document turns out
wrong, its **frontmatter** may gain a line naming the ticket carrying the correction. **The prose is
never touched** — not softened, not deleted, not de-`[ASSUMPTION]`ed. The wrong sentence stays,
visibly wrong.

This is the narrowest possible carve-out, and it does not weaken the rule it sits inside. The rule
protects the *evidence* — what was asked for, on what date. A pointer alters no evidence; it makes
the correction findable by the one reader who most needs it, the person who opened the requirement
first rather than the index. A retracted paper keeps its text and gains a retraction notice.

**2. Do not describe data shapes in a requirement.** This is what made the pointer necessary, and it
is the part that prevents recurrence rather than managing symptoms.

`2026-08-06-recipe-detail.md` did not become wrong because the owner changed their mind. It became
wrong because it **described a shape instead of a need** — *"kept in their groups (Bahan A, Bahan
B)"* — and a shape belongs in `docs/contracts/`, which is revisable by design. Had it said *"the
parts of a recipe must not be merged — a student must be able to prepare each part separately"*, the
component structure would satisfy it exactly and nothing would need correcting.

The drafting test, now written into the README: **if a sentence could be answered with "that depends
what the JSON ends up looking like", it is not a requirement.** It goes to `## Open questions`, or is
rewritten as a need that does not care about the shape.

## Out of scope

- **Changing the immutability rule.** An earlier draft of this ticket proposed numbered revisions for
  approved requirements. **The owner rejected it on 2026-08-07** — the rule stands as written. Do not
  reopen it. The `corrected-by:` pointer above is not that proposal: it adds metadata and leaves
  every word of the content alone.
- **Recording the recipe shape change.** The corrected shape — components, `merk`, `note` — belongs in
  the recipe tickets and in `docs/contracts/`, which is revisable by design. It is *not* going into
  the requirement.

## Open questions

**None.**

## Test plan

1. Every listed document carries the block, worded identically.
2. No file under `docs/requirements/` was touched.
3. `AGENT-PLAYBOOK.md` §0 and the new block read as complementary, not contradictory — one names
   facts, the other names intent.
5. No stop condition or permission rule exists **only** in `AGENT-PLAYBOOK.md`. Anything whose
   absence could do damage is in `CLAUDE.md`, because that is the only file guaranteed to load.
6. `AGENT-PLAYBOOK.md` §1 and §7 point at `CLAUDE.md` rather than restating it, and the overlaps
   that remain are reason-behind-a-rule, not a second copy of the rule.
4. No document claims a contract or a `CLAUDE.md` outranks a requirement.

## Done when

- [x] Every document stating the rule updated — they must agree with each other
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Notes

Filed and started on 2026-08-07 in the same step, because the owner's instruction scheduled it —
the same pattern as DN-010.

**Recorded correction, per the rule this ticket describes.** The approved requirement
`2026-08-06-recipe-detail.md` describes ingredients as a flat list with group labels. **That is
wrong**, and every word of it stays. The correct shape — a recipe is a list of **components**, each
with its own ingredients *and* its own method, split so a student can measure each into a separate
bowl — is recorded in `docs/contracts/recipe.json` and `docs/contracts/README.md`, and will be traced
in the recipe tickets when they are written.

That document now carries `corrected-by: DN-019` in its frontmatter, with three comment lines naming
which bullet is wrong. **Verified: prose unchanged at 82 lines before and after; the diff is four
frontmatter lines and nothing else.**

`corrected-by:` points at DN-019 rather than at the recipe data ticket because that ticket does not
exist yet. **When it does, append it** — the pointer is a list, and the first entry is the one that
recorded the correction, not necessarily the one that implements it.
