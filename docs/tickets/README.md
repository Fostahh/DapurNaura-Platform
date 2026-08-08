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

> **Source of truth.** For *what was asked for*, `../requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

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
| [DN-008](DN-008-product-cooking-class-list.md) | Data layer — fetch the list of cooking classes | `done` | data |
| [DN-009](DN-009-product-cooking-class-list-ui.md) | iOS — cooking-class list screen (SwiftUI + MVVM) on GET /classes | `done` | both |
| [DN-011](DN-011-product-cooking-class-detail-data.md) | Data layer — fetch one cooking class with its recipes | `done` | data |
| [DN-012](DN-012-product-cooking-class-detail-ui.md) | iOS — cooking-class detail screen, status-driven buy button and recipe tappability | `done` | ui |
| [DN-020](DN-020-product-recipe-detail-data.md) | Data layer — fetch one recipe in full, as a list of components | `done` | data |
| [DN-021](DN-021-product-recipe-detail-ui.md) | iOS — the recipe screen, replacing the placeholder | `done` | ui |

DN-008 and DN-009 trace to **verbal** instructions from the owner (2026-08-06) — the requirement
documents are deliberately deferred and should be backfilled when the requirements path is
exercised. DN-009's UI was verified by the owner on the running app before its commit, per the
platform's UI gate.

**DN-011 and DN-012 are the first tickets to trace to a real requirement document** —
[`../requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md),
approved 2026-08-06 — so their `source:` is a genuine link rather than a flagged deviation. They are
ordered: **DN-011 landed before DN-012**, which needed its use case and its stub replay. Both are
`done` — merged 2026-08-08.

**DN-020 and DN-021 are the recipe screen — the level of the domain the product actually sells.**
Both are `done`, delivered 2026-08-07 and merged 2026-08-08. **103 data-layer tests pass** (up from 89) and
`swiftlint lint` reports **0 violations**, with every row of the iOS known-violations table now
struck — the last one, `RecipePlaceholderView`'s §3 exemption, died with the file DN-021 deleted. They are the first tickets whose
`source:` points at a requirement **known to be partly wrong**: the approved document describes
ingredients as a flat list with group labels, and the first real recipe proved a recipe is a list of
**components**, each with its own ingredients *and* its own method.

That is safe only because of what DN-019 put in place. The requirement carries
`corrected-by: DN-019, DN-020, DN-021` in its frontmatter, its prose is untouched, the corrected
shape lives in `docs/contracts/recipe.json`, and **both tickets carry the correction inside
`## Requirement (traced)`** — before the quote it modifies, not buried in an implementation note.

### Technical

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-001](DN-001-technical-secure-storage-encryption.md) | SecureStorage stores plaintext on Android | `done` | data |
| [DN-002](DN-002-technical-network-manager-hardening.md) | Harden DNNetworkManager — timeouts, strict JSON, hide internals | `done` | data |
| [DN-003](DN-003-technical-ios-build-variants.md) | iOS build variants — Development / Alpha / Beta / Release via xcconfig | `done` | ios |
| [DN-004](DN-004-technical-remove-scaffolding-dtos.md) | Delete the leftover scaffolding DTO and endpoint from DNLibrary | `done` | data |
| [DN-005](DN-005-technical-publish-preflight-provenance.md) | publish-spm.sh — validate the source repo and record release provenance | `done` | tooling |
| [DN-006](DN-006-technical-network-engine-seam.md) | Make DNNetworkManager testable — engine seam, no singleton | `done` | data |
| [DN-007](DN-007-technical-commit-msg-hook.md) | Enforce the DN-XXX commit-message convention with a commit-msg hook | `done` | tooling |
| [DN-010](DN-010-technical-bilingual-prompt-protocol.md) | Bilingual prompt protocol — English docs, confirm-before-work gate | `done` | docs |
| [DN-013](DN-013-technical-lower-deployment-target.md) | Lower IPHONEOS_DEPLOYMENT_TARGET from 26.2 to 17.0 everywhere | `done` | ios |
| [DN-014](DN-014-technical-ios-codebase-architecture.md) | Decide and document the iOS codebase architecture — CODEBASE-ARCHITECTURE.md | `done` | docs |
| [DN-015](DN-015-technical-apply-architecture-to-screens.md) | Bring the two existing screens up to CODEBASE-ARCHITECTURE | `done` | ui |
| [DN-016](DN-016-technical-move-formatters-to-library.md) | Move rupiah formatting and the Indonesian error vocabulary into DNLibrary | `done` | both |
| [DN-017](DN-017-technical-tidy-root-docs.md) | Move the standards documents out of the repository roots into docs/ | `done` | docs |
| [DN-018](DN-018-technical-per-repo-readme.md) | Give every repository a README, and settle on one name for the codebase document | `done` | docs |
| [DN-019](DN-019-technical-source-of-truth.md) | Settle where truth lives — hierarchy, requirement corrections, and the CLAUDE.md/playbook boundary | `done` | docs |
| [DN-022](DN-022-technical-agent-opens-prs.md) | Let the agent push ticket branches and open pull requests | `done` | docs |
| [DN-023](DN-023-technical-release-branch-topology.md) | publish-spm.sh refuses to release — its branch rule encodes the old topology | `done` | tooling |

**Branches are stacked in all three repos.** Each is built on the previous because they touch the
same files — **merge each repo's PRs in the order shown**:

Verified against git on 2026-08-07, not read off this index:

| Repo | Base | Stack |
|---|---|---|
| **DNLibrary** | `development` | ~~`DN-001`~~ ~~`DN-002`~~ **merged** → `DN-004` → `DN-006` → `DN-008` → `DN-009` → `DN-011` → `DN-017` → `DN-016` → `DN-018` → `DN-019` → `DN-020` |
| **ios/DapurNaura** | `development` | `DN-003` → `DN-009` → `DN-013` → `DN-012` → `DN-014` → `DN-015` → `DN-016` → `DN-018` → `DN-019` → `DN-021` |
| **umbrella** | `development` | `DN-010` → `DN-011` → `DN-012` → `DN-013` → `DN-014` → `DN-015` → `DN-016` → `DN-018` → `DN-019` → `DN-020` → `DN-021` (DN-007 sits on its own branch) |
| **ios/SPMDNLibrary** | `development` | `DN-018` → `DN-019` — its first ticket branches; the repo had no markdown at all |

**All four repos target `development`.** `main` is frozen until the app reaches `1.0.0`, when
`development` merges into it once — owner's instruction, 2026-08-07. The umbrella's `development` was
created from `main` at `30c711d` that day; it had none before.

**The umbrella takes no PRs** — its ticket branches are pushed into `development` directly. It
carries only docs and workspace config, so there is no build to break and nothing to review that was
not already reviewed on the ticket.

**Merge with a merge commit, not a squash.** DN-001 was, and `f263523` survived into `development`
as a result. That matters beyond one ticket: the commit SHAs recorded throughout these ticket files
stay valid, and every downstream branch stayed correctly based, so none needed rebasing. A squash
would rewrite `development`, orphan every branch above it, and turn ~20 recorded SHAs into dead
references. See [DN-022](DN-022-technical-agent-opens-prs.md).

**Work the lowest open id first.** Owner's instruction, 2026-08-06: tickets are reviewed and executed
in ascending order, and a higher id must not run ahead of a lower one. DN-016 already did — see
below — and that is the exception the rule exists to prevent, not a precedent.

**DN-015 is `done`.** Its original scope landed in `8d6937c`; an amendment on the same branch
then settled the folder conventions and navigation ownership the owner raised on 2026-08-06, and
added `DapurNauraAppRouter`, which `CODEBASE-ARCHITECTURE.md` §4 had specified since DN-014 without
anything implementing it. Awaiting the owner on the running app.

**DN-016 is `done`, delivered in two halves.** Its Kotlin half was committed (`28f00e2`) out of
order, *before* DN-015 and before the lowest-id-first rule existed — that commit stays, and this is
the exception that prompted the rule, not a precedent. The Swift half was held until the owner
approved DN-015 on 2026-08-06 and then landed: both Swift formatters deleted, eight call sites moved
to `DNFormat` / `DNErrorKt`, and `Helper/` gone entirely.

**`swiftlint lint` now reports 0 violations** — the first time, and every row in
`CODEBASE-ARCHITECTURE.md`'s known-violations table is struck. Keep it there: a clean linter makes
the next violation visible the moment it appears, which a habitual "3 known ones" never does.

⚠️ **DN-016 is the first ticket to need the full release path** — `publish-spm.sh publish`, a tag, a
GitHub release, then bumping the app off `../DNLibraryLocal` to the published version. All of it is
human-triggered and none of it has run. Until it does, the app builds only against the local package.

**DN-018 is `done`.** Every repository now carries a `README.md`, and the codebase document is
called `CODEBASE-ARCHITECTURE.md` everywhere — `DNLibrary`'s was renamed from `CODEBASE-STANDARD.md`,
which is why tickets DN-001 … DN-017 still cite the old name. **Those were left alone deliberately:**
a ticket records what was true when it was written, and rewriting closed work to match a later
decision makes the record lie. The renamed file carries a *formerly named* line so the old term still
resolves.

`docs/GETTING-STARTED.md` is gone, folded into the umbrella `README.md`. Four of its statements had
become false and were corrected rather than carried across.

**DN-019 states which artefact wins when documents disagree** — the requirement, and where none
exists, the ticket. Owner's instruction, 2026-08-07, after the agent revised an approved requirement
in place to absorb a corrected recipe shape. **That violated the standing immutability rule and was
reverted.** The rule is unchanged; what was missing was any document saying where truth lives, so
"put the correction in the ticket" read as bookkeeping rather than as the answer.

⚠️ **The approved recipe requirement is knowingly wrong and stays that way.**
`2026-08-06-recipe-detail.md` describes ingredients as a flat list with group labels. The first real
recipe proved a recipe is a list of **components**, each with its own ingredients *and* method. The
document is **not edited** — the corrected shape lives in `docs/contracts/recipe.json`, in
`docs/contracts/README.md`, and in the recipe tickets when they are written.

⚠️ **Found while writing SPMDNLibrary's README, and verified**: that repository has **no tags and no
releases**, and the binary-target URL in its `Package.swift` returns **404**. SPM resolves by tag, so
the package cannot resolve at all today. Nothing is broken in practice — the app has only ever built
against `ios/DNLibraryLocal` — and the first `publish-spm.sh publish` fixes all three in one step, so
no separate ticket was filed. It is recorded in that repository's README.

The umbrella stack exists because the ticket index and the rulebooks are shared files that every
one of those tickets touches; branching them independently would have produced four conflicting
edits of the same paragraphs.

**DN-010 changes the workflow standard itself**, not the product: it is the first `docs` ticket, and
the first to be filed and started in the same step because the owner's instruction scheduled it.
Its branch is cut from `main` — the umbrella repo has no `development` — independent of DN-007's.

---

## States

| State | Meaning | Who sets it |
|---|---|---|
| `todo` | Written up, not started | Agent, at creation |
| `in-progress` | Being implemented | Agent |
| `in-review` | Implemented, data-layer tests green, awaiting review | Agent |
| `done` | PR merged | Agent, **only after the owner says the PR is approved and merged** |

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
