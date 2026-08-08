---
id: DN-015
type: technical
title: Bring the two existing screens up to CODEBASE-ARCHITECTURE — navigation, error handling, composition
status: done
source: —
branch: ticket/DN-015-apply-architecture-to-screens
layer: ui
---

## In plain language

DN-014 wrote the rulebook for the iPhone app. This ticket fixes the two screens that already exist so
they follow it.

Three of the fixes are real faults, not tidying. Two of them can lose the screen the user is looking
at, and one can leave the app spinning forever with no way out. The rest is making the code match the
rules so the next screen can be copied from it safely.

Nothing new appears in the app. The screens look and behave the same, except that three things that
were broken stop being broken.

## Rationale

`CODEBASE-ARCHITECTURE.md` ships with a populated `## Known violations` table because the code it
governs predates it. **DN-014 wrote the rules and deliberately did not apply them** — folding the
fixes in would have reopened DN-012, which the owner had already verified on the running simulator.

This is that follow-up. Three items are behavioural defects found by review on 2026-08-06:

1. **`navigationDestination` is registered inside a conditional branch.**
   `CookingClassListView` registers it inside `case .loaded`. Tapping *Coba Lagi* sets `.loading`,
   the `List` disappears, the registration goes with it, and any pushed detail screen is torn down.
   Violates §4.

2. **Two navigation idioms are mixed in one `NavigationStack`.** The list pushes by value; the detail
   screen pushes recipes with a closure-based `NavigationLink`. SwiftUI loses destinations when both
   are present. Violates §4, and SwiftLint now reports it as an **error**.

3. **An empty `catch` can strand a screen on a permanent spinner.** Both ViewModels set
   `state = .loading`, then swallow every error. Anything other than cancellation leaves the screen
   spinning with no retry. Violates §7.

The remainder are structural: two files carrying two types each, four `@ViewBuilder` helpers where
extracted structs belong, per-screen closures where §5 requires a `ViewModelFactory`, and design
literals repeated across three files.

**Why now.** The recipe-detail screen is approved and unticketed. Whatever these two screens look like
when it starts is what it will be modelled on — a rulebook nothing complies with teaches nothing.

## Context

Read before starting:

- **`ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md`** — all ten sections. The `## Known violations`
  table is this ticket's scope, and every row must be struck off or explained.
- **`docs/tickets/DN-014-technical-ios-codebase-architecture.md`** — the decisions and why each rule
  exists. Do not re-litigate them here.
- **`ios/DapurNaura/CLAUDE.md`** — the local package rule, and the `git add -A` prohibition.

Already true, and constraining:

- **DN-012 was verified by the owner on the running app.** Behaviour must not change except for the
  three defects. If a fix alters what the user sees, stop and say so.
- The three purchase states must keep behaving exactly as DN-012 specified — in particular, the
  awaiting-confirmation state still shows no buy button.
- iOS work stacks on `ticket/DN-014-ios-codebase-architecture`.
- `swiftlint lint` currently reports 5 violations, 1 error. It must report 0 when this is done.

## Technical approach

**The three defects first, in their own commit**, so the behavioural fix is reviewable without the
structural churn around it.

- Move the single `navigationDestination` onto the `NavigationStack`'s content, outside the state
  switch.
- Introduce `Route` with per-feature `ClassRoute` / `RecipeRoute` enums (§4), replacing
  `navigationDestination(for: String.self)`. Routes carry ids.
- Convert the recipe `NavigationLink` to the value form.
- Split the `catch` in both ViewModels: `catch is CancellationError` leaves state untouched, anything
  else sets `.failed`.

**Then the structure**, as a second commit:

- Extract `CookingClassRow`, `RecipeRow`, and the detail screen's four `@ViewBuilder` helpers into
  `View` structs, one per file (§3).
- Add `AppRouter` as `@Observable`, held at the root, injected via `.environment` (§4).
- Add `ViewModelFactory` and route every screen's construction through it, replacing the per-screen
  closures (§5).
- Lift spacing, corner radii and colours into shared constants; drop `.caption2` (§9).

## Public API contract

None — app-side only. **Version bump implied:** none.

## Out of scope

- **Moving `rupiah()` and `DNError.indonesianMessage` into DNLibrary.** That is **DN-016**; it needs a
  published library version. Leave both where they are, still violating §10, and leave that row in the
  known-violations table with a pointer to DN-016.
- **Wiring the SwiftLint build phase.** Editing `project.pbxproj` risks the local-package reference.
- **Any visual or behavioural change** beyond the three defects.
- **The recipe detail screen.** Its own ticket, from the approved requirement.

## Test plan

UI work, so the owner verifies on the running app. `swiftlint lint` must report **0 violations**
before that hand-off.

What the owner should exercise, because these are the paths the defects live on:

1. **Open a class, go back, tap *Coba Lagi*, open a class again.** Defect 1 shows up here — before the
   fix, the retry can tear down a pushed detail screen.
2. **Open a bought class, tap a recipe.** Defect 2 — the placeholder must appear.
3. **All three purchase states still render exactly as DN-012 left them.** Bought shows no price and
   opens recipes; awaiting-confirmation shows the note and **no buy button**; unbought shows
   `Beli Kelas · Rp125.000` and inert recipes.
4. `portions` and `loyang` still render as two separate labels, absent rather than blank when locked.

## Done when

UI work:

- [ ] Code implemented on `ticket/DN-015-apply-architecture-to-screens`
- [ ] `swiftlint lint` reports 0 violations
- [ ] Every `## Known violations` row struck off, except the §10 row deferred to DN-016
- [ ] Verified manually by the human
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Amendment (2026-08-06) — folder conventions and navigation ownership

The ticket's original scope landed in `8d6937c`. The owner then reorganised the iOS tree by hand and
proposed hoisting navigation out of leaf components, in the manner of Compose's `onClick` +
`NavHost`. Reviewing that produced five corrections and two new rules, all delivered on the same
branch. **`CODEBASE-ARCHITECTURE.md` §3 and §4 were amended rather than DN-014 reopened** — the owner
has already reviewed DN-014's document, and reopening it would invalidate that review.

**What the owner had already got right, and was left alone:** the `App/` grouping (entry point,
config and navigation together, which makes §5's composition root visible rather than asserted), and
`Presentation/` split per feature.

**Corrections**

| Finding | Fix |
|---|---|
| Three files no longer matched the type inside them — `DapurNauraAppConfig.swift` held `AppConfig`, and both route files held differently-named enums. SwiftLint cannot catch this: `file_name` is opt-in and not enabled. | Type renamed to `DapurNauraAppConfig`; route files renamed to match their enums. §3 now states the rule and that review, not the linter, enforces it. |
| **Route ownership was inverted.** Both route enums sat with the screen that *pushes* them. That holds only while each screen has one entry point — the second screen to push a recipe would have to import the class-detail feature's vocabulary. | Routes moved to the feature they open: `ClassRoute` → `CookingClassDetail/`, `RecipeRoute` → `RecipeDetail/`. §4 gained the destination-ownership rule. |
| `Atom/` was not atomic design — it held an atom (`PurchaseStatusBadge`), two molecules (`CookingClassRow`, `RecipeRow`) and an organism (`PurchaseSection`, which owns `@State` and an alert). It also duplicated the existing `Presentation/Components/` at a different scope. | Both renamed to `Components/`, told apart by position. §3 forbids atomic tiers and explains why: scope is a fact, tier is an argument re-had on every new file. |
| `Helper/` is a junk drawer that DN-016 empties — it holds only the two formatters plus `DesignConstants`, which is §9's design system rather than a helper. | `DesignConstants.swift` → `Presentation/`. `Helper/` is marked transitional in §3 and takes nothing new. |
| `RecipeLink`, a feature component, imported the app-level `Route` type and chose the destination. | Deleted. `CookingClassDetailLoadedView` already computed `isPurchased`, so it now decides. |

**The navigation rule, and where it differs from the proposal**

The owner's instinct was right and half-implemented already — `CookingClassListView` wraps
`CookingClassRow` in the link itself, so the row knows nothing. `RecipeLink` was the one real
violation.

The rule written into §4 is **"nothing below screen level may name `Route`"**, not "no
`NavigationLink` below screen level". A literal translation of Compose's `onClick` + `NavHost` would
have replaced `NavigationLink(value:)` with `Button` + `path.append` everywhere, and inside a `List`
that costs the disclosure chevron, row press states and selection behaviour — `RecipeRow` already
hand-draws its own `chevron.right`, which is that tax paid once. `NavigationLink(value:)` is already
state-hoisted: the child declares an intent, the parent's `navigationDestination` resolves it. So the
mechanism stays; what moved is the knowledge.

**`DapurNauraAppRouter`**

§4 specified an `@Observable AppRouter` — the owner's Q2 decision in DN-014, *"from the start rather
than deferred"* — and **no such type existed**. The stack used SwiftUI's implicit path. Added under
the owner's name (2026-08-06), matching `DapurNauraApp` / `DapurNauraAppConfig`, held as `@State` on
`DapurNauraApp`, injected with `.environment(_:)`, bound as `NavigationStack(path: $router.path)`.

It is **the array and nothing else**. `push(_:)` and `popToRoot()` were written and then removed:
`NavigationLink(value:)` appends and the back button removes, so neither had a caller, and a
convenience method nothing calls is worse than none because the next screen copies it. The purchase
flow will be the first real caller, needing pop-to-root once a completed payment has to unwind
however deep the user has gone.

**Verified:** `swiftlint lint` reports 1 violation — the `NumberFormatter` in `Rupiah.swift`, which
is the §10 row deferred to DN-016 and deliberately left failing. `xcodebuild -scheme "DapurNaura Dev"
-destination 'platform=iOS Simulator,name=iPad (A16),OS=26.3.1'` → **BUILD SUCCEEDED**.

**The `@ViewBuilder` state switch — resolved, on the owner's instruction of 2026-08-06.**

Three `@ViewBuilder content` properties remained after the work above, while the known-violations
table already claimed that row struck off. Investigating it turned up something worse than the
inconsistency: **§3's stated reason for the rule was wrong.**

The document justified banning computed properties with *"SwiftUI diffs and re-renders at struct
boundaries."* True in general, and inert here — the input that changed is the very state the property
switches on, so an extracted struct re-renders exactly the same. **A rule defended by a reason that
does not survive checking teaches people to stop trusting the document**, which costs more than the
rule buys. It also made §3 stricter than Apple's own samples, which use `@ViewBuilder` helpers
freely, without saying so.

The real justification is **previews**, and the app had **zero `#Preview`s** — not from neglect, but
because no screen could be previewed without a ViewModel, a use case and a `DNDataLayer`. That
constraint is now recorded honestly, along with what the earlier reasoning got wrong.

The agent's first framing of this overstated it as *"previews are impossible"*; `DNDataLayer.stub()`
does make the happy path previewable. **What the stub cannot do is fail**, so `.failed` was
unreachable, and so was `.loaded` with the awkward data. The corrected claim — deterministic states,
not previews-at-all — is what §3 now argues.

**Delivered:** `CookingClassListContent` and `CookingClassDetailContent`, each taking `state` plus an
`onRetry` closure, with seven previews between them covering the failure, all three purchase states,
and the long-class-name-beside-widest-badge pairing §9 flags as the first thing to crowd at large
text sizes. §3 rewritten around the previewability test — *can you `#Preview` it in every state?*

**`RecipePlaceholderView` deliberately left alone**, and recorded as a standing exemption in
`## Known violations` rather than silently skipped. It is marked temporary and the recipe-detail
screen replaces it wholesale; tidying code with a deletion date is churn. The exemption dies with the
file.

### Four findings from a critical re-read, 2026-08-06

The owner asked whether the delivered code was actually SwiftUI best practice. Re-reading it against
that question rather than against the ticket found four things. All four are fixed here, on the
owner's instruction.

**1. `body` used an explicit `return` after `@Bindable`.** It compiled, but an explicit `return` opts
the body out of the `@ViewBuilder` transform, and Apple's documented form for `@Bindable` in a body
omits it. Removed.

**2. View identity was positional, so a replaced route would have shown the previous screen.**
The real one. `RouteDestination.body` calls `factory.make…` on every evaluation, and
`CookingClassDetailView.init` stores it with `State(initialValue:)` — **which is honoured only on the
first render.** Every later pass builds a ViewModel and discards it.

Wasted allocation is the small half. The dangerous half is that SwiftUI identifies a destination by
its *position* in the path: replace the route at a given depth — "next recipe", or a deep link
landing on a different class — and the view at that position keeps its `@State`, so the stale
ViewModel survives and the user reads the wrong kelas.

It could not fire today, because every push lands at a new depth. It would have fired the first time
a feature replaced a route in place, and it would have looked like a data bug rather than a
navigation one. Fixed with `.id(route)` at the single `navigationDestination` registration, and §4
now requires it with the reasoning attached.

**The discarded allocation is accepted, explicitly.** A ViewModel here stores two references. §4
records the rejected alternative — making the ViewModel optional and building it in `.task` — because
it trades a cheap allocation for an optional unwrap in every body and a loading state that would mean
two different things.

**3. `@Environment(DapurNauraAppRouter.self)` is non-optional and traps when absent**, so any future
`#Preview` of a router-reading view crashes without `.environment(DapurNauraAppRouter())`. Not hit by
the previews delivered here — they target the `Content` views, which is the other reason §3 wants
that split — but a trap waiting for whoever previews a screen next. Documented in §4 and on the type.

**4. The router earns nothing today, and that is now written down.** `NavigationLink(value:)` drives
navigation; only `NavigationStack` reads `path`. It exists for deep links, state restoration and
pop-to-root after payment — scheduled work, and cheaper to carry across two screens than to retrofit
across five. §4 states this plainly and forbids citing it as precedent for adding other structure
ahead of need, which is the failure mode of leaving a speculative abstraction unexplained.

**Re-verified after all four:** `xcodebuild -scheme "DapurNaura Dev"` → **BUILD SUCCEEDED**,
`swiftlint lint` → 1 violation, the §10 row held for DN-016.
