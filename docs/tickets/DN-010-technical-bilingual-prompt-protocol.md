---
id: DN-010
type: technical
title: Bilingual prompt protocol — English docs, confirm-before-work gate
status: in-review
source: —
branch: ticket/DN-010-bilingual-prompt-protocol
layer: docs
---

## Rationale

The owner prompts in two languages. The repository is written in one.

Every document, ticket, code comment and commit message in this workspace is English. The owner
speaks Bahasa Indonesia and English, and will use either when instructing the agent. Until now the
workflow had nothing to say about that, which left two gaps a cold-started agent would fill by
guessing:

1. **What language the record is written in.** [`AGENT-PLAYBOOK.md`](../AGENT-PLAYBOOK.md) §1 says a
   verbal instruction from the owner is a requirement and must be quoted *verbatim*. Applied to an
   Indonesian instruction, that rule produces an Indonesian quote inside an otherwise English
   ticket. The rule and the repository's language convention collide, and nothing said which wins.
2. **Whether the agent may act on its own reading of a request.** The existing gates all sit
   *after* work exists — the owner verifies the running app, the owner triggers the commit. There
   was no gate before work started, so a misread instruction was only caught once it had already
   been built. Translation makes that more likely, not less: a misread Indonesian instruction and a
   confident English ticket look identical to the next agent reading the ticket.

The cost of a misread request here is not a wrong line of code. It is a ticket that misstates what
the owner asked for, which then becomes the permanent record of why the code exists — the exact
failure mode Document Driven Development exists to prevent.

### The originating instruction

> "Let's update the workflow. Sometimes i will prompt using Bahasa Indonesia, then you will
> translates it into English for docs purposes. Let's do the loop workflow for this case, you make
> sure what i mean, if i confirmed it with no assumptions, then you start working on it."
>
> — owner, verbal, 2026-08-06

Followed by, in the same session, after the agent flagged the risk that a translation rule could
bleed into the app's Indonesian content:

> "app-content language still the same, im just changing the workflow standard"
>
> — owner, verbal, 2026-08-06

### Decisions taken by the owner, 2026-08-06

The agent presented the ambiguities rather than resolving them. The owner's calls:

| Question | Decision |
|---|---|
| How Indonesian instructions are recorded | **English translation only.** The Indonesian original is not stored. |
| Scope of the confirm-before-work gate | **Every request, in any language.** |
| Where the rule lives | **A ticket first** (this one), then the doc edits. |
| Chat reply language | **Match the owner's language.** The repository stays English regardless. |
| App-content language | **Unchanged — Bahasa Indonesia.** This ticket changes the workflow standard only. |

The first decision deliberately narrows the playbook's `verbatim` rule. It is recorded here because
a future reader will otherwise find a translated quote and think the rule was broken.

## Context

Read before starting:

- [`../../CLAUDE.md`](../../CLAUDE.md) — the autonomy boundary this ticket extends
- [`../AGENT-PLAYBOOK.md`](../AGENT-PLAYBOOK.md) §1 — the `verbatim` rule being narrowed
- [`../ARCHITECTURE-AND-WORKFLOW.md`](../ARCHITECTURE-AND-WORKFLOW.md) §3, §5 — the loop diagram
  and the autonomy table
- [`README.md`](README.md) — the ticket template, whose `layer:` enumeration has no value for a
  docs-only change

Already true, and constraining:

- **The app is Bahasa Indonesia and stays that way.** `CLAUDE.md` states there is no English
  localisation and none is planned. Domain vocabulary (`kelas`, `bahan-bahan`, `loyang`) is kept
  untranslated on purpose because translation loses meaning. Any rule about translation must apply
  to the owner's *instructions* and never to the app's *content*.
- **The umbrella repo has no `development` branch** — only `main` and
  `ticket/DN-007-commit-msg-hook`. The workflow says ticket branches come off `development`; in
  this repo that branch does not exist, so this branch is cut from `main`, matching DN-007.
- **`docs/requirements/` is empty**, so the translation rule has no existing document to apply to.
  It applies from the next verbal instruction onward.

## Technical approach

No code. Six documents change; each owns a different slice of the rule, so the rule is stated once
in each place it is actually consulted, at the depth that place calls for.

| File | Change |
|---|---|
| `CLAUDE.md` | New **Language** section (what the rule is) + two entries in the autonomy lists (when it binds) |
| `docs/AGENT-PLAYBOOK.md` | §1 retitled and gains the confirm gate + the translation narrowing of `verbatim`; §7 gains it as the earliest stop condition |
| `docs/ARCHITECTURE-AND-WORKFLOW.md` | §3 gains a **Language** subsection and the confirm gate in the loop diagram; §5 gains the gate in *Stop and wait* |
| `docs/GETTING-STARTED.md` | The loop gains a step 0; the autonomy summary gains the gate — onboarding depth, one paragraph |
| `docs/tickets/README.md` | `layer:` enumeration gains `docs` + a docs done-when block; index gains DN-010 |
| `docs/tickets/DN-010-*.md` | This file |

`docs/requirements/README.md` is **not** touched — see `## Open questions`.

### The rule being written down

**Language.**

- The owner may prompt in Bahasa Indonesia or English. Everything written into any repository is
  English: requirement documents, tickets, `docs/`, code, comments, branch names, commit messages.
- An Indonesian instruction is recorded as the agent's **English translation**, attributed as
  translated and dated. This is a deliberate narrowing of `verbatim` — the obligation it replaces
  is that the translation be a faithful transcription, not an interpretation. `[ASSUMPTION]`
  marking still applies, and any wording whose meaning the translation could plausibly change goes
  to `## Open questions` instead of being silently resolved.
- **Never translate app content.** Domain terms and user-facing copy stay Indonesian. The rule
  covers what the owner says to the agent, not what the app says to its users.
- Chat replies match the owner's language. The repository does not.

**The confirm-before-work gate.**

- Before acting on a request, the agent restates its understanding and waits for the owner's
  confirmation. Every request, either language.
- The restatement names its assumptions, or states there are none — and "no assumptions" is a claim
  that has to be true when made.
- Anything ambiguous is asked, not chosen.
- Confirmation is per-request, the way commit authority is per-batch. Confirming one request does
  not pre-authorise the next.
- The gate is additive. It sits *before* work begins and replaces none of the existing gates: the
  owner still verifies the running app, and still triggers every commit.
- It does not apply to problems the agent notices on its own. Filing a technical ticket at
  `status: todo` stays autonomous — there is no instruction there to misread.

## Public API contract

None. No code changes, no library symbols affected, **no version bump** — `publish-spm.sh` is not
run for this ticket.

## Out of scope

- **The app's content language.** Bahasa Indonesia, unchanged, per the owner's correction above.
- **Translating anything that already exists.** The rule applies from the next instruction onward;
  no existing ticket is rewritten.
- **Backfilling the deferred requirement documents** for DN-008 and DN-009.
- **Automated enforcement.** DN-007's `commit-msg` hook checks the `DN-XXX` prefix; nothing
  mechanically checks language or the confirm gate, and nothing here proposes that it should.
- **`docs/requirements/README.md`**, pending the answer in `## Open questions`.

## Test plan

No tests — this ticket ships documentation, and `layer: docs` carries no automated gate. The data
layer is untouched, so `:sharedLogic:check` is not run and would prove nothing about this change.

Verification is the owner reading the diff. The check that matters: the rule as written in each of
the four documents says the same thing, and none of them can be read as licensing translation of
app content.

## Done when

Docs work:
- [x] Ticket filed with the owner's instruction and decisions recorded
- [x] `CLAUDE.md`, `AGENT-PLAYBOOK.md`, `ARCHITECTURE-AND-WORKFLOW.md`, `tickets/README.md` updated
- [x] Ticket index regenerated
- [x] Diff reviewed by the owner
- [x] Committed as `ae88e22` on `ticket/DN-010-bilingual-prompt-protocol`, not merged

Always:
- [ ] PR merged, ticket marked `done` by the human

## Open questions

1. **Is `docs/requirements/README.md` immutable?** The two rulebooks disagree.
   `ARCHITECTURE-AND-WORKFLOW.md` §5 forbids editing *"a file in `docs/requirements/`"*, which
   includes the README. `CLAUDE.md` forbids editing *"a requirement document once it is
   `status: approved`"* — and the README is a folder guide with no `status:` field, so that rule
   does not reach it. The playbook says `CLAUDE.md` wins on conflict, which would permit the edit.
   It was left untouched anyway, because the translation rule is fully stated in the four documents
   above and touching it buys nothing worth resolving an ambiguity for. **The README's drafting
   obligation — "every statement must be traceable to something the human actually said" — now has
   a translation step in front of it, so it is the natural place for a cross-reference.** If the
   owner confirms the narrower reading, add one line pointing at the language rule.

## Implementation notes

- **Filed and started in one step.** Filing a technical ticket is autonomous; starting one the
  agent filed itself is not. Here the owner's originating instruction both requested the change and
  scheduled it (*"then you start working on it"*), so the ticket was written directly at
  `in-progress` rather than staged through `todo` for a scheduling step that had already happened.
- **`layer: docs` is a new value** in the ticket template's enumeration
  (`data | ui | both | tooling`). None of the four fit: this ticket ships no code, so the data, UI
  and tooling gates all describe verification that cannot happen. Squeezing it into `tooling` would
  have attached a "behaviour demonstrated, including failure paths" checklist to a document change.
  The enumeration in `tickets/README.md` was extended rather than the ticket mislabelled.
- **Branched from `main`, not `development`.** The umbrella repo has no `development` branch; DN-007
  set the precedent.
- **This ticket exercised the gate it defines.** The agent restated the request, put the four
  genuine ambiguities to the owner rather than choosing defaults, and started only after the
  answers came back — including the app-content correction, which arrived unprompted and confirms
  the gate catches exactly what it is meant to catch.
