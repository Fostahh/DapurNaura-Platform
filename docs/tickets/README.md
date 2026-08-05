# Tickets

One file per ticket: `DN-XXX-short-slug.md`. This index is regenerated as tickets change — it is
derived, so if it drifts from the files, the files win.

## Open

_None yet._

## Done

_None yet._

---

## Template

```markdown
---
id: DN-001
title: Short imperative title
status: todo          # todo | in-progress | in-review | done
source: docs/requirements/YYYY-MM-name.md
branch: ticket/DN-001-short-slug
---

## Requirement (traced)

> Quoted lines from the source document that this ticket satisfies.

## Technical approach

What changes, where, and why. Name the files.

## Public API contract

What Swift and Kotlin callers see after this lands. This is the part that matters most —
DNLibrary ships as a binary, so its public surface is a contract, not an implementation detail.
Call out anything source-breaking for existing consumers.

## Test plan

Specific cases, not "add tests". Which Gradle task proves it.

## Done when

- [ ] Code implemented
- [ ] Unit tests written and passing (`./gradlew :sharedLogic:check` from `DNLibrary/`)
- [ ] Committed on `ticket/DN-001-short-slug`, not merged
```
