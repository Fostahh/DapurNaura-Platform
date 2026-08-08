---
id: DN-014
type: technical
title: Decide and document the iOS codebase architecture — CODEBASE-ARCHITECTURE.md
status: done
source: —
branch: ticket/DN-014-ios-codebase-architecture
layer: docs
---

## In plain language

*A short version for anyone who does not work on the code. The rest of this ticket is the detailed
version of the same thing.*

**The problem.** The project is built in two halves. The half that fetches data already has a
written rulebook — it says how things must be named, how mistakes must be handled, what has to be
tested. The half that draws the screens on the iPhone has no rulebook at all. Nothing is written
down about how a screen should be put together.

**Why that matters.** When the rules only live in someone's head, each new screen ends up built a
little differently from the last one. That has already caused real problems: two faults were found
in the screens built so far, and both came from the same cause — nothing says who is responsible
for moving between screens, so it was done two different ways in two places, and they conflict.

**Why now rather than later.** There are two screens today, and the next one has already been agreed
with the owner. Writing the rulebook now means writing one document. Writing it after five or six
screens exist means rebuilding all of them to match.

**What this ticket produces.** One document, kept next to the iPhone app's code, covering ten
topics: how a screen is structured, how moving between screens works, where the app is allowed to
do its own thinking versus asking the data half, how errors are shown to the user, and which
language is used where. It also adds an automatic checking tool called SwiftLint, which reads the
code and flags anything written in the wrong style before a human has to.

**What it does not change.** Nothing the user sees. No new features, no visual change, no change to
how the app behaves. This is entirely about making future work faster and less error-prone.

**What was needed from the owner.** Seven decisions, all now taken on 2026-08-06 and recorded under
*Open questions*. The largest was how moving between screens should work from now on. The strictest
was the last: when the app needs to work something out — a price, who may open what — it must ask the
tested half rather than decide for itself, and that now covers formatting too, so the Android app
planned later inherits the same answers instead of reinventing them.

**What is needed now.** Read the document and say whether it matches how you want the app built.
There is no test that can check this one — a person reading it is the only verification there is.

---

## Rationale

`DNLibrary/CODEBASE-STANDARD.md` states, in 10 numbered sections, what may and may not be written in
the data layer — layering, public API rules, error handling, naming, testing. `ios/DapurNaura` has
no equivalent. Its `CLAUDE.md` documents build variants, secrets, the local package rule and known
issues, but says nothing about how the app itself is put together: what a ViewModel may do, where
navigation is decided, what belongs in Swift versus behind the KMP boundary.

**The two repos are not equally protected, and the unprotected one is the one without a standard.**

| | DNLibrary | ios/DapurNaura |
|---|---|---|
| Compiler-enforced API rules | `explicitApi()` | — |
| Automated gate | `./gradlew :sharedLogic:check` | — |
| Tests required | yes, every public use case | **no** — platform DoD excludes UI |
| Linter | — | **SwiftLint, added by this ticket** |
| Written standard | `CODEBASE-STANDARD.md` | **nothing** |

Every mechanical control this workspace has points at Kotlin. This ticket closes part of that gap by
adding SwiftLint, but a linter enforces formatting and idiom — it cannot tell whether business logic
has drifted into a ViewModel, or whether navigation is registered in the right place. Those remain
matters for a written standard and the owner reading a diff, which makes the document at least as
load-bearing here as the one in DNLibrary.

**Three things make this the right moment rather than premature.**

1. **The defects already arrived.** A SwiftUI review on 2026-08-06 found three behavioural defects
   in the DN-009/DN-012 screens. Two were structural navigation faults: `navigationDestination` was
   registered inside a `case .loaded` branch and so deregisters on retry, and the detail screen's
   closure-based `NavigationLink` is mixed with the list screen's value-based one in a single
   `NavigationStack`. These are not independent slips. They are what happens when nothing in the
   repository says who owns navigation.

2. **Decisions already exist but are unfindable.** DN-012's commit message asserts *"Composition
   stays at the app root: the list receives a `(String) -> CookingClassDetailViewModel` factory, not
   the data layer, so `DapurNauraApp` remains the only place that knows a `DNDataLayer` exists."*
   That is a real architectural rule, currently recorded only in a commit message. A cold-started
   agent will not find it, and the next screen will quietly break it.

3. **The third screen is already approved.** `docs/requirements/2026-08-06-recipe-detail.md` is
   approved and unticketed. Deciding the structure now costs one document; deciding it after five
   screens costs a refactor of five screens.

There is no requirement document behind this and there cannot be — nobody writes a requirement
asking for a navigation convention. That is what `type: technical` exists for.

## Context

Read before starting:

- **`DNLibrary/CODEBASE-STANDARD.md`** — the sibling document. Match its shape deliberately:
  numbered sections, **must** for rules and **should** for guidance, every rule carrying the
  specific reason it exists rather than generic advice, and a closing `## Known violations` section
  that admits what does not yet comply.
- **`ios/DapurNaura/CLAUDE.md`** — build variants, secrets, the local package rule, SKIE bridging
  notes, known issues. **Do not duplicate any of it.** The new document links to it and covers only
  what it does not.
- **`docs/ARCHITECTURE-AND-WORKFLOW.md`** §4–§6 — the Definition of Done, which places the testing
  obligation on the data layer and is the premise of §10.
- The current Swift sources on `ticket/DN-012-cooking-class-detail-ui` — ten files, two screens,
  two shared helpers.

Prior art by the same author, worth reading before inventing anything:

- **`~/Desktop/XcodeProjects/MovieDB`** — UIKit + VIPER, with `AppConfigurator` / `AppNavigator` /
  `ScreenFactory` performing exactly the "protocol registered at the app root" pattern. It is good
  UIKit architecture and the reasons it works there are mechanical to UIKit — `pushViewController`
  needs a constructed `UIViewController`, so something must build it. Read it to understand what
  does **not** carry over, not as a template.
- **`~/Desktop/XcodeProjects/MovieDBDataLayer`** — a Swift package that throws (`async throws` +
  `NetworkError`) where DNLibrary returns sealed results. Both are correct for their language. The
  document should say why, so the DNLibrary rule is not cargo-culted into future pure-Swift code.

Already true, and constraining:

- The app is **one target, one module**. There are no feature packages, so patterns that exist to
  protect module boundaries have nothing to protect here.
- `DNLibrary` is already the repository-and-use-case layer. **A second one in Swift would be the
  classic KMP duplication mistake** and the document must forbid it explicitly.
- The committed app does not compile, by design, under the local package rule. Any example code in
  the document cannot be verified by building.

## Technical approach

Produce **`ios/DapurNaura/CODEBASE-ARCHITECTURE.md`**, sibling in shape to
`DNLibrary/CODEBASE-STANDARD.md`. Proposed section list:

| § | Section | What it fixes |
|---|---|---|
| 1 | Layering | `View → ViewModel → DNLibrary use case`, inward only. The app owns no business logic. |
| 2 | The ViewModel contract | `@MainActor @Observable final class`, `private(set) var state`, one `State` enum, must not `import SwiftUI`, must not navigate. |
| 3 | Views — structure and composition | One type per file; extract `View` structs rather than `@ViewBuilder` helpers; folder per feature. |
| 4 | Navigation | Per-feature `Route` enums under a thin top-level wrapper, one `navigationDestination`, `NavigationLink(value:)` as the only idiom, routes carry ids rather than model objects. Both defects found on 2026-08-06 become unrepresentable: one registration on always-rendered content cannot deregister, and with no closure form there is nothing to mix. Must also record **when** to drop the wrapper — separate Swift packages, not screen count. |
| 5 | Composition root | Promotes DN-012's commit-message rule into a written one. |
| 6 | Crossing the SKIE boundary | `description_`, `onEnum(of:)`, `companion.stub()`, `try await`, and that Kotlin nullability carries meaning — `portions == nil` means *locked*, not *absent*. |
| 7 | Errors, loading and empty states | One Indonesian vocabulary, `ContentUnavailableView`, and cancellation distinguished from real failure in `catch`. |
| 8 | Language and content | Code and comments English; every user-facing string Bahasa Indonesia; no localisation planned, therefore no string catalog. |
| 9 | Design system | Shared constants for spacing, rounding and colour. Semantic fonts only — never `.system(size:)`. 44pt minimum tap targets. **No VoiceOver section** — see the decisions table. |
| 10 | Where logic belongs | See below. The `must` from Q4, and the reasoning behind it. |

Plus **SwiftLint**: add `.swiftlint.yml` and wire the build phase, with the rule set chosen to match
what this document already says rather than pulling in defaults wholesale. Rules the document does
not justify should be off.

Closing sections, mirroring the sibling: **Before submitting a change**, **What the build enforces
for you** (SwiftLint, and precisely what it does and does not catch — the gap it leaves is what the
rest of the document is for), and **Known violations**, pre-populated from the 2026-08-06 review so
the document starts honest rather than aspirational.

**Section 10 is the load-bearing one.** Read as architecture rather than process, "tests are
required for the data layer only" means *any logic written in Swift is logic nothing will ever
test*. The rule that follows is not "write good ViewModels" but **push logic across the boundary
into DNLibrary, where the tests are**. A ViewModel that maps a state machine is fine. A ViewModel
that computes a price, sorts, or decides eligibility is untestable by construction. That single
rule explains the shape of the whole app and is not derivable from any general MVVM guidance.

## Public API contract

None. This ticket produces one Markdown file and changes no Swift, so no consumer sees anything.

**Version bump implied:** none.

## Out of scope

- **Applying the standard to existing code.** The 2026-08-06 review findings — the two navigation
  defects, the swallowed `catch`, the per-call `NumberFormatter` — are separate tickets. This one
  decides the rules; fixing DN-009 and DN-012 against them is DN-015 onward. Folding them in would
  reopen DN-012, which the owner has already verified on the running app.
- **The navigation refactor itself**, for the same reason.
- **Fixing the existing violations SwiftLint reports.** Adding the tool and its configuration is in
  scope; working through whatever it flags in the current code is DN-015 onward, so that this ticket
  stays reviewable.
- **SwiftLint anywhere except `ios/DapurNaura`.** Owner's instruction, 2026-08-06: the app only, not
  the KMP library. `.swiftlint.yml` lives in the app repo and nowhere else. Do not add it to
  `DNLibrary` — it has no Swift sources, its equivalent gate is `explicitApi()` plus
  `:sharedLogic:check`, and **no Kotlin lint tool is to be proposed as a counterpart**. Do not add it
  to `ios/SPMDNLibrary` either; that repo is a single manifest file.
- **Android.** No app exists yet. When it does it gets its own document; this one must not pretend
  to be cross-platform.
- **Anything already in `ios/DapurNaura/CLAUDE.md`** — variants, secrets, the local package rule.

## Open questions

**This ticket exists to answer these.** They are decisions for the owner, not gaps for the agent to
fill quietly. Agent recommendations are given so the owner is choosing between concrete options
rather than starting from nothing.

| # | Question | Options | Agent recommendation |
|---|---|---|---|
| 1 | **Routing pattern** | (a) `Route` enum + one `navigationDestination`; (b) Coordinator object owning push/pop; (c) protocol registration at the app root, as in MovieDB | **Answered — (a), with per-feature enums.** |
| 2 | **Who owns the navigation path** | (a) `@State` in a root view; (b) an `@Observable AppRouter` in the environment | **Answered — (b).** |
| 3 | **Closures vs a `ViewModelFactory`** | Keep passing `(String) -> DetailViewModel` closures, or introduce a factory | **Answered — factory.** |
| 4 | **When the app has to work something out, which half does it?** Business rules — prices, eligibility, what a user may open — in the tested Kotlin half, or allowed in the untested Swift half? | A strict rule, or a suggestion | **Answered — strict, and stricter than proposed. See below.** |
| 5 | **Where the document lives** | `ios/DapurNaura/CODEBASE-ARCHITECTURE.md`, or `docs/` in the umbrella | **Answered — the app repo.** |
| 6 | **Do we support blind users?** VoiceOver reads the screen aloud; supporting it means describing every image and icon in words, on every screen, forever | Required before release, written down as a goal, or not done | **Answered — see below.** |
| 7 | **`ContentView.swift`** | Delete as dead scaffolding, or keep | **Answered — delete.** |

Questions 1–5 and 7 carry recommendations the owner can accept or overrule in one pass.

### Decisions taken by the owner, 2026-08-06

> "I dont need VoiceOver. UITest no need for now"
>
> — owner, verbal, 2026-08-06, reaffirmed after the agent set out what each term covers

| Question | Decision |
|---|---|
| VoiceOver (Q6) | **Not a requirement.** The document gets no accessibility section and no VoiceOver rules. |
| Dynamic Type | **Stays**, as one line inside §9 Design system. |
| UI tests | **None for now.** Confirms the existing platform Definition of Done rather than changing it; `DapurNauraUITests/` stays empty scaffolding. |
| SwiftLint (Q4) | **Added by this ticket**, not deferred. Configuration lands with the document. **`ios/DapurNaura` only** — see the scope note below. |
| Routing pattern (Q1) | **A `Route` enum with one `navigationDestination`. Route enums are split per feature**, each living in its own feature folder, wrapped by a thin top-level `Route`. Not a Coordinator, not protocol registration. |
| Navigation path owner (Q2) | **An `@Observable AppRouter` in the environment**, from the start rather than deferred to the third screen. Its path stays `[Route]`. |
| Screen construction (Q3) | **A `ViewModelFactory`**, replacing the per-screen closures DN-012 introduced. |
| Document location (Q5) | **The app repo, beside the code it governs.** Final path is `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` — moved out of the root by DN-017 in the same session. |
| `ContentView.swift` (Q7) | **Deleted**, mirroring DN-004 in the data layer. |

| Where logic lives (Q4) | **A strict `must`, with no formatting exception.** The agent proposed keeping presentation formatting in Swift; the owner rejected that as too loose. Display formatting derived from data moves to DNLibrary as well. **A ViewModel consumes — it does not compute and does not format.** |

**All open questions are now answered.** The ticket is fully specified.

### How Q4's stricter form works

The agent's proposal was *business rules in Kotlin, formatting stays in Swift*. The owner's decision
removes the exception, on a ground the agent had under-weighted: **an Android app is planned.**
`rupiah()` and `DNError.indonesianMessage` currently live in Swift, so Android would reimplement
both, and the same failure would eventually be worded two different ways on two platforms.

**Formatting moves as shared functions, not as fields on domain models.** Returning display strings
from use cases would turn domain models into view models and contradict `CODEBASE-STANDARD.md` §2.
Instead the formatters themselves become public, tested KMP API — `CookingClass.price` stays a
`Long`, and both platforms call the same function to render it.

**The boundary is the view.** Formatting derived only from data belongs in DNLibrary. Formatting
that depends on view context — truncating to fit two lines, choosing a short label because a card is
narrow — stays in Swift, because only the view knows. Dates are the case to decide when one first
appears; `"2 hari lalu"` is data-derived, but Swift's `Date.formatted()` is materially better than
reimplementing it in Kotlin.

**Accepted cost.** Every copy change becomes a library release: edit Kotlin, run tests, publish, tag,
release, bump the app. Today it is a one-line Swift edit. The owner accepted this in exchange for one
tested source of truth across both platforms. Do not quietly reintroduce a Swift-side formatter to
avoid the release cycle.

**Cross-repo consequence — not this ticket's work.** `Rupiah.swift` and `DNError+Message.swift` must
move into DNLibrary, which is a data-layer change requiring its own ticket, a published version and
an app bump. File it separately; DN-014 only writes down the rule.

**Not to be raised again until the owner brings them up:** CI, and UI tests. Both are deliberate
deferrals, not oversights. Do not list them as gaps, absences, or future work in this ticket, in
`CODEBASE-ARCHITECTURE.md`, or in review commentary.

**Why Dynamic Type survives a "no accessibility" decision.** The two were separated before the
owner confirmed. VoiceOver carries a permanent per-screen cost — a label on every image, grouped
elements, testing with the screen curtain. Dynamic Type carries **none**: the existing screens use
semantic fonts (`.headline`, `.subheadline`, `.caption`) rather than `.system(size:)`, so text
already scales and nothing needs adding. §9 therefore states it as a rule about font choice, not as
an accessibility feature — *use semantic fonts, never `.system(size:)`* — which is what the code
already does.

The one thing worth watching is layout at large text sizes, not support for it: the class name and
status badge share an `HStack` in `CookingClassListView`, and that pairing crowds first.

**Why "no logic in Swift" is a `must` rather than guidance.** SwiftLint catches formatting and
idiom; it cannot see that a price calculation has drifted into a ViewModel. Logic written in Swift
is logic that nothing checks, so the rule keeping it out of Swift has to bind rather than advise.
§10 should say that plainly.

**Consequence for follow-up tickets.** Three findings from the 2026-08-06 SwiftUI review are now
out of scope permanently and must not be carried into DN-015 onward: unlabelled `AsyncImage`s, the
unlabelled `lock.fill` icon, and row element grouping. The three behavioural defects are unaffected
— none of them are accessibility.

## Test plan

**A `docs` ticket has no automated gate.** The owner reading the diff *is* the verification, so this
section says what to check rather than which task to run.

1. **Every rule traces to something real.** Any rule that could have been copied from a general
   SwiftUI article, rather than from this codebase or a decision taken here, does not belong.
   The sibling document sets this bar explicitly.
2. **No contradiction with `ios/DapurNaura/CLAUDE.md`, `DNLibrary/CODEBASE-STANDARD.md`, or
   `docs/ARCHITECTURE-AND-WORKFLOW.md`.** Where they overlap, the new document links rather than
   restates — a rule written twice is a rule that will disagree with itself later.
3. **Every Open question above is answered in the text**, with the owner's decision recorded and
   dated, in the manner of DN-010's decisions table.
4. **`## Known violations` is populated, not empty.** The current code does not comply — the
   document opens honest or it is not describing this repository.
5. **The examples are marked unverified.** The committed app does not compile under the local
   package rule, so no code sample in the document has been built. Say so rather than implying
   otherwise.

## Done when

Docs work (the workflow standard itself):

- [ ] Every document stating the rule updated — they must agree with each other
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Implementation notes (2026-08-06)

Delivered on `ticket/DN-014-ios-codebase-architecture` in **both** repos — the umbrella carries this
ticket, `ios/DapurNaura` carries the document and the linter config.

**What landed**

- `ios/DapurNaura/CODEBASE-ARCHITECTURE.md` — 10 numbered sections plus *Before submitting a change*,
  *What the build enforces for you*, and a populated *Known violations* table listing nine ways the
  current code does not yet comply.
- `ios/DapurNaura/.swiftlint.yml` — rule set chosen against the document rather than adopted
  wholesale, with four custom rules that enforce §4, §6, §9 and §10 directly.
- `DapurNaura/ContentView.swift` deleted (Q7). Nothing referenced it, and `project.pbxproj` never
  named it — `DapurNaura/` is a synchronized folder — so the deletion needed no project edit.

**SwiftLint verified.** The owner installed it mid-ticket, so the configuration was executed rather
than shipped unverified. Against SwiftLint 0.65.0: **5 violations across 12 files, 1 error.** Every
one is already a row in the document's known-violations table — the linter found nothing the document
had not predicted, which is the right result on a first run.

The custom rules fire on real code, not hypotheticals: `no_navigation_link_closure` reports
`CookingClassDetailView.swift:134` as an **error**, and `no_swift_number_formatter` reports
`Rupiah.swift:13`. `no_system_font` and `no_default_in_onenum` stayed silent because there is nothing
to catch.

One configuration fault was found by running it and fixed: `unused_import` was listed under
`opt_in_rules`, but it is an analyzer rule and only runs under `swiftlint analyze`. SwiftLint warned
about it on every invocation. Moved to `analyzer_rules` alongside `unused_declaration`.

**One rule was designed and then dropped.** §2's *a ViewModel must not import SwiftUI* was drafted as
a custom rule, but expressing it needs "this file contains both X and Y", which regex handles badly.
An approximation that misfires trains people to ignore the linter, so it was removed and §2 is
enforced by review. Both the config and the document record that decision so it is not re-attempted.

**The build phase was not wired.** Adding a SwiftLint run-script phase means editing
`project.pbxproj` — the file that carries the local-package wiring and must never have it committed.
That edit cannot be verified without Xcode, so it is left to the owner rather than done blind.

**Out of scope and deliberately not done:** none of the nine known violations were fixed, including
the two navigation defects. DN-014 wrote the rules; applying them is DN-015 onward. Fixing them here
would have reopened DN-012, which the owner has already verified on the running app.

**Follow-ups filed the same session:** **DN-015** (fix the known violations), **DN-016** (move the
formatters into DNLibrary), **DN-017** (move the standards documents out of the repository roots —
which relocated this ticket's own deliverable to `ios/DapurNaura/docs/`).

## Notes

Filed by the agent at `status: todo` on 2026-08-06 after the owner asked for a ticket covering the
iOS codebase structure and architecture. **Filing is autonomous; scheduling is not** — the owner
scheduled it in the same session, after taking all seven decisions.

It stacks on `ticket/DN-013-lower-deployment-target`, the umbrella tip, because it edits
`docs/tickets/README.md`, which every ticket in the DN-010 → DN-013 stack also edits.
