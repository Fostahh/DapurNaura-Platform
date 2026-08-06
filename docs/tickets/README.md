# Tickets

One file per ticket, named `DN-XXX-<type>-<short-slug>.md` — the type is in the filename so the
kind of work is visible without opening anything:

```
DN-001-technical-secure-storage-encryption.md
DN-005-product-cooking-class-list.md
```

The id comes first so files still sort in creation order, which matters because that id is the
thread linking commits across repositories. **Branch names stay `ticket/DN-XXX-short-slug`** —
without the type, since the id already identifies the ticket and branches get typed by hand.

This index is regenerated as tickets change — it is derived, so if it drifts from the files, the
files win.

Lifecycle, autonomy rules and the Definition of Done live in
[../ARCHITECTURE-AND-WORKFLOW.md](../ARCHITECTURE-AND-WORKFLOW.md) §4–§6.

---

## Two kinds of ticket

| | **Product** | **Technical** |
|---|---|---|
| Origin | A requirement document you wrote | A problem you or the agent noticed |
| `source:` | Required — points at `docs/requirements/` | Omitted; there is no document |
| First section | `## Requirement (traced)` — quoted from the doc | `## Rationale` — the argument, written here |
| "Why does this exist?" | Open the requirement document | It is in the ticket |

Everything else — technical approach, API contract, test plan, done-when — is identical.

A **product** ticket delivers something a user asked for. A **technical** ticket changes code
nobody asked about: testability, architecture, tooling, debt. Nobody writes a requirement document
saying "make the HTTP engine injectable," so without this split such work cannot be ticketed at
all.

**Classify by where the justification comes from, not by subject matter.** "Add offline caching"
is a product ticket if a user asked for offline access, and a technical ticket if you decided the
architecture needs it.

> **Keep the categories to two.** Add a new one only when the *process* differs — different gates,
> different traceability — never because the *topic* differs. A bug in a feature is a product
> ticket.

**One number sequence.** `DN-001`, `DN-002`, … regardless of type. Not `DNP-`/`DNT-`. One counter,
nothing to renumber if a ticket is reclassified, and commit messages stay uniform (`DN-004: …`) —
which matters, because that id is the only thing linking work across the separate repos.

---

## Index

### Product

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-008](DN-008-product-cooking-class-list.md) | Data layer — fetch the list of cooking classes | `in-review` | data |
| [DN-009](DN-009-product-cooking-class-list-ui.md) | iOS — cooking-class list screen (SwiftUI + MVVM) on GET /classes | `in-review` | both |
| [DN-011](DN-011-product-cooking-class-detail-data.md) | Data layer — fetch one cooking class with its recipes | `in-review` | data |
| [DN-012](DN-012-product-cooking-class-detail-ui.md) | iOS — cooking-class detail screen, status-driven buy button and recipe tappability | `in-review` | ui |

DN-008 and DN-009 trace to **verbal** instructions from the owner (2026-08-06) — the requirement
documents are deliberately deferred and should be backfilled when the requirements path is
exercised. DN-009's UI was verified by the owner on the running app before its commit, per the
platform's UI gate.

**DN-011 and DN-012 are the first tickets to trace to a real requirement document** —
[`../requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md),
approved 2026-08-06 — so their `source:` is a genuine link rather than a flagged deviation. They are
ordered: **DN-011 must land before DN-012**, which needs its use case and its stub replay. Both are
`todo` and unscheduled; the owner starts them.

### Technical

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-001](DN-001-technical-secure-storage-encryption.md) | SecureStorage stores plaintext on Android | `in-review` | data |
| [DN-002](DN-002-technical-network-manager-hardening.md) | Harden DNNetworkManager — timeouts, strict JSON, hide internals | `in-review` | data |
| [DN-003](DN-003-technical-ios-build-variants.md) | iOS build variants — Development / Alpha / Beta / Release via xcconfig | `in-review` | ios |
| [DN-004](DN-004-technical-remove-scaffolding-dtos.md) | Delete the leftover scaffolding DTO and endpoint from DNLibrary | `in-review` | data |
| [DN-005](DN-005-technical-publish-preflight-provenance.md) | publish-spm.sh — validate the source repo and record release provenance | `in-review` | tooling |
| [DN-006](DN-006-technical-network-engine-seam.md) | Make DNNetworkManager testable — engine seam, no singleton | `in-review` | data |
| [DN-007](DN-007-technical-commit-msg-hook.md) | Enforce the DN-XXX commit-message convention with a commit-msg hook | `in-review` | tooling |
| [DN-010](DN-010-technical-bilingual-prompt-protocol.md) | Bilingual prompt protocol — English docs, confirm-before-work gate | `in-review` | docs |
| [DN-013](DN-013-technical-lower-deployment-target.md) | Lower IPHONEOS_DEPLOYMENT_TARGET from 26.2 to 17.0 everywhere | `in-review` | ios |

**Branches are stacked in all three repos.** Each is built on the previous because they touch the
same files — **merge each repo's PRs in the order shown**:

| Repo | Stack |
|---|---|
| **DNLibrary** | `DN-001 → DN-002 → DN-004 → DN-006 → DN-008 → DN-009 → DN-011` |
| **ios/DapurNaura** | `DN-003 → DN-009 → DN-013 → DN-012` |
| **umbrella** | `DN-010 → DN-011 → DN-012 → DN-013` (DN-007 sits on its own branch off `main`) |

The umbrella stack exists because the ticket index and the rulebooks are shared files that every
one of those tickets touches; branching them independently would have produced four conflicting
edits of the same paragraphs.

**DN-010 changes the workflow standard itself**, not the product: it is the first `docs` ticket, and
the first to be filed and started in the same step because the owner's instruction scheduled it.
Its branch is cut from `main` — the umbrella repo has no `development` — independent of DN-007's.

### Done

_None yet._

---

## States

| State | Meaning | Who sets it |
|---|---|---|
| `todo` | Written up, not started | Agent, at creation |
| `in-progress` | Being implemented | Agent |
| `in-review` | Implemented, data-layer tests green, awaiting review | Agent |
| `done` | PR merged | **Human, manually** |

Rejections are verbal — flip back to `in-progress` and fix. If the same feedback arrives twice,
write it into the ticket so it survives the next session.

If implementation is blocked, append a `## Blocked` section, stop, and tell the human. Do not
improvise around it.

**The agent may create a technical ticket** at `status: todo` when it notices a problem — that is
how an incidental finding becomes tracked work instead of scope creep or a lost observation. It
must not **start** one until the human schedules it.

---

## Template — product ticket

```markdown
---
id: DN-005
type: product
title: Short imperative title
status: todo          # todo | in-progress | in-review | done
source: docs/requirements/2026-08-recipe-catalogue.md
branch: ticket/DN-005-short-slug
layer: data | ui | both | tooling | docs
---

## Requirement (traced)

> Quoted lines from the source document that this ticket satisfies.

[…shared sections below…]
```

## Template — technical ticket

```markdown
---
id: DN-001
type: technical
title: Short imperative title
status: todo
source: —             # no requirement document exists, and that is correct
branch: ticket/DN-001-short-slug
layer: data | ui | both | tooling | docs
---

## Rationale

What is wrong today, in specifics — name the file and the behaviour.
Why it is worth fixing now, and what it unblocks.

There is no requirement document to point at, so this section is the only record
of why this code changed. Write it for someone reading it in six months.

[…shared sections below…]
```

## Shared sections — both kinds

```markdown
## Context

Which files to read before starting, and anything already true that constrains the
approach. An agent starts every session cold — this is what stops it rediscovering
the codebase from nothing each time.

## Technical approach

What changes, where, and why. Name the files.

## Public API contract

What Swift and Kotlin callers see after this lands. DNLibrary ships as a binary, so
its public surface is a contract, not an implementation detail. Call out anything
source-breaking for existing consumers.

**Version bump implied:** patch | minor | major — and why.

## Out of scope

What this deliberately does not cover. Prevents sprawl, and saves an argument at review.

## Test plan

Specific cases, not "add tests". Which Gradle task proves it.
Data layer only — UI is verified manually by the human.

## Done when

Data-layer work:
- [ ] Code implemented on `ticket/DN-XXX-short-slug`
- [ ] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [ ] Committed, not merged

UI work:
- [ ] Code implemented on `ticket/DN-XXX-short-slug`
- [ ] Verified manually by the human
- [ ] Committed, not merged

Tooling work (scripts, build config):
- [ ] Change implemented
- [ ] Behaviour demonstrated, including the failure paths it should catch
- [ ] Committed, not merged

Docs work (the workflow standard itself):
- [ ] Every document stating the rule updated — they must agree with each other
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always:
- [ ] PR merged, ticket marked `done` by the human
```

---

## Filling it in

- **`type:`** decides whether `source:` or `## Rationale` carries the justification.
- **`layer:`** decides which gates apply. A `ui` ticket has no tests, no `publish-spm.sh` run, and
  no version bump. A `docs` ticket — a change to the workflow standard itself, like DN-010 — has no
  automated gate at all; the human reading the diff *is* the verification, so say in the ticket
  what they should be checking for.
- **Commit messages must start with the ticket id** (`DN-004: …`). The projects are separate git
  repositories, so that id is the only thread linking the work across them.
