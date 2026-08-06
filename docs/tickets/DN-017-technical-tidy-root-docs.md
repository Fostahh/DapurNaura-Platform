---
id: DN-017
type: technical
title: Move the standards documents out of the repository roots into docs/
status: in-review
source: —
branch: ticket/DN-017-tidy-root-docs
layer: docs
---

## In plain language

Each project folder had several documents sitting loose at its top level. This moves the long ones
into a `docs/` folder so the top level stays short and it is obvious where to look.

Two files deliberately stay where they are, because tools depend on their location — moving them
would quietly break things rather than tidy them.

## Rationale

Owner's instruction, 2026-08-06: the markdown at the repository roots does not feel tidy.

Before:

| Repo | Root markdown |
|---|---|
| `DNLibrary` | `CLAUDE.md`, `CODEBASE-STANDARD.md`, `README.md` |
| `ios/DapurNaura` | `CLAUDE.md`, `CODEBASE-ARCHITECTURE.md` |

The umbrella already got this right — `CLAUDE.md` at root, everything else under `docs/`. The two
project repos had drifted from that, and DN-014 was about to add a third root-level document.

**Two files must not move**, and the reason is mechanical rather than conventional:

- **`CLAUDE.md` — Claude Code discovers it at the repository root.** Moving it means no agent loads
  the project's instructions again.
- **`README.md` — GitHub renders it as the repository landing page** only from the root.

That leaves the standards documents, which nothing discovers automatically and which are the longest
files in both roots.

## Technical approach

- `DNLibrary/CODEBASE-STANDARD.md` → `DNLibrary/docs/CODEBASE-STANDARD.md`
- `ios/DapurNaura/CODEBASE-ARCHITECTURE.md` → `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md`

Moved with `git mv` so history follows the file rather than reading as delete-plus-add.

Every inbound link updated. Prose references of the form *"CODEBASE-STANDARD §6"* are left alone —
they name a section, not a path, and rewriting them would add noise for no navigational gain.

## Out of scope

- **`DNLibrary/README.md` is stock KMP template boilerplate** and describes an `/iosApp` directory
  that does not exist — its own `CLAUDE.md` carries a warning saying so. That is a worse problem than
  file placement, but replacing it means writing a real README, which is a content decision for the
  owner rather than a tidy. **Raised, not fixed.**
- **`ios/DapurNaura` has no `README.md` at all.** Same reasoning.
- `.swiftlint.yml` stays at the root — SwiftLint's default discovery path.
- Nothing in the umbrella repo changes.

## Test plan

No automated gate. What to check:

1. **Every relative link resolves.** Verified on delivery by resolving each `](../…)` target against
   the filesystem — 2 unique paths, both resolve.
2. **`git log --follow` still traces the moved files**, i.e. they were moved rather than
   re-created.
3. **Nothing outside the two repos points at the old paths.**

## Done when

Docs work:

- [x] Every document stating the rule updated — they must agree with each other
- [x] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Implementation notes (2026-08-06)

Delivered alongside DN-014, in the same session the owner asked for it.

**`ios/DapurNaura`** — the move happened before the file was ever committed, so it lands on
`ticket/DN-014-ios-codebase-architecture` as part of that ticket rather than as a separate move. The
document was written to the root, then relocated; there is no rename in the history because there was
nothing to rename yet.

**`DNLibrary`** — `CODEBASE-STANDARD.md` was already committed, on a seven-deep in-review stack, so
the move needed its own branch: `ticket/DN-017-tidy-root-docs`, cut from
`ticket/DN-011-cooking-class-detail`, the current tip. `git mv` recorded it as `R` (rename), so
history follows.

> **This adds an eighth PR to the DNLibrary queue**, merging after DN-011. Worth knowing before the
> stack is worked through: the merge order becomes
> `DN-001 → DN-002 → DN-004 → DN-006 → DN-008 → DN-009 → DN-011 → DN-017`.

**Links updated:** `DNLibrary/CLAUDE.md`'s pointer to the standard, and the two outbound links in
`CODEBASE-ARCHITECTURE.md` — one to `../CLAUDE.md`, one to the standard's new home three levels up.
Both were resolved against the filesystem after editing rather than assumed.

**Verified:** `swiftlint lint` still resolves its config after the reshuffle — 5 violations, 1 error,
all of them pre-existing rows in DN-014's known-violations table.
