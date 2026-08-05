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

_None yet — `docs/requirements/` is empty, so the product path has not been exercised._

### Technical

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-001](DN-001-technical-secure-storage-encryption.md) | SecureStorage stores plaintext on Android | `todo` | data |
| [DN-002](DN-002-technical-network-manager-hardening.md) | Harden DNNetworkManager — timeouts, strict JSON, hide internals | `todo` | data |
| [DN-003](DN-003-technical-ios-build-variants.md) | iOS build variants — Development / Alpha / Beta / Release via xcconfig | `in-review` | ios |
| [DN-004](DN-004-technical-remove-scaffolding-dtos.md) | Delete the leftover scaffolding DTO and endpoint from DNLibrary | `todo` | data |
| [DN-005](DN-005-technical-publish-preflight-provenance.md) | publish-spm.sh — validate the source repo and record release provenance | `in-review` | tooling |
| [DN-006](DN-006-technical-network-engine-seam.md) | Make DNNetworkManager testable — engine seam, resettable instance | `todo` | data |
| [DN-007](DN-007-technical-commit-msg-hook.md) | Enforce the DN-XXX commit-message convention with a commit-msg hook | `todo` | tooling |

Every `todo` ticket was filed by the agent and none is scheduled — the agent must not start one
until told to. Suggested data-layer order: DN-004 (pure deletion, smallest diff) → DN-006 (unblocks
all testing) → DN-002 (same file as DN-006 — decide whether to fold them before starting) → domain
modelling against `docs/contracts/`. DN-001 is independent and can be scheduled any time.

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
layer: data | ui | both | tooling
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
layer: data | ui | both | tooling
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

Always:
- [ ] PR merged, ticket marked `done` by the human
```

---

## Filling it in

- **`type:`** decides whether `source:` or `## Rationale` carries the justification.
- **`layer:`** decides which gates apply. A `ui` ticket has no tests, no `publish-spm.sh` run, and
  no version bump.
- **Commit messages must start with the ticket id** (`DN-004: …`). The projects are separate git
  repositories, so that id is the only thread linking the work across them.
