---
id: DN-041
type: technical
title: The workspace documents say there is no login screen, and that the recipe screen is a placeholder
status: in-review
source: —
branch: ticket/DN-041-docs-login-drift
commit: 7fd6da5, 3ffb06a
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/21
layer: docs
---

## Rationale

**DN-040 made a sentence in three documents literally false, and it is the most dangerous kind of
false: it is inside the paragraph a new session reads to learn what the app does not have.**

> "nothing anywhere carries identity: **no login**, no session, no user model"

There is a login screen now. It is the first thing the app shows. It authenticates nobody — no
credential is checked, no session exists, and the 2026-08-06 deferral is untouched — but a reader
who meets that sentence and then opens `Presentation/Login/` has been told something the code
contradicts, and has no way to know which half is stale.

**The risk is specific, not cosmetic.** The next agent to need a signed-in user finds
`hasPassedLogin` at the composition root and a screen that takes a password. If the documents say
*no login*, the natural inference is that the documents are behind and the login works. That is
exactly backwards, and it is how `purchaseStatus` ends up wired to a boolean that means *"has been
past a screen"*.

**A second drift is older and larger.** `README.md` still says:

> "Two screens run — the class list and the class detail […] The recipe screen, which is the point
> of the product, is still a placeholder."

Six screens run, and the recipe screen stopped being a placeholder at DN-021 — four merged product
tickets ago. `ios/DapurNaura/CLAUDE.md` says **"Three screens exist"** and lists three of the six.

This is DN-029's finding recurring exactly as it predicted: **the rules held wherever they were
encoded and drifted wherever they were prose.** Nothing forces a screen count to be updated, so
nobody updates it. The correction here is therefore not only to fix the numbers but to **stop
counting** — the ticket index is derived and correct, and a prose screen count is a fact with no
owner.

Filed on the owner's instruction, 2026-08-11: *"please synchronize umbrella projects and their
repository with tickets or requirements."*

## Context

Read before starting:

- `README.md` — *Where the project actually is*
- `CLAUDE.md` — *The shape of what is built*, and *Current known blockers*
- `docs/ARCHITECTURE-AND-WORKFLOW.md` — the three-things-the-domain-assumes list, and the open-gaps
  list near the end
- `ios/DapurNaura/CLAUDE.md` — *What this app is*
- `docs/tickets/DN-040-product-login-screen.md` — the wording that must not be contradicted:
  `hasPassedLogin` is not a session, and nothing here is the beginning of one

**The deferral itself has not changed and must not be written as if it has.** No backend, no session,
no user model, no token storage, no purchase path. The only new fact is that a screen exists in front
of all of it.

## Technical approach

**Documents only. No code, in either repository.**

| Document | What changes |
|---|---|
| `README.md` | The screen inventory stops being a count. The recipe placeholder claim goes — it has been wrong since DN-021 |
| `CLAUDE.md` | *Three things the domain assumes* keeps all three; the signed-in-user entry gains the clause that a login screen exists and authenticates nobody. The blocker's *"no login"* becomes *"a login screen that checks nothing"* |
| `docs/ARCHITECTURE-AND-WORKFLOW.md` | Same correction, in both places it states the gap |
| `ios/DapurNaura/CLAUDE.md` | *"Three screens exist"* → the current set, without a number. Gains the light-mode and portrait lock from DN-039, which changes how any new screen is built |
| `ios/DapurNaura/README.md` | Its feature list covered two screens and still called the recipe screen a placeholder. Also carried a build command with a bare simulator name, which known issue 2 and DN-034 both forbid |
| `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` | §5 records that the composition root also chooses which screen is the root, and that `hasPassedLogin` is not a session. §3's layout shows `DesignConstants` can span files |

**Every other tracked `.md` was checked and is correct.** `docs/AGENT-PLAYBOOK.md`'s screen count is
inside an explicitly labelled historical snapshot that points readers at the ticket index;
`docs/contracts/README.md` describes wire shapes; `CLAUDE.md`'s *"two screens already render state
that cannot yet exist"* counts the screens showing `purchaseStatus`, not the app's screens; and all
three `DNLibrary` documents plus `ios/SPMDNLibrary/README.md` say nothing about iOS screens or
identity. **Leaving a correct sentence alone is part of the job** — rewriting the playbook's snapshot
would have destroyed the evidence it exists to preserve.

**Two rules for the wording, both learned from DN-029:**

- **Never restate ticket status in prose.** The screen list names the tickets that created each
  screen so the reader can follow the id; it does not say how many there are, because that number
  goes stale on the next merge and nothing forces anyone to notice.
- **State the deferral more loudly, not less.** The temptation is to soften *"no signed-in user"*
  now that a login screen exists. The opposite is correct: the gap is now easier to miss, so it
  needs to be harder to misread.

**DN-039's lock belongs in the iOS document specifically**, not the umbrella. It is a fact you need
before writing a view — the app is light-mode only and portrait only, so a screen built with
adaptive colours is fine but one designed for dark mode is wasted work.

## Public API contract

None. Documentation only.

**Version bump implied:** none.

## Out of scope

- **Any code change.** If this ticket touches a `.swift` file or a build setting, it has gone wrong.
- **Editing requirement documents.** `2026-08-10-login.md` is approved and frozen; it is not wrong,
  and nothing here corrects it.
- **Editing DN-039 or DN-040.** Both are `done` and record what was true when they were written.
- **Resolving the signed-in-user gap**, or designing around it. Still the owner's deferral of
  2026-08-06.
- **A wider audit of every document.** This corrects what DN-040 falsified plus the two screen
  counts found beside it. DN-029 already did the sweep; this is not a second one.

## Test plan

Not code. What the owner is asked to check in the diff:

- No document claims there is no login screen
- No document claims the recipe screen is a placeholder
- **No document states a screen count**
- Every document still states plainly that there is no session, no user model, no token storage and
  no purchase path — and none of them reads as though login weakened that
- Nothing under `docs/requirements/` is touched
- No `.swift` file, xcconfig or project file appears in either diff

## Done when

- [x] `README.md`, `CLAUDE.md` and `docs/ARCHITECTURE-AND-WORKFLOW.md` corrected
- [x] `ios/DapurNaura/CLAUDE.md` corrected, including DN-039's lock
- [x] `ios/DapurNaura/README.md` and `docs/CODEBASE-ARCHITECTURE.md` corrected — the miss the owner
      caught, recorded under *Notes*
- [x] **All eleven tracked `.md` files enumerated and read**, not grepped
- [x] The four documents agree with each other and with DN-040
- [x] Ticket index regenerated
- [ ] Diff reviewed by the owner
- [x] Committed, not merged — iOS `7fd6da5` and `3ffb06a`; the umbrella half is in this branch
- [x] iOS PR opened — [DapurNaura-iOS#21](https://github.com/Fostahh/DapurNaura-iOS/pull/21); the umbrella takes none by policy
- [ ] PR merged, ticket marked `done` by the owner

## Notes

**The umbrella half needs no PR and the iOS half does**, because the iOS documents live in a separate
repository. One ticket, three commits, one pull request.

**The first pass swept four documents and stopped, and the owner caught it.** `ios/DapurNaura/README.md`
was left saying the recipe screen was a placeholder and listing two features, and its build command
still named a bare simulator — a contradiction with this repo's own known issue 2 that had survived
since DN-034. The agent had grepped for the phrases it already knew were wrong rather than
enumerating every tracked `.md` and reading it.

**That is the failure worth keeping:** a search finds what you thought of, an inventory finds what you
did not. The second pass listed all eleven tracked documents first, then checked each — which is what
turned up the README and the two architecture sections. **Enumerate, then check. Do not grep and
call it a sweep.**

**This is the second time a document has been wrong in the direction of understating what exists.**
DN-029 found the same shape: `CLAUDE.md` claimed DN-024/DN-025 were uncommitted for a day after they
had shipped. Both times the derived index was correct and the prose was not.
