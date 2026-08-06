---
id: DN-018
type: technical
title: Give every repository a README, and settle on one name for the codebase document
status: todo
source: —
branch: ticket/DN-018-per-repo-readme
layer: docs
---

## In plain language

Every project folder should carry the same three documents: a short front page saying what the thing
is (`README.md`), the instructions an AI agent reads automatically (`CLAUDE.md`), and the rulebook
for writing code in it (`CODEBASE-ARCHITECTURE.md`). Two of the three folders are missing the front
page, and the rulebook is called two different names in two places.

This fixes both, and folds the existing setup guide into the umbrella's new front page so a newcomer
has one place to start instead of two.

Nothing about the app changes. No code is touched.

## Rationale

Owner's instruction, 2026-08-06: *"Each repository have their own README.md and CLAUDE.md and
CODEBASE/ARCHITECTURE. Only Umbrella has WORKFLOW that will explains the WORKFLOW of Umbrella into
iOS and Android."*

Current state against that model:

| Repo | `README.md` | `CLAUDE.md` | Codebase doc | Workflow |
|---|---|---|---|---|
| umbrella | **missing** | ✅ | — *(no code; correct)* | ✅ `docs/ARCHITECTURE-AND-WORKFLOW.md` |
| `DNLibrary` | ✅ 27 lines, thin | ✅ | ✅ `docs/CODEBASE-STANDARD.md` — **wrong name** | — |
| `ios/DapurNaura` | **missing** | ✅ | ✅ `docs/CODEBASE-ARCHITECTURE.md` | — |
| `android` | not created | | | |

**Why the name matters.** `CODEBASE-STANDARD` and `CODEBASE-ARCHITECTURE` are the same slot in the
same model, and the Android app will need a third one before anybody decides what to call it. A slot
whose name is guessed per repo is a slot a cold-started agent cannot find by convention.

**Why the READMEs matter, and what they are not for.** This workspace already carries 2,732 lines of
markdown across eight documents. A README that restates any of it is a rule written twice, which
DN-014's own test plan identifies as the failure mode — two copies disagree eventually, and the wrong
one gets followed. The README is an **orientation** document: what this repo is, what it is built
with, how the pieces fit, and where to go for everything else. It links; it does not duplicate.

Note also that `README.md` is **not** auto-loaded by an agent — `CLAUDE.md` is. The README's audience
is a human arriving cold, and GitHub's landing page. That is why it is worth having and why it must
not become the place rules live.

## Context

Read before starting:

- **`~/Desktop/XcodeProjects/MovieDB/README.md`** — the owner's model, 68 lines: one-paragraph
  summary, `## Features`, a `## Tech Stack` table, `## Architecture` with an ASCII flow diagram,
  `## Project Structure` as a tree, `## Requirements`. Match this shape. It works there because it
  is that repo's *only* document; here it is the eighth, so the Project Structure and Architecture
  sections shrink to a pointer plus a diagram rather than a full account.
- **`docs/tickets/DN-017-technical-tidy-root-docs.md`** — established that `CLAUDE.md` and
  `README.md` must stay at the repository root (Claude Code and GitHub both discover them by
  location) while everything long lives in `docs/`. This ticket adds files under that rule, not
  against it.
- **`ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md`** §3 — owns the folder-structure account. The iOS
  README points at it and must not copy the tree.
- **`docs/GETTING-STARTED.md`** (196 lines) — being folded into the umbrella README. Read it whole
  before moving anything; it is the only onboarding path that exists.

Already true, and constraining:

- **The iOS folder structure is in flux.** The owner reorganised it on
  `ticket/DN-015-apply-architecture-to-screens` (an `App/` group, `Presentation/` per feature) and
  DN-015 has an unresolved amendment covering route ownership, component-folder naming and
  navigation. **The iOS README's structure section must not be written from the current tree** — it
  would document a layout that is mid-change. Point at §3 and let DN-015 settle the tree first.
- **The app has no backend, no payment gateway and two working screens.** A `## Features` section
  written from the MovieDB template will overstate what exists. Describe what runs today; mark
  anything else as planned.

## Technical approach

Three repos, three separate commits — no commit spans projects.

### 1. `DNLibrary` — rename the codebase document

- `git mv docs/CODEBASE-STANDARD.md docs/CODEBASE-ARCHITECTURE.md`
- Update the **six live references** — path links and prose alike:
  - `DNLibrary/CLAUDE.md:5` (link), `:139` (prose "CODEBASE-STANDARD §6")
  - `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md:10` (link), `:232` (prose)
  - `docs/AGENT-PLAYBOOK.md:130`
  - `docs/ARCHITECTURE-AND-WORKFLOW.md:458` (prose)
- Add one line under the new file's title recording the former name, so a search for the old term
  still lands somewhere.
- Expand `DNLibrary/README.md` from 27 lines to the MovieDB shape.

### 2. `ios/DapurNaura` — new `README.md`

New file at the repo root. Sections, following the model:

| Section | Content here |
|---|---|
| Summary | Cooking app for Dapur Naura; classes → recipes → method and video. Content is Bahasa Indonesia. |
| Features | **What runs today only** — class list, class detail with status-driven buy button. Payment gateway and recipe detail marked planned. |
| Tech Stack | Swift, SwiftUI, `@Observable` MVVM, Swift Concurrency, DNLibrary via SPM, `.xcconfig` variants, SwiftLint. |
| Architecture | The `View → ViewModel → DNLibrary use case` flow as a diagram. Three lines of prose, then a link to `docs/CODEBASE-ARCHITECTURE.md`. |
| Project Structure | **A pointer to §3, not a tree.** See the constraint in Context. |
| Requirements | iOS 17.0+ (DN-013), Xcode, and the local-package rule — link to `CLAUDE.md`, do not restate it. |

### 3. umbrella — new `README.md`, absorbing `GETTING-STARTED.md`

- New `README.md` at the umbrella root: what the workspace is, the not-a-monorepo rule, the four
  repos and what each is for, then the folded onboarding content (`bootstrap.sh`, prerequisites,
  first build).
- `git rm docs/GETTING-STARTED.md`, with its content moved rather than rewritten.
- Update the three inbound references: `CLAUDE.md`, `docs/ARCHITECTURE-AND-WORKFLOW.md`, and
  `docs/tickets/DN-010-technical-bilingual-prompt-protocol.md`.
- **No codebase document for the umbrella** — owner's decision; it tracks `docs/` and config only.
- `docs/ARCHITECTURE-AND-WORKFLOW.md` and `docs/AGENT-PLAYBOOK.md` stay exactly as they are.

The umbrella README will exceed the model's 68 lines because it absorbs 196. That is expected —
onboarding is what a front page is for, and the alternative is two files a newcomer must find in the
right order.

## Public API contract

None. Markdown only; no Swift, no Kotlin, no version bump.

## Out of scope

- **Any code change.** This ticket touches `.md` files only.
- **The DN-015 amendment** — folder conventions, route ownership, navigation. Unresolved and tracked
  there. This ticket depends on its outcome for one paragraph and works around it by pointing at §3.
- **`android/`.** No repo exists. When it is created it inherits the same three-file set; that is
  recorded here and needs no ticket of its own until there is something to document.
- **Rewriting `AGENT-PLAYBOOK.md` or `ARCHITECTURE-AND-WORKFLOW.md`.** Their links get updated; their
  content does not move.
- **`docs/contracts/README.md`.** A different kind of file — it documents the contract fixtures, not
  a repository — and stays as it is.

## Open questions

| # | Question | Options | Agent recommendation |
|---|---|---|---|
| 1 | **The ~25 historical references to `CODEBASE-STANDARD` in `DN-001` … `DN-017`.** A rename makes them name a document that no longer exists. | (a) leave them; (b) rewrite them all | **(a) leave them.** DN-017 set the precedent that prose references naming a section are left alone, and tickets are a record of what was true when written — rewriting closed work to match a later decision makes the record lie. The former-name line added in step 1 is what makes them still resolvable. **Owner to confirm.** |

### Decisions taken by the owner, 2026-08-06

> "Each repository have their own README.md and CLAUDE.md and CODEBASE/ARCHITECTURE. Only Umbrella
> has WORKFLOW that will explains the WORKFLOW of Umbrella into iOS and Android."
>
> — owner, 2026-08-06

| Question | Decision |
|---|---|
| Codebase document name | **`CODEBASE-ARCHITECTURE.md` in every repo.** `DNLibrary`'s is renamed. |
| Umbrella codebase document | **None.** The umbrella has no code — `README` + `CLAUDE.md` + workflow only. |
| `GETTING-STARTED.md` | **Folded into the umbrella `README.md`.** `AGENT-PLAYBOOK.md` stays separate. |
| README model | **`MovieDB/README.md`**, adapted — orientation only, links rather than restates. |

## Test plan

No automated gate; a `docs` ticket is verified by reading. What to check:

1. **Nothing is stated twice.** Every rule in a README exists in exactly one place, and the README
   links to it. A README paragraph that could be deleted without losing information should be.
2. **No dead links**, in either direction — the renamed file, the deleted `GETTING-STARTED.md`, and
   every inbound reference to both.
3. **The iOS `## Features` section matches what actually runs.** Two screens, stub data, no backend,
   no payments.
4. **No structure tree in the iOS README** — §3 owns it, and it is mid-change on DN-015.
5. **`grep -r "CODEBASE-STANDARD"` outside `docs/tickets/` returns nothing.**
6. **A newcomer can get from the umbrella README to a running app** without opening
   `GETTING-STARTED.md`, which no longer exists.

## Done when

Docs work (the workflow standard itself):

- [ ] Every document stating the rule updated — they must agree with each other
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged — three commits, one per repo, all tagged `DN-018:`

Always:

- [ ] PR merged, ticket marked `done` by the human

## Notes

Filed by the agent at `status: todo` on 2026-08-06, after the owner supplied `MovieDB/README.md` as
the model and stated the per-repository document set. **Filing is autonomous; scheduling is not** —
the owner starts it.

Ordering against the open iOS work: **DN-015 should land first.** Its amendment decides the folder
conventions the iOS README would otherwise describe, and this ticket deliberately avoids depending on
that by pointing at §3 rather than copying the tree. Running them the other way round is possible but
means writing the one paragraph twice.
