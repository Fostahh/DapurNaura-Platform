---
id: DN-015
type: technical
title: Bring the two existing screens up to CODEBASE-ARCHITECTURE — navigation, error handling, composition
status: todo
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
