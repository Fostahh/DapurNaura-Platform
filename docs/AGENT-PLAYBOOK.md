# Agent Playbook — how to work here, step by step

**Status:** extracted 2026-08-06 from a full working session (DN-001…DN-009) run end to end by a
frontier-class agent (Claude Fable). The umbrella [`CLAUDE.md`](../CLAUDE.md) defines *what is
allowed*; this document defines *how to execute well*. It is written to be followed **literally**,
so that any agent — regardless of capability — produces the same quality. When this document and
`CLAUDE.md` conflict, `CLAUDE.md` wins.

The single principle behind every rule here: **never trust a claim you have not verified — not the
docs', not the tools', not your own.** Everything else is that principle applied to a specific
moment in the workflow — including §1, which applies it to your own reading of what you were asked
for.

---

## 0. Session start — establish ground truth

An agent starts every session cold. Before any work:

1. Read the umbrella `CLAUDE.md`, then the `CLAUDE.md` of every project you will touch.
2. Run `git status -sb` and `git log --oneline -5` in **every** repo you will touch. Note the
   current branch of each — do not assume it.
3. **Believe files over documents.** Docs drift; code and git history do not. If a doc says
   "explicitApi() is enabled" or "the task is `testDebugUnitTest`", verify before relying on it.
   This workspace has already caught both of those claims being false.
4. When a doc contradicts reality, **fixing the doc is part of the job** — in the commit where the
   fact changes, or a `docs:` commit if it was already stale.

## 1. Every request is confirmed, then becomes a ticket, then becomes code

**Confirm before you act — DN-010.** Restate what you understood the request to be, name your
assumptions or state plainly that there are none, and **wait**. Every request, either language.
Anything ambiguous is asked about, not chosen. Confirmation is per-request, exactly like commit
authority is per-batch: confirming one does not pre-authorise the next.

Two things this gate is not. It is not a replacement for the later gates — the human still verifies
the running app and still triggers every commit. And it does not apply to problems *you* noticed:
filing a technical ticket at `status: todo` stays autonomous, because there is no instruction there
to misread. The gate exists because every other gate in this workflow sits *after* work exists, so
without it a misread request is only caught once it has already been built — and by then it is also
the permanent record of why the code exists.

"No assumptions" is a claim. Only make it when it is true.

Then:

- No code without a ticket in `docs/tickets/`. Filing is autonomous; **starting** a ticket you
  filed yourself needs the human's go — see the autonomy table in `CLAUDE.md`.
- Type by **where the justification comes from**: requirement document → `product`; a problem you
  observed → `technical` with a `## Rationale` a stranger can evaluate in six months.
- **A verbal instruction from the human is a requirement.** Quote it *verbatim* in
  `## Requirement (traced)`, date it, and flag the missing requirement document as a recorded
  deviation. Never paraphrase it into what you think they meant without marking your additions.
- **The repository is English; the owner is not always.** When the instruction was Bahasa
  Indonesia, what goes in the ticket is **your English translation** — attributed as translated and
  dated. This is the one narrowing of *verbatim* above, decided by the owner in DN-010, and it
  raises the bar rather than lowering it: the translation must be transcription, never
  interpretation. Any wording whose meaning your translation could plausibly change goes to
  `## Open questions` instead of being quietly resolved. **Never translate app content** — `kelas`,
  `bahan-bahan`, `loyang`, recipe names, every user-facing string stays Indonesian. The rule covers
  what the owner says to you, not what the app says to its users.
- Anything the human did not say but you need to assume: mark `[ASSUMPTION]` inline. Anything
  genuinely undecided: `## Open questions`, or ask — never silently guess.
- The ticket's `## Out of scope` is written **before** implementing, and it is binding. Scope you
  discover mid-work becomes a *new* ticket, not a bigger diff.

## 2. Before writing code

1. Read every file the ticket's `## Context` names. All of them.
2. Check for **overlap**: if two tickets touch the same files, they must not be implemented
   independently. Stack the branches (later ticket branched from the earlier ticket's branch) and
   **record the merge order in `docs/tickets/README.md`** the moment you decide it.
3. Flip the ticket to `in-progress` when you start — not after.

## 3. While writing code

- Smallest change that satisfies the ticket. Match the surrounding code's style, comment density
  and idiom — comments state constraints the code cannot show, never narrate the diff.
- **For any "X is broken" ticket: write the test first and run it against the broken code.**
  Record that it failed and how. A fix whose test never failed proves nothing. (DN-001 did this:
  the encryption check read raw file bytes and failed against the plaintext implementation before
  the fix existed.)
- When the platform blocks a planned test (no keychain in the hostless simulator process, no
  Keystore under Robolectric), do not delete the case and do not fake it: keep it `@Ignore`d with
  the reason written at the ignore site, inject a seam so the rest stays testable, and record the
  deviation in the ticket.

## 4. Verification — tests are your only eyes

- You cannot run the app and look at it. Tests are your entire feedback loop; UI is verified by
  the human, on the running app, **before** anything is committed.
- Run the real gate (`./gradlew :sharedLogic:check` for the data layer), not a convenient subset.
- **Distrust convenient results.** A green build seconds after a large change means *verify, not
  celebrate*: read the test-result XML (`tests= / skipped= / failures=` per class), check file
  timestamps, force a rerun if in doubt. A gate that silently ran nothing looks identical to a
  gate that passed.
- Report failures **verbatim** — paste the real error, never a summary of an error you did not
  read. If a result surprises you (too fast, too clean), say so and investigate before moving on.

## 5. Committing — only when the human has authorized it

Committing, pushing, PRs, merges, releases and `done` are always the human's to trigger.
Authorization is per-batch: "commit these tickets" does not cover the next ticket.

When authorized:

1. One ticket = one branch (`ticket/DN-XXX-slug`) = one commit. Message starts `DN-XXX: ` —
   it is the **only** cross-repo link to the ticket — followed by a body that explains *why*,
   not a list of files.
2. **Stage explicitly, file by file.** Never `git add -A` or `git add -u` blindly: `-A` sweeps in
   what must never be committed, and `-u` silently *misses new files* — this session lost a test
   file from a commit exactly that way and had to repair history.
3. In `ios/DapurNaura`, before every commit:
   `git show :DapurNaura.xcodeproj/project.pbxproj | grep -n "DNLibraryLocal\|XCLocalSwiftPackageReference"`
   must return **nothing**. The local package wiring is never committed, in any state.
4. Immediately after committing: write the SHA into the ticket, tick the done-when boxes that are
   now true (never ones that are not), flip status to `in-review`, and add
   `## Implementation notes` recording every deviation, discovery, and decision the human may
   want to veto.

## 6. The doc sweep — after every change

Documentation is a set of caches over the code; every change invalidates some of them. After each
ticket, check and fix, in the same commit where possible:

| Mirror | Lives in |
|---|---|
| Ticket status + notes | the ticket file (the **only** source of truth for status) |
| The ticket index | `docs/tickets/README.md` — regenerate it, it does not regenerate itself |
| Known-violations table | `DNLibrary/CODEBASE-ARCHITECTURE.md` |
| "What exists" descriptions | each repo's `CLAUDE.md` |
| Blockers / §8 constraints / §9 drift | `docs/ARCHITECTURE-AND-WORKFLOW.md`, umbrella `CLAUDE.md` |

A resolved item is **struck through with the resolving ticket named**, never silently deleted —
the trail is the point.

## 7. Stop conditions — non-negotiable

- A request you have not yet confirmed → restate it, **stop**, wait for the human's confirmation
  (§1). This is the earliest stop condition and the cheapest one to honour.
- Requirement ambiguous, impossible, or contradicting code → append `## Blocked` to the ticket
  with the options you see, **stop**, tell the human. Never improvise around a blocker.
- UI work → build it, run it, then **stop for the human's verification before any commit**.
- Anything in `CLAUDE.md`'s "Stop and wait" or "Never" lists → exactly that.
- A destructive or irreversible act you were not explicitly asked for → ask first.

## 8. Honesty rules

- **Own your mistakes visibly.** If you commit wrongly, staged the wrong thing, or claimed
  something false — say it plainly, repair it (history surgery is fine on unpushed local
  branches; never force-push), and record the repair in the ticket. This session did exactly that
  for a mis-staged test file, and the repair is part of the record.
- Never edit an approved requirement, and never edit a contract silently — contract changes are
  deliberate, noted revisions.
- Never mark your own ticket `done`, and never tick a box describing work that did not happen.
- If the same human feedback arrives twice, write it into the ticket or the relevant `CLAUDE.md`
  before the session ends — verbal feedback does not survive the session boundary.

---

## Worked example — the 2026-08-06 session this playbook is extracted from

One day, nine tickets, requirement → running app. The sequence, so you can see every rule above
in a real trace:

1. **Ground truth first.** A review of the workspace found the docs drifted from reality (stale
   ticket index, a contract marked "not yet written" that was approved, a task name that did not
   exist, `explicitApi()` claimed but off). The drift was fixed and two missing tickets (DN-006,
   DN-007) were filed **before any code was written**.
2. **Scheduling is the human's.** All `todo` tickets sat unstarted until the owner said "work on
   them, ascending". Overlapping DNLibrary tickets became **stacked branches**
   (DN-001 → DN-002 → DN-004 → DN-006 → DN-008 → DN-009), merge order recorded in the index.
3. **Failure proven first.** DN-001's encryption check ran against the plaintext implementation
   and failed; then the fix was written; then it passed. Platform limits (no Keystore off-device,
   no keychain in the hostless test process) became injectable seams plus `@Ignore`d cases with
   reasons — recorded in the ticket, not hidden.
4. **Mid-session verbal requirements became product tickets** (DN-008 `GET /classes`, DN-009 the
   SwiftUI screen), each quoting the owner verbatim and flagging the deferred requirement doc.
5. **The UI gate held.** The screen was built against `DNDataLayer.stub()` (contract replay),
   wired via the never-committed local package; the owner verified the running app on the
   simulator **before** the commit, and the staged index was grepped clean of local wiring.
6. **Every commit updated its ticket** (SHA, notes, deviations) and swept the doc mirrors, so the
   next cold-started session — or a smaller model — inherits reality, not archaeology.

End state **of that session**: 9 tickets `in-review`; 21 data-layer tests green on the Android host
and 16 on the iOS simulator (plus 4 keychain cases parked `@Ignore` with their reason); one screen
verified on the simulator; zero uncommitted surprises. That is the standard this document exists to
keep.

> **Those numbers are a snapshot, not the current state.** The workspace has run further since —
> through DN-018, with 89 data-layer tests and two screens. This trace is kept as the evidence the
> playbook is drawn from; for what is true now, read
> [`tickets/README.md`](tickets/README.md) and each repository's `CLAUDE.md`.
