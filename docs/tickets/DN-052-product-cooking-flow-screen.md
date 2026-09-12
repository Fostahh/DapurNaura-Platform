---
id: DN-052
type: product
title: The cooking flow — three pages from ingredients to finished, entered from the recipe
status: in-review
source: docs/requirements/2026-09-12-cooking-a-recipe.md
branch: ticket/DN-052-cooking-flow-screen
layer: ui
---

## Rationale

From the requirement. A cook with the recipe open has no way to work through it without losing their
place. This builds the flow: a checklist, the method, and a finish.

**Page 2/3's video is deliberately not in this ticket.** It needs a web view, YouTube's player
interface and a JavaScript bridge for seeking — a different kind of work from three SwiftUI pages,
and the riskiest part of the feature. **DN-053** does it, and this ticket leaves a placeholder in its
place so the flow is walkable end to end without it.

## Context

Read before starting:

- `docs/requirements/2026-09-12-cooking-a-recipe.md` — the whole document
- `RecipeDetailContent.swift` and `RecipeComponentSection.swift` — the screen this is entered from,
  and how components are laid out today
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §3 (folder layout), §4 (navigation), §5 (the
  composition root)
- **DN-051 must be merged first** — the checklist reads and writes progress through it

## Technical approach

**The entry is a new button on the recipe detail screen, pinned to the bottom** above the safe area,
over the scrolling content.

> **This differs from `Beli Kelas`, which sits inline in the class detail's scroll view.** Deliberate,
> and the requirement records why: buying is a decision made *after* reading, while cooking is what a
> returning cook wants *immediately*. **Recipe detail changes in no other way.**

**One screen, three pages, progress pinned at the top** — a horizontal line in three segments with a
counter reading `1/3`, `2/3`, `3/3`.

**Movement is by button only; there is no swipe.** Pages after the first carry their own back
control. The navigation bar's back button therefore means one thing only — leave the flow — and is
never overloaded to step between pages.

> **The owner hoped for one `View` struct.** Expect one container plus three small page views: still
> one screen, one navigation destination, one flow. Three genuinely different layouts inside a single
> `body` would be worse code, not better, and the container is what owns the page state.

> **iOS 17 has real vertical paging** (`ScrollView` + `.scrollTargetBehavior(.paging)`), but it is
> **not** what this needs — that brings a swipe gesture the owner ruled out. A container with a
> vertical transition is the right shape. `TabView(.page)` is horizontal-only and the rotation trick
> to make it vertical is not worth its cost.

**Page 1/3 — the checklist.** Ingredients grouped by component, each component introduced by its name
in bold with **a grey divider line between groups**.

> **The divider is new.** Recipe detail separates components with the bold name and spacing alone.
> The owner asked for both here; recipe detail is **not** changed to match.

Tapping a row checks it and strikes the text through. Ticks are read and written through DN-051, so
they survive a restart, and the flow resumes on the page it was left on.

**Page 2/3 — placeholder.** The timestamp list and the video arrive in DN-053. This ticket puts
something in its place so the flow can be walked and reviewed.

**Page 3/3 — finished.** A headline, then the recipe name on its own line, then two controls:

```
Selamat!

Anda sudah selesai membuat

Brownies Red Velvet Cheese & Original Cheese

        [ Ulangi ]      [ Selesai ]
```

**The recipe name is on its own line because it can be long** — this one is forty-four characters and
buries the headline when run inline.

**`Selesai` returns to the recipe detail. `Ulangi` clears progress and returns to 1/3.** Neither
records anything anywhere.

> **Neither button may fake a completed state.** The backend tracker the owner described is blocked
> on auth and a backend, exactly as payment is. The screens admit what they cannot do rather than
> inventing a status — the rule set for the payment screens, applied here for the same reason.

**User-facing strings are the owner's.** *Selamat!*, *Anda sudah selesai membuat*, *Ulangi*,
*Selesai* and the forward/back labels for 1/3 and 2/3 are agent drafts marked `[ASSUMPTION]` in the
requirement, and can be replaced without argument.

## Corrections from the owner on the running app, 2026-09-12

**1. The page transition is horizontal, not vertical.** Owner's correction while reviewing the build:
*"my mistake sorry, the transition should be horizontally."* The requirement describes it as vertical
in several places and **is not edited** — it records what was asked for at the time. Its frontmatter
carries a `corrected-by: DN-052` pointer, which is the one edit an approved requirement permits.

**2. The pinned bar was too tall and its button too narrow.** The button now spans the full width
with the bar's vertical padding reduced from 16 to 12.

> **The cause is worth recording, because it was wrong in four places.** `.frame(maxWidth: .infinity)`
> was applied to the `Button` rather than to its label, so the tappable frame stretched while the
> filled pill still hugged its text. `PurchaseSection` already had it right — `Text(…)
> .frame(maxWidth: .infinity)` *inside* the button — and the flow's own controls and the finished
> page's two buttons had the same defect, all now matching the existing convention.

**3. The navigation title truncates, and it stays that way.** *Brownies Red Velvet Cheese & Original
Cheese* is forty-four characters, and an inline title cuts it to *"…& Original Ch…"*.

A `.principal` toolbar item with two lines was tried and **does not work**: iOS clips the navigation
bar rather than growing it, so the second line never appears. The remaining options were to drop the
title — the name already appears in full as a heading in the content — or shrink the text until it
fits, which at forty-four characters is far smaller than every other title in the app.

**Owner's decision: leave it truncated.** It is what iOS does by default and what Apple's own apps
do with long titles, and the full name is readable in the content immediately below.

> **So `RecipeDetailContent` changes only to gain the button**, exactly as *Out of scope* requires.
> The earlier draft of this section recorded a deliberate exception to that rule; there is no longer
> an exception to record.

## SwiftUI review, 2026-09-12

Run on the owner's instruction before committing, against the `swiftui-pro` reference set. The
reviewer wrote the code, which is worth stating.

**Acted on:**

- **`loaded(_:)` became `CookingFlowPager`, its own `View` struct.** The reference states twice that
  view bodies should not be broken up with methods returning `some View`. Extracting it left
  `controls` as the only such helper, so that became `CookingFlowControls` too.
- **Logic left `body`.** Navigation (`router.path.removeLast()`) and a `Task`-wrapping button action
  were inline; both are now methods. `CookingFlowView` is a `body` plus five small methods.

**Declined by the owner, and recorded rather than silently skipped:**

- **Reduce Motion.** The pager slides a full screen width, which the reference says should fall back
  to opacity when the setting is on. **Owner's decision: not needed for this project.**
- **VoiceOver.** Two decorative images — the checkbox glyph on every ingredient row and the party
  popper on 3/3 — are announced as *"checkmark circle fill"* and *"party popper fill"*. **Owner's
  decision: not needed for this project.**

> **These are recorded because they are real findings, not because they should be reopened.** If
> accessibility is ever in scope, this is the list to start from, and neither fix is large.

### The pager: `GeometryReader` kept over `ScrollView` paging, after trying both

The reviewer suggested iOS 17's `ScrollView` + `.scrollTargetBehavior(.paging)` +
`.scrollPosition(id:)` as the more modern shape. **It was built, run, and rejected by the owner.**

**Why it was worse here, and the cause is this screen's own layout:** the *Kembali* button appears
from page 2 onwards, so the controls bar changes height. That resizes the scroll container, which
makes `containerRelativeFrame` recompute all three pages **mid-animation**, while `.paging` competes
with `withAnimation` over who owns the position. The result was visibly laggy. `GeometryReader`
absorbs the same height change as one offset shift, with no scroll machinery holding an opinion.

| | `GeometryReader` | `ScrollView` paging |
|---|---|---|
| Animation | smooth | stutters when the controls bar resizes |
| Arithmetic | one multiply | none |
| Source of truth | `viewModel.pageIndex` alone | `pageIndex` **plus** a synced `scrolledPage` |
| Swipe | off by construction | must be switched off |

**The "manual calculation" is one line**, and it reads the current width from the proxy each time, so
nothing can go stale. The `ScrollView` version needed `@State`, `.onAppear` and `.onChange` to keep a
second copy of the current page in step — more state, not less.

> **The lag is probably fixable** — pinning the controls bar to a constant height would remove the
> resize. It was not pursued: that is added complexity to rescue an approach that was only ever a
> stylistic preference over one that already worked.

## Out of scope

- **The video and the timestamp list** — DN-053.
- **The storage itself** — DN-051.
- **Any backend call.** There is nothing to call and nobody to call it for.
- **Changing recipe detail** beyond adding the pinned button.

## Test plan

UI only, so no automated tests are added — per the platform Definition of Done, UI is verified by the
owner on the running app. **The build is not one of the steps a UI ticket skips** (DN-034).

What the owner checks:

| Check | Expected |
|---|---|
| *Mulai buat resep* on recipe detail | Pinned at the bottom, visible without scrolling |
| Page 1/3 | Thirteen ingredients in two groups, bold names, a grey divider between them |
| Tapping a row | Checked and struck through; tapping again undoes it |
| Forward, then back | 2/3 and back to 1/3, animated vertically, ticks intact |
| Force-quit mid-flow, reopen, re-enter | Ticks restored **and** the page resumed |
| Page 3/3 | Headline, recipe name on its own line, *Ulangi* and *Selesai* |
| *Selesai* | Returns to the recipe detail |
| *Ulangi* | Clears the ticks and returns to 1/3 |
| The navigation bar back button, on 2/3 | Leaves the flow — it does not step back a page |

## Done when

- [ ] The pinned button exists on recipe detail, and nothing else there changed
- [ ] Three pages, progress indicator, buttons only, per-page back control
- [ ] Checklist grouped by component with a grey divider; tick strikes through
- [ ] Ticks and page persist via DN-051 and resume correctly
- [ ] Page 3/3 reads as specified; neither button records or fakes anything
- [ ] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034)
- [ ] `swiftlint lint --strict` reports 0 violations
- [ ] Documentation sweep (DN-042)
- [ ] Diff reviewed by the owner on the running app
- [ ] Committed
- [ ] PR opened
- [ ] PR merged
