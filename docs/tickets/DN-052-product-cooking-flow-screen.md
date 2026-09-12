---
id: DN-052
type: product
title: The cooking flow — three pages from ingredients to finished, entered from the recipe
status: todo
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
