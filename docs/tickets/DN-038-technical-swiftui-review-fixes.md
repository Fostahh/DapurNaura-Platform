---
id: DN-038
type: technical
title: Dynamic Type and four view-level findings from the SwiftUI review
status: in-review
branch: ticket/DN-038-swiftui-review-fixes
layer: ui
---

## Rationale

A SwiftUI review of `ios/DapurNaura` on 2026-08-10 found no deprecated API at all — no
`foregroundColor`, no `cornerRadius`, no `NavigationView`, no `ObservableObject` family, no
`AnyView`, no `GeometryReader`. §3's composition rules hold across all three screens. What it did
find sits in two places the architecture document does not yet cover.

**Two of the six respect an accessibility setting the app currently ignores.**

`CODEBASE-ARCHITECTURE.md` §9 requires semantic fonts, and SwiftLint's `no_system_font` custom rule
enforces it with `severity: error` — its message says *"a fixed size never scales with the user's
text size."* That reasoning is right and the rule catches the case it names. But three views place
scaling text inside a **fixed point-width frame**, which reintroduces the same failure by a route
the regex cannot see:

```swift
// ios/DapurNaura/DapurNaura/Presentation/RecipeDetail/Components/IngredientRow.swift
Text(ingredient.quantity)
    .font(.subheadline.bold())
    .frame(width: DesignConstants.quantityColumnWidth, alignment: .leading)   // 72pt, fixed
```

The font scales; the column does not. At the larger accessibility text sizes the text truncates
inside a box that never grew. The three sites are `IngredientRow` (quantity, 72pt),
`RecipeComponentSection` (step number, 22pt) and `OfflineClassRow` (date column, 56pt) — and the
last is the first to break, because its day number is `.title`.

**This is worst where it matters most.** `DesignConstants` line 26 records why those columns are
fixed: *"the recipe method reads as two aligned columns… so the text lines up down the page."* That
alignment is for someone following a method with their hands busy — exactly the reader most likely
to have raised their text size, and the step number is their place-marker.

The second was Reduce Motion. `NoticeSheet` animates a full-height card up from the bottom edge with
`.transition(.move(edge: .bottom))`, unconditionally. SwiftUI does not gate author-written
transitions on the setting; `\.accessibilityReduceMotion` has to be read.

**That one was built and then dropped — owner's decision, 2026-08-10.** The finding stands as
written; only the work is unscheduled. See `## Out of scope`.

**The other four change no behaviour a user relies on**, and are grouped here because they were
found in one pass over the same views:

- `CategoryFilterChips.background(for:)` erases two `Color` branches through `AnyShapeStyle`. Both
  branches are already `Color`, so the erasure buys nothing and boxes an existential per chip.
- `CookingClassDetailLoadedView` evaluates `if isPurchased` **inside** its `ForEach`, though the
  value is constant across every row, building `_ConditionalContent` per recipe.
- `RecipeImageCarousel` draws `.tabViewStyle(.page)` index dots as plain white circles with no
  backing plate. Over a light recipe photo they vanish, taking with them the only signal that more
  images exist.
- `DapurNauraApp` initialises two `@MainActor` types in stored-property defaults, from a synthesised
  `init()` that is nonisolated. Swift 5 permits the implicit hop; Swift 6 makes it an error.

## Approach, in outline

- `@ScaledMetric(relativeTo:)` in the three views, each relative to the font its column pairs with.
  **`DesignConstants` keeps the base numbers** — §9 owns the value, the view owns how it scales.
- ~~`\.accessibilityReduceMotion` in `NoticeSheet`~~ — **dropped, see `## Out of scope`.**
- `background(for:)` returns `Color`; the `AnyShapeStyle` wrappers go.
- Hoist `if isPurchased` out of the `ForEach` in `CookingClassDetailLoadedView`.
- `.indexViewStyle(.page(backgroundDisplayMode: .always))` on the carousel, and hide the index
  entirely for a single-image recipe — one dot reads as a carousel that will not scroll.
- `@MainActor` on `DapurNauraApp`.

## Out of scope

- **Reduce Motion.** Built on this branch, then dropped — **owner's decision, 2026-08-10.** No reason
  was given, and none is inferred here. `NoticeSheet` is byte-identical to `development`; the revert
  is `a00f980`, a new commit rather than a rewrite of `2d3ac68`, because force-push is on the `Never`
  list and the branch was already pushed. **The finding in `## Rationale` is not withdrawn** — the
  sheet does move a full-height card unconditionally, and a later ticket that wants to fix it should
  start from there rather than rediscovering it.
- **VoiceOver labels and traits.** The review also found the app carries no accessibility modifiers
  at all — `SheetCloseButton` is an unlabelled icon-only button, `NoticeSheet` is a hand-built modal
  without `.isModal`, `RecipeRow`'s lock icon is the sole carrier of "you cannot open this", and
  `CategoryFilterChips` encodes selection in colour alone. **Owner's decision, 2026-08-10: not now.**
  Deliberately recorded here rather than dropped, because the finding is real and the next reader of
  this ticket should not have to rediscover it.
- The `RecipeDetail` divergences — no `LoadedView` split, `.navigationTitle` only in `.loaded`,
  preview fixtures at file scope where the offline feature has `OfflineClassPreviewSamples`. Also
  found in the same review, also left.
- Any wording change, any colour change, any layout change at the default text size.

## Done when

- [x] The three columns scale with the user's text size
- [x] `AnyShapeStyle`, the in-loop branch, the invisible dots and the isolation warning are gone
- [x] `** BUILD SUCCEEDED **` — the DN-034 gate. No compiler warnings, after forcing the changed
      files to recompile rather than trusting an incremental build. **Re-run after the Reduce Motion
      revert**, not carried over from the run before it
- [x] `swiftlint lint` clean — 0 violations, also re-run after the revert
- [x] **Owner verified the running app** and approved, 2026-08-10 — the one box the agent cannot
      tick itself
- [x] Committed, not merged — [DapurNaura-iOS#18](https://github.com/Fostahh/DapurNaura-iOS/pull/18)

## Notes

**Filed and started in one step on the owner's instruction, 2026-08-10.** The autonomy table makes
filing autonomous and scheduling the owner's; here the owner asked for the work directly, having
been shown each change as a code sample first.

**One ticket rather than two, deliberately.** The accessibility pair and the four corrections were
first split into DN-038/DN-039. They were merged back because the agent cannot commit: two branches
would have left the second ticket's untracked files riding in the first ticket's working tree for
the owner to untangle at commit time. One review event, one verification pass, one branch.

**No DNLibrary change**, therefore no tests, no `publish-spm.sh` run, no version bump and no
`Package.resolved` movement. The UI-only path in `CLAUDE.md` step 3.

## Implementation notes

**Reduce Motion was built, reviewed and then dropped**, all on 2026-08-10. It is recorded here
rather than erased because the ticket is the source of truth for a technical ticket, and a reader
comparing this file against the merged diff would otherwise find a change described and absent.

The revert is worth one line of process note: the branch was already pushed and the PR already open,
so the fix was `a00f980` on top rather than a rewrite of `2d3ac68`. `Never` forbids force-push, and
a two-commit history that shows the reversal is the honest record anyway — the PR body says the same.

**The title changed with it**, from *"Dynamic Type, Reduce Motion and four view-level findings"*. The
index row and `DapurNaura-iOS#18` were both updated to match; a title naming work the ticket no
longer contains is the kind of drift DN-029 was filed about.
