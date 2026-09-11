---
id: DN-045
type: technical
title: A ticket with no PR can never be marked done, because the rule only names a merged PR
status: in-review
source: —
branch: ticket/DN-045-done-without-a-pr
layer: docs
---

## Rationale

**DN-042 sat at `in-review` for a month with its work already merged, and nothing was wrong with it.**
The owner merged `ticket/DN-042-documentation-gate` into `development` as `4755790` on 2026-08-11.
The ticket stayed open until 2026-09-11, when the owner closed it by hand.

**The rule that closes a ticket names only one thing, and DN-042 did not have it.** Stated four
times across three documents, identically:

| Where | Wording |
|---|---|
| `ARCHITECTURE-AND-WORKFLOW.md` §5 states table | *"`done` \| PR merged \| Agent — only once the human says the PR is approved and merged"* |
| `ARCHITECTURE-AND-WORKFLOW.md` §6, *The ticket* | *"Done when the **PR is merged**, marked manually by the human."* |
| `docs/tickets/README.md` states table | *"`done` \| PR merged \| Agent, only after the owner says the PR is approved and merged"* |
| `CLAUDE.md`, autonomy | *"mark a ticket `done` once the owner has said its PR is approved and merged"* |

**The umbrella takes no pull requests, by its own policy** — its ticket branches are merged into
`development` with plain git. A ticket whose every changed file is in the umbrella therefore has no
PR, the condition can never be true, and **there is no state the ticket can legitimately reach.**

DN-042's own `## Done when` records the dead end precisely, which is why nothing looked wrong:

```
- [x] Committed, not merged
- [x] No PR — every changed file is in the umbrella, which takes none by policy
- [ ] Ticket marked `done` by the owner
```

The agent that wrote it was right on both lines. There was simply nothing that could tick the last
one.

**Three earlier umbrella tickets missed this by luck, not design**, which is why it took 44 tickets to
surface:

- **DN-029** went through a real PR — [DapurNaura-Platform#2](https://github.com/Fostahh/DapurNaura-Platform/pull/2) — back when the umbrella still took them
- **DN-034** shared DN-033's branch and rode an iOS PR, [DapurNaura-iOS#14](https://github.com/Fostahh/DapurNaura-iOS/pull/14)
- **DN-010** was marked `done` with *"PR merged, ticket marked `done` by the human"* still **unticked** — closed on the owner's say-so with the box left open, the same gap papered over rather than noticed

**DN-042 is the first ticket that was genuinely umbrella-only with no PR anywhere.** It will not be
the last: the doc-sweep gate DN-042 itself installed makes umbrella-only tickets *more* likely, not
less.

**Scheduled by the owner on 2026-09-11** — *"Yeah fix it then"* — after DN-042 was closed by hand.

## Context

Read before starting:

- `docs/ARCHITECTURE-AND-WORKFLOW.md` §5 (the states table) and §6 (*Definition of Done*)
- `docs/tickets/README.md` — *States*, and the four `## Done when` templates
- `CLAUDE.md` — *Autonomy*, both the "do without asking" and "stop and wait" halves

**`done` tickets are not edited**, so the ~20 closed tickets carrying an unticked
*"PR merged, ticket marked `done` by the human"* stay exactly as they are. They record what the rule
said when they were written, and DN-018 settled that rewriting closed work to match a later decision
makes the record lie. **Only the four live statements move.**

## Technical approach

**One clause, added wherever the rule is stated. No new rule, and no new authority for the agent.**

> Where a ticket produces no pull request — every changed file in the umbrella, which takes none by
> policy — the owner confirming the branch is merged closes it instead.

The owner's confirmation stays the trigger; what changes is that the confirmation may be about a
**merge** rather than only about a **PR**. The agent still never infers `done` from a green page, a
merge commit in the log, or its own judgement.

**Applied in four places**, so no document can be read on its own and give the old answer:

| File | Change |
|---|---|
| `ARCHITECTURE-AND-WORKFLOW.md` §5 | states table gains the no-PR case |
| `ARCHITECTURE-AND-WORKFLOW.md` §6 | *The ticket* gains the clause, with DN-042 named as the worked example |
| `docs/tickets/README.md` | states table matches §5 |
| `CLAUDE.md` | the autonomy line gains the same clause |

**The `## Done when` template also gains a no-PR variant**, so the next umbrella-only ticket writes
the right checklist rather than one it cannot finish.

## Public API contract

None. Documentation only.

**Version bump implied:** none.

## Out of scope

- **Closed tickets.** Not edited, for the reason in *Context*.
- **Giving the umbrella pull requests.** The policy that it takes none is deliberate — it carries only
  docs, there is no build to break, and nothing to review that was not already reviewed on the
  ticket. This ticket makes the closure rule fit that policy, not the other way round.
- **Letting the agent close a ticket on its own.** The owner's confirmation remains required. The gap
  was never that the agent lacked authority; it was that the owner had no defined way to give it.
- **Backfilling DN-042's month.** It was closed on 2026-09-11 and the dates are recorded honestly in
  its own file.

## Test plan

Documentation, so there is nothing to build or run. What proves it:

- The four live statements agree with each other and none can be read alone to give the old answer
- The `## Done when` template offers a no-PR variant
- No `done` ticket is modified — `git diff --name-only` lists no closed ticket file
- `git ls-files '*.md'` enumerated and every hit for the old wording checked (DN-042's own gate)

## Done when

- [x] `ARCHITECTURE-AND-WORKFLOW.md` §5 and §6 carry the clause
- [x] `docs/tickets/README.md` states table matches
- [x] `CLAUDE.md`'s autonomy line matches
- [x] A no-PR `## Done when` variant exists in the template
- [x] No closed ticket edited
- [x] Documentation sweep (DN-042) — enumerated with `git ls-files '*.md'`
- [ ] Diff reviewed by the owner
- [ ] Committed
- [ ] **No PR — every changed file is in the umbrella, which takes none by policy**
- [ ] Merged into `development`, and the owner confirms it — which is the clause this ticket adds,
      applied to itself

## Notes

**This ticket closes on the rule it writes**, which is the cleanest test available: if DN-045 can be
marked `done` without a PR, the gap is shut. If it cannot, the wording is still wrong.

**The gap survived 44 tickets because the failure is silent.** A ticket stuck at `in-review` looks
exactly like a ticket still being reviewed, and the derived index — correct in every other respect —
reported it faithfully as open. It took the owner asking *"Why DN-042 still in-review?"* for anyone
to check.
