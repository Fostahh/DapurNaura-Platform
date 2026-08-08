---
id: DN-022
type: technical
title: Let the agent push ticket branches and open pull requests
status: in-progress
source: —
branch: ticket/DN-022-agent-opens-prs
layer: docs
---

## In plain language

Right now the agent may write code and commit it, but not push it or open a pull request — so every
change stops on this machine until the owner moves it by hand. That has left **40 commits across
four repositories with nothing merged.**

This ticket lets the agent push ticket branches and open PRs. **It does not let the agent merge**,
tag, release, or push to `main` or `development`. A pull request is a *request*; the decision stays
the owner's.

## Rationale

Owner's instruction, 2026-08-07: *"Sekarang saya mau fokus ke GitHub PR. Bagaimana saya mengsetup
anda as an agent agar dapat membuat PR ke repository saya ini"* — agent's English translation per
DN-010: *"Now I want to focus on GitHub PRs. How do I set you up as an agent so you can create PRs
to my repositories?"*

**Two separate things blocked it, and installing a tool only fixes one.**

1. **Mechanical.** `gh` is not installed. `CLAUDE.md` and `ARCHITECTURE-AND-WORKFLOW.md` §9 both say
   so, and both are correct.
2. **Policy.** Both documents list *opening a PR* under **Stop and wait for the human**. With `gh`
   installed the agent still must not, and quietly doing it anyway would be exactly the kind of
   unilateral workflow change the owner reverted on 2026-08-07.

**Push and PR cannot be separated.** A pull request needs a pushed branch, and pushing is on the same
stop list. Granting one without the other is incoherent, so both move together — and only for
`ticket/*`.

**What deliberately does not move:** merge, tag, GitHub release, and any push to `main` or
`development`. Merge is a *decision*; the whole point of the review gate is that a human makes it.

## Context

Already true, and constraining:

- **40 commits, nothing merged, `Done` empty.** Stack depth is now the largest single risk in the
  workspace — see the PR chain below.
- **`.claude/settings.local.json` is git-ignored globally**, so permissions written there apply to
  this machine only. Rules meant to travel with the repository belong in `.claude/settings.json`,
  which the umbrella tracks under "docs/ + workspace config".
- **The agent runs git with `-C` in some places and `cd` in others.** A permission pattern matching
  only one form silently fails to cover the other, so the agent must standardise on `cd` into the
  repository before pushing, and the pattern is written for that form alone.

## Technical approach

### 1. Authentication — the owner's step, and the one with real blast radius

Owner's decision, 2026-08-07: **a fine-grained personal access token limited to the four
repositories**, not `gh auth login` over OAuth.

The difference matters. OAuth grants the CLI access to the owner's **entire GitHub account**; a
fine-grained token can be scoped to exactly these four repositories with two permissions:

| Permission | Why |
|---|---|
| **Contents:** read and write | push a branch |
| **Pull requests:** read and write | open and read a PR |

Nothing else — no `Administration`, no `Actions`, no `Workflows`. A token that cannot merge is a
second, independent guard behind the policy one: even a mistaken command cannot land code.

```sh
brew install gh
gh auth login --with-token < token.txt   # then delete token.txt
gh auth status                            # confirm the scope
```

### 2. Permissions

`.claude/settings.json`, committed:

```json
{ "permissions": { "allow": [
  "Bash(git push origin ticket/*)",
  "Bash(gh pr create *)",
  "Bash(gh pr list *)",
  "Bash(gh pr view *)",
  "Bash(gh pr diff *)"
] } }
```

`gh pr merge` is **absent, deliberately** — it is not an oversight to be tidied up later.

### 3. Documents to change

- `CLAUDE.md` — move *pushing a `ticket/*` branch* and *opening a PR* out of **Stop and wait** into
  **Do without asking**, with merge and release explicitly left behind.
- `docs/ARCHITECTURE-AND-WORKFLOW.md` §5 and §9 — the same, and §9's *"`gh` is not installed"* known
  issue is resolved.

## The PR chain — read this before opening anything

Every branch is stacked on the previous one, so **a PR must target the branch below it, not the base
branch.** Targeting `development` everywhere makes PR *n* display every commit from PRs 1…*n*, and a
reviewer cannot tell what any single ticket actually changed.

Verified against git on 2026-08-07, not read off the index:

| Repo | Chain (each targets the one before; the first targets the base) |
|---|---|
| **DNLibrary** → `development` | DN-001 → DN-002 → DN-004 → DN-006 → DN-008 → DN-009 → DN-011 → DN-017 → DN-016 → DN-018 → DN-019 → DN-020 |
| **ios/DapurNaura** → `development` | DN-003 → DN-009 → DN-013 → DN-012 → DN-014 → DN-015 → DN-016 → DN-018 → DN-019 → DN-021 |
| **umbrella** → `main` | DN-010 → DN-011 → DN-012 → DN-013 → DN-014 → DN-015 → DN-016 → DN-018 → DN-019 → DN-020 → DN-021 *(DN-007 stands alone off `main`)* |
| **ios/SPMDNLibrary** → `development` | DN-018 → DN-019 |

**That is 36 pull requests.** Owner's decision, 2026-08-07: **per ticket, all 36**, overriding the
agent's per-repo recommendation below. Each PR targets the branch beneath it in its chain.

## How PRs are opened — the owner's protocol

Settled with the owner on 2026-08-07. **The agent does not open PRs in a batch, and does not open one
unprompted.**

**Target branches.** Owner's instruction, 2026-08-07, superseding an earlier one that put the
umbrella on `main`: *"for development process, push into development, later on if the app already
version 1.0.0, then merged development into main."*

**All four repositories use `development`.** `main` is frozen until the app reaches `1.0.0`, when
`development` merges into it once. The umbrella had no `development` branch; it was created from
`main` at `30c711d` and pushed on 2026-08-07.

| Repo | Base |
|---|---|
| DNLibrary, ios/DapurNaura, ios/SPMDNLibrary, umbrella | `development` |
| all four | `main` — **only at 1.0.0** |

**The umbrella takes no pull requests.** Owner's instruction, 2026-08-07: *"umbrella just push, no
need PRs."* Its ticket branches are pushed into `development` directly. The umbrella carries only
docs and workspace config, so there is no build to break and no code to review — the review already
happened on the ticket itself.

**One "go" from the owner = one ticket's branch (or branches) opened as a PR into its target branch.**
The owner then merges it, and says "go" again for the next. The unit is **the branch, not the
commit** — owner's instruction: *"if the current branch have multiple commit, agent won't consider
the multiple commit. Just do the PR."* Three branches carry two commits (iOS DN-003, iOS DN-015,
umbrella DN-013); that changes nothing.

**Where a ticket spans two repositories** — DN-009 (DNLibrary + iOS), DN-011 (DNLibrary + umbrella),
DN-013, DN-016, DN-018, DN-019 — one "go" opens **both** PRs, each naming the other under
`### Dependencies`. Reviewing one half of a cross-repo ticket is reviewing half a change.

### Marking a ticket `done`

Owner's instruction, 2026-08-07: *"If i say approved and merged for the PR, mark the tickets into
done ya."* This moves `done` off the **Stop and wait** list, with a precise trigger.

**The owner saying the PR is approved and merged is the authorisation.** The agent then sets
`status: done`, ticks the final `Done when` box with the PR link and merge commit, and moves the row
into the index's `Done` section.

**What did not move:** the agent never infers `done` from a green PR page, from `gh pr view` showing
`MERGED`, or from its own reading of the diff. Observing the merge is not being told about it — the
gate is the owner's word, and only that.

### Rebase check — run before every push

Owner's instruction, 2026-08-07: *"If the PR branch isn't ahead of target branch, please rebase it
first."* Every branch is stacked on the one before it, so whether this triggers depends entirely on
how the owner merges.

```sh
git fetch origin
# $BASE is `development`, or `main` in the umbrella — see the table above.
git rev-list --count origin/$BASE..ticket/DN-XXX   # only this ticket's own commits?
#   yes → push, open the PR
#   no  → git rebase --onto origin/$BASE <parent> ticket/DN-XXX, re-check, then push
```

**No branch is pushed before this check**, so a rebase always happens before that branch's first
push. **This never requires a force-push**, which stays on the `Never` list — policy and mechanism
agree, rather than the mechanism quietly needing an exception.

| Merge method | Consequence for the next branch |
|---|---|
| **Merge commit** | original SHAs stay in `development`; the next branch is already based correctly; the check passes and no rebase happens |
| **Squash** / **Rebase and merge** | `development` gets new SHAs; every downstream branch is orphaned and must be rebased |

**Agent recommendation: merge commit.** Every commit is already one ticket carrying its `DN-XXX` id,
so squashing collapses one commit into one commit and buys nothing — while **rewriting the 20+ commit
SHAs recorded in the ticket files** (`f263523` in DN-001, `86c05ce` in DN-002, `ad281c8` in DN-012,
two more in `docs/tickets/README.md`, and so on). Those SHAs are part of how work is traced across
four repositories that share no history. Squashing is still the owner's call; it just costs a
back-writing pass afterwards.

## PR title and body — the agreed format

Owner's format, settled 2026-08-07. It is the owner's existing habit, not something invented here.

**Title:** `DN-XXX: <the ticket title>` — the same id that is already in every commit message, because
that id is the only thread tying work together across four repositories.

**The governing rule: a section appears only when it has content.** Owner's instruction, 2026-08-07:
*"If evidence is empty, delete it."* No placeholder headings, no empty tables, no dashes standing in
for content. Most PRs are therefore `### Description` alone.

**Body — the full set of sections, none of them mandatory except the first:**

```markdown
### Description
Optional sentence of context, then:
- What changed

### Evidence

| Device | Result |
| - | - |
| iPhone 15 Pro, iOS 17.5 | … |

### Dependencies
- [DNLibrary#12](https://github.com/Fostahh/DNLibrary/pull/12)

### RCA
Why the bug existed.
```

- **`### Description`**, not *Changes*. A bullet list cannot hold a caveat gracefully; a Description
  can open with a sentence of context first. DN-020 and DN-021 need exactly that — the requirement
  they trace to is partly wrong, and the reader has to meet that before the bullets.
- **`### Evidence`** — screenshots or a device table, when there are any. **Omitted otherwise.** The
  owner may add it to a PR by hand after the fact; the agent does not pre-create the heading.
- **`### Dependencies` is a link, nothing more.** Owner's instruction, 2026-08-07: *"no need to be
  confused by tag, release, etc. Just put a reference link into the PR from DNLibrary."* A cross-repo
  dependency is one line pointing at the other repository's PR. GitHub cannot enforce it and this
  format does not pretend otherwise.

### What counts as a dependency — the owner's rule

Owner's clarification, 2026-08-07, in their own example:

> Requirement A causes two tickets. **Ticket A** is data, so DNLibrary. **Ticket B** is UI, so
> DapurNaura. Ticket A's PR has no dependencies — it *is* the data. Ticket B's PR depends on Ticket
> A's, because the data is consumed from it.
>
> If **Ticket C** is UI and uses the *same* API as Ticket A, Ticket C does **not** reference Ticket
> A's PR — that API was already there before Ticket C was created or developed.

**The test is "did this ticket's work require that library change?" — not "does this ticket use
library code?"** A dependency is a link between two halves of *one delivery*. Once an API is merged
and available, it stops being a dependency and becomes the platform. Nobody lists the standard
library.

Two dimensions, and they are easy to confuse:

- **Scope — which PRs get a link?** Only those whose consumed API was introduced by the same
  delivery. Ticket C gets nothing, however heavily it uses the library.
- **Lifetime — does the link expire?** No. Owner's instruction, 2026-08-07: *"If I merge the
  DNLibrary and SPMDNLibrary and creates the tag version, I still wants you to point out the
  dependencies DapurNaura have into DNLibrary PR."* Once Ticket B has the link it keeps it, merged
  and tagged or not. It records *why the app needed that library change* — and it is the only path
  from a Swift call site back to the Kotlin PR that created it, because the two repositories share
  no history and the `DN-XXX` id is the whole thread.

### Which iOS PRs name a DNLibrary PR

Derived on 2026-08-07 from each branch's own diff — the symbols it **introduces**, not the ones it
inherits. **Two iOS tickets depend on a differently-numbered DNLibrary ticket**, which is where
guessing from the id would go wrong.

| iOS ticket | Depends on | Library API the delivery introduced |
|---|---|---|
| DN-009 | **DNLibrary DN-009** (on DN-008) | `GetCookingClassesUseCase`, `CookingClass`, `DNDataLayer`, `DNError` |
| DN-012 | **DNLibrary DN-011** ⚠️ | `GetCookingClassDetailUseCase`, `CookingClassDetail`, `RecipeSummary`, `PurchaseStatus` |
| DN-016 | **DNLibrary DN-016** | `DNFormat`, `DNErrorKt` — the same ticket in both repos |
| DN-021 | **DNLibrary DN-020** ⚠️ | `GetRecipeUseCase`, `Recipe`, `RecipeComponent`, `Ingredient`, `RecipeStep` |

**No `### Dependencies` section:** DN-003, DN-013, DN-014, DN-015, DN-018, DN-019.

**DN-015 is the case the rule exists for.** It adds **13** `import DNLibrary` lines — more than any
other iOS ticket except DN-021 — and consumes `CookingClassDetail`, `PurchaseStatus`,
`GetCookingClassDetailUseCase` and more. It still gets **no dependency**, because it introduces none
of them: it re-architects around API that DN-011 had already delivered. Counting imports would have
produced a link here; asking whether the ticket *required* a library change does not.
- **`### RCA`** — **any PR that fixes a defect**, which in this workspace means bug tickets *and*
  `type: technical` tickets correcting something already wrong in the code. Owner's instruction,
  2026-08-07: *"if defect fix too, add RCA."* There is no `bug` ticket type here, so reading "bug
  tickets only" literally would have meant RCA never appeared at all. It does **not** apply to
  technical tickets that add capability rather than fix a defect — an engine seam or a docs tidy has
  no root cause.

  Four things, briefly: **cause** (what was actually wrong), **why it survived** (what should have
  caught it and didn't), **impact** (including "none", when nothing shipped), and **prevention**
  (the specific test or rule that makes recurrence visible — not a promise to be careful).

## Public API contract

None. Configuration and documentation only.

## Out of scope

- **Merging.** Not now, and not as a follow-up.
- **Tags and GitHub releases.** Still human-triggered, still `publish-spm.sh publish`.
- **Pushing to `main` or `development`.** The permission pattern cannot express it and the token
  should not allow it.
- **CI.** A deliberate deferral the owner has asked not to have re-raised.
- **Installing `gh` or creating the token.** The agent cannot and should not — it is the owner's
  account.

## Open questions

**None. Answered by the owner on 2026-08-07: per ticket, 36 PRs.** The reasoning below is kept as the
record of what was weighed, not as an open choice.

**36 PRs is a large review burden for work that is already written and verified.** The alternative is
one PR per repository, from the tip branch to the base — **4 PRs instead of 36**.

| | Per ticket (36) | Per repo (4) |
|---|---|---|
| Review granularity | one ticket per PR, each reviewable alone | one enormous diff per repo |
| Bisecting later | precise | still precise — the commits survive either way |
| Effort to open | 36 correctly-based PRs | 4 |
| Effort to review | 36 rounds | 4, but each very large |
| Risk of a wrong base | high — 36 chances | almost none |

**Agent recommendation was per repo, this once — the owner chose per ticket.** The per-ticket value is *review*, and the owner has
already reviewed and approved every one of these tickets as it was built — a second review would be
the same content a second time. The commits keep their `DN-XXX` messages either way, so history and
bisecting lose nothing. **Then go per-ticket from DN-022 onward**, when a PR is reviewed before
approval rather than after.

## Test plan

No automated gate.

1. `gh auth status` shows a token scoped to the four repositories, not the whole account.
2. `git push origin ticket/…` succeeds; a push to `development` is refused by the token.
3. `gh pr merge` is not in the allow list.
4. Every document stating the autonomy rule agrees with the others.
5. A PR opened by the agent names its ticket id in the title and targets the correct base.

## Done when

- [ ] Owner installs `gh` and creates the fine-grained token
- [x] `.claude/settings.json` written with push and PR permissions, merge withheld
- [x] `CLAUDE.md` and `ARCHITECTURE-AND-WORKFLOW.md` updated and agreeing
- [x] Owner decides 36-PR versus 4-PR — **per ticket, 36**
- [x] PR title and body format agreed with the owner
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Notes

Filed and started on 2026-08-07 in the same step, because the owner's instruction scheduled it — the
same pattern as DN-010 and DN-019.

**The agent cannot complete this ticket alone**, and that is by design: the two steps that grant it
new power — installing `gh` and minting the token — are the owner's, on the owner's account.
