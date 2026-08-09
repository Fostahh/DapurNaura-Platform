---
id: DN-034
type: technical
title: Every iOS change must build before it is offered for review
status: in-progress
source: —
branch: ticket/DN-033-cooking-class-selection-entry
layer: docs
---

## Rationale

**The agent's only automated gate on iOS work is SwiftLint, and SwiftLint does not compile
anything.** It checks shape — font calls, `NavigationLink` form, file length. Code that does not
build passes it cleanly.

`ARCHITECTURE-AND-WORKFLOW.md` §6 says UI work is *"verified manually by the human. No automated
gate — tests are data-layer only."* That sentence is about **tests**, but it reads as *there is
nothing the agent can check*, which is false. `xcodebuild … build` needs no simulator run, no test
target and no human, and it is the difference between "the linter is happy" and "this compiles".

**Owner's instruction, 2026-08-09**, recorded as the agent's English translation per DN-010:

> "I want an additional rule: whenever there is a codebase change in the iOS project, please just
> build it — no need to run it in the simulator — and make sure the build succeeds."

DN-033 is the worked example. It went through four rounds of owner feedback on previews while the
only evidence the agent could offer each time was *"SwiftLint reports 0 violations"* — a statement
that would have been equally true of code that did not compile. The first build ran only after this
rule was given.

**This does not replace the human's verification of the running app**, and must not be written up as
if it does. It is a floor underneath it: the agent proves the code compiles, the owner proves it
behaves. §6's UI entry gains a gate; it does not lose one.

## Context

Read before starting:

- `docs/ARCHITECTURE-AND-WORKFLOW.md` §6 — the Definition of Done, per layer
- `CLAUDE.md` — *Workflow* step 3 (the UI-only branch) and *Build & test*
- `ios/DapurNaura/CLAUDE.md` — *Build & test*, and known issue 2, which is why the destination
  cannot be written casually
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` — *Before submitting a change*

**The destination is the part that goes wrong.** `DNLibrary.xcframework` carries no x86_64 slice,
and several iOS 18.3.1 simulator runtimes publish the same device name for both architectures — so
`-destination 'generic/platform=iOS Simulator'` fails on the x86_64 pass and
`name=iPhone 16 Pro` is ambiguous and makes `xcodebuild` print the device list instead of building.
Both traps are already documented as known issue 2. **The rule has to carry a destination that
works**, or it will be followed and still fail.

## Technical approach

**No code. Four documents, which must agree with each other.**

The rule, stated once and referenced from the rest:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=<simulator-uuid>' build
```

- **Any change to Swift, the project file or an xcconfig** — build it. Not only at the end of a
  ticket: before offering the change to the owner at all.
- **Build, do not run.** No simulator boot, no install, no launch. The owner scoped it that way, and
  it is what makes the rule cheap enough to hold every time.
- **`** BUILD SUCCEEDED **` or it is not finished.** A failing build is not reported as a caveat
  alongside the diff; it is fixed first.
- **Get the simulator id from `xcrun simctl list devices available`.** Never a bare device name,
  never the generic destination — known issue 2.

| Document | What changes |
|---|---|
| `docs/ARCHITECTURE-AND-WORKFLOW.md` §6 | The UI Definition of Done gains the build gate, and the misreadable *"no automated gate"* is corrected to say what it actually means — no automated **test** gate |
| `CLAUDE.md` | *Workflow* step 3's UI-only branch says *"no tests, no publish, no version bump"*; it must not also imply no build. *Build & test* gains the command |
| `ios/DapurNaura/CLAUDE.md` | *Build & test* states the rule at the point of use, next to the destination trap it depends on |
| `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` | *Before submitting a change* gains a checklist line, beside the SwiftLint one |

**Why all four rather than one.** DN-029's finding was that **the rules held wherever they were
encoded and drifted wherever they were prose**. This rule cannot be encoded — there is no CI, and
the owner has ruled CI out as *"very far off"* — so the only available substitute is stating it at
every point where someone is about to skip it. The checklist line is the one an agent actually meets
at the moment it matters.

## Public API contract

None. Documentation only.

**Version bump implied:** none.

## Out of scope

- **CI.** A ticket proposing it was filed and deleted on the owner's instruction — *"that process is
  very far off for me to implement"* — and the ticket index says it is not to be re-proposed. This
  rule is what stands in for it, and it is honest about being attested by the agent rather than
  enforced.
- **Running the app, installing it, or taking screenshots.** Explicitly excluded by the owner.
- **Swift tests, or a UI test target.** Unchanged: tests are data-layer only.
- **A build gate on `DNLibrary`.** It already has one — `./gradlew :sharedLogic:check`.
- **A git hook or script.** Same reasoning as CI, at a smaller scale; nobody asked, and a hook that
  runs `xcodebuild` on every commit in a repo Xcode rewrites constantly would be resented within a
  day.

## Test plan

Not code, so nothing to test. What replaces it — the owner reading the diff, checking:

- The four documents state the same rule and do not contradict each other
- §6 no longer reads as though the agent has nothing it can check
- The destination in every copy of the command is id-based, and the reason is one click away
- Nothing implies the build replaces the owner's verification of the running app

Demonstrated on DN-033, which is the change that prompted it: `** BUILD SUCCEEDED **` on
`DapurNaura Dev`, simulator `AD0B3801-84D9-48AE-80E7-54633283317D` (iPhone 17 Pro), 2026-08-09.

## Done when

- [ ] All four documents updated and in agreement
- [ ] §6's UI entry distinguishes *no automated test gate* from *no automated gate*
- [ ] Every copy of the command uses an id-based destination
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged
- [ ] PR merged, ticket marked `done` by the human

## Notes

**Filed and started in the same step**, because the owner's instruction scheduled it — the same
shape as DN-010. Filing is autonomous; starting is not, and here the owner did the scheduling in the
sentence that asked for it.

**It shares DN-033's branch in both repos.** The rule arrived mid-ticket, its first application
*is* DN-033, and the alternative was stashing an unfinished feature to make a docs branch. The
commits are separate and each carries its own id, which is what the reviewer follows — the same
reasoning that let DN-024 and DN-025 share one umbrella branch.
