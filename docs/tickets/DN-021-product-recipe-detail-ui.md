---
id: DN-021
type: product
title: iOS — the recipe screen, replacing the placeholder
status: done
source: docs/requirements/2026-08-06-recipe-detail.md
branch: ticket/DN-021-recipe-detail-ui
layer: ui
---

## Requirement (traced)

From [`../requirements/2026-08-06-recipe-detail.md`](../requirements/2026-08-06-recipe-detail.md),
approved 2026-08-06:

> "This is the screen the whole app exists to deliver. Everything before it — the class list, the
> class detail — is navigation; this is the content the owner's students paid for."

> Someone who has bought a cooking class and is now **cooking from one of its recipes** — most likely
> with the phone on the kitchen counter, hands busy, reading as they go.

Checkable statements, quoted:

> - Opening a recipe from a bought class shows its pictures, its name, its portions, its loyang, its
>   ingredients with quantities, and its steps in order.
> - Portions and loyang appear as two separate values.
> - No video, no difficulty and no preparation time appear anywhere on the screen.

### Correction to the requirement — read before the quotes above

The approved document carries `corrected-by: DN-019` and **has not been edited**. Its ingredient
shape is wrong: it describes one flat list with group labels. The owner supplied the first real
recipe on 2026-08-07 and **a recipe is a list of components, each with its own ingredients *and* its
own method**, split so a student can prepare each in a separate bowl. See DN-020 for the full
correction; the need the requirement states — *the parts of a recipe must not be merged* — is
unchanged and is exactly what components satisfy.

Consequently these two statements from the requirement no longer apply as written and are replaced:

> ~~Ingredient groups survive: a recipe whose source has *Bahan A* and *Bahan B* shows two named
> groups, not one merged list.~~
> ~~Ingredients with no group are still shown.~~

**Replaced by:** a recipe with two components shows two named sections, each with its own ingredient
list *and* its own numbered method. A recipe with one unnamed component shows no section heading.

## Context

Read before starting:

- **`ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md`** — all of it, but especially §3 (a view renders
  from state alone, so every state is previewable), §4 (nothing below screen level names `Route`),
  §7 (one Indonesian error vocabulary), §10 (a ViewModel consumes; it does not compute or format).
- **`DapurNaura/Presentation/CookingClassDetail/`** — the pattern to copy. `…View` owns the
  ViewModel and modifiers, `…Content` takes `state` and draws, `Components/` holds the parts.
- **`docs/contracts/recipe.json`** — what the screen actually has to render, including the awkward
  cases: an ingredient with `merk` and no `note`, one with `note` and no `merk`, a null `portions`.

Already true, and constraining:

- **`RecipePlaceholderView` and `RecipePlaceholderViewModel` are deleted by this ticket**, not
  extended. Both say so at the top of the file: *"TEMPORARY … Do not build on it."* They are also the
  standing §3 exemption in the known-violations table — **that exemption dies with them**, and the
  real screen complies like the other two.
- **`RecipeRoute` already exists** at `Presentation/RecipeDetail/RecipeRoute.swift` and already
  carries `(classId, recipeId)`. Navigation needs no change.
- **The placeholder resolves its recipe out of the class detail.** The real screen calls
  `GetRecipeUseCase` instead — one recipe, fetched by id.
- **`portions` may be null on a bought recipe** and that is not an error. Brownies Red Velvet has no
  portions value. Render loyang alone; do not show an empty row and do not invent a placeholder.

## Technical approach

Under `Presentation/RecipeDetail/`, replacing the two placeholder files:

| File | Role |
|---|---|
| `RecipeDetailView.swift` | owns the ViewModel, `.task`, navigation title |
| `RecipeDetailViewModel.swift` | `@MainActor @Observable`, `private(set) state`, calls `GetRecipeUseCase` |
| `RecipeDetailContent.swift` | takes `state` + `onRetry`, draws, carries the `#Preview`s |
| `Components/RecipeImageCarousel.swift` | the recipe carries more than one picture |
| `Components/RecipeComponentSection.swift` | one component: heading, its ingredients, its method |
| `Components/IngredientRow.swift` | quantity, name, `merk`, `note` |

**Layout is the agent's**, as it was for DN-012 — the requirement describes what is shown, not how.
Three decisions it does constrain:

- **Portions and loyang are two values, never merged.** A missing one is absent, not blank.
- **Steps are numbered and in order.** This is a method someone follows with their hands busy.
- **Ingredients belong to their component**, visually as well as structurally. A reader must never
  have to work out which bowl an ingredient goes in.

**`merk` earns visible weight.** It is commercial advice — which brand to buy, and which cheaper one
still works — for an audience learning to cook for income. Do not bury it as a footnote.

**Previews are required**, per §3: loading, failed, a two-component recipe, and a one-component
recipe with no heading. `Recipe` is a `public data class`, so SKIE exposes an initialiser and the
previews need no data layer.

## Public API contract

None — this is app code. **Consumes** DN-020's additions.

**Version bump implied:** none for the library; the app bumps to DN-020's published version.

## Out of scope

- **Video playback** — deferred by the owner. `videoUrl` and `videoTimestampSeconds` arrive in the
  model and are rendered nowhere. **Do not add a player, a thumbnail, or a "video coming" notice.**
- **`difficulty` and `prepTimeMinutes`** — deferred, and the values do not exist.
- **Cooking aids** — timers, step check-off, keep-screen-awake, scaling quantities to a different
  number of portions. The requirement names these out of scope deliberately: *"a kitchen screen
  invites them, so they are named here to keep them out of this one deliberately rather than by
  omission."*
- **Offline access.**
- **Any client-side entitlement check.** The server sends 403 and omits the content.

## Open questions

**None.** Scope settled 2026-08-06; the component shape settled 2026-08-07.

## Test plan

**UI work, so the owner verifies on the running app.** `swiftlint lint` must report **0 violations**
before hand-off — it is at 0 today and this ticket must not be what breaks that.

What the owner should exercise:

1. **Open a bought class → tap a recipe.** Pictures, name, loyang, both components with their own
   ingredients and their own numbered method.
2. **The two components are unmistakably separate.** *Toping creamcheese* must not read as a
   continuation of *Brownies* — that merge is the specific failure this shape exists to prevent.
3. **`merk` is legible** — *Kunci Biru*, *Segitiga Biru*, *Bordeaux Tulip* — and the notes read
   correctly: *"Opsional"*, *"Dipakai DN (Owner)"*, *"Pewarna — hanya untuk varian red velvet"*.
4. **No portions row at all**, since this recipe has none. Loyang shows alone.
5. **No video anywhere**, no difficulty, no preparation time.
6. **Every recipe row in a bought class opens** — the stub cycles the fixture, so ids 12–16 resolve.
7. **A locked class still cannot reach this screen**, exactly as before.
8. **Back and forward twice**, then *Coba Lagi* on a failure. The `.id(route)` fix from DN-015 is
   what keeps a replaced route from showing the previous recipe.

## Done when

UI work:

- [x] Implemented on `ticket/DN-021-recipe-detail-ui`
- [x] `RecipePlaceholderView` / `RecipePlaceholderViewModel` deleted, and their §3 exemption struck
      from the known-violations table
- [x] `swiftlint lint` reports 0 violations
- [x] Previews cover loading, failed, two components, one unnamed component
- [ ] Verified manually by the human on the running app
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human

## Notes

**This screen is the product.** Everything shipped so far is the path to it.

**Ordering: DN-020 must land first** — this ticket cannot start without `GetRecipeUseCase`, and
`publish-spm.sh local` must be re-run from DN-020's branch so the app links a library that exports
`Recipe`.

Filed by the agent at `status: todo` on 2026-08-07 alongside DN-020. **Filing is autonomous;
scheduling is not.**

## Implementation notes (2026-08-07)

Six files under `Presentation/RecipeDetail/`, replacing the two placeholder files, which are deleted.

**The layout decision that matters:** ingredients and method are drawn **inside one section per
component**, not as one ingredient list followed by one method. That is the entire reason the owner
splits them — so a student can measure each component into its own bowl — and a merged layout would
throw the structure away at the last step, after the contract and the data layer had preserved it.

`merk` is rendered in the accent colour rather than as a grey footnote. It is commercial advice for
an audience cooking for income: which brand to buy, and which cheaper one still works.

**Two aligned columns** — quantity beside ingredient, number beside step — with fixed widths in
`DesignConstants`, so text lines up down the page instead of stepping in and out with each row.

**Portions and loyang draw nothing when absent.** This recipe genuinely has no portions, so the row
is not rendered at all rather than shown blank.

**Verified:** `swiftlint lint` → **0 violations**. `xcodebuild -scheme "DapurNaura Dev"` →
**BUILD SUCCEEDED**. Four previews plus two on `IngredientRow`.

**The last known violation is gone.** `RecipePlaceholderView`'s §3 exemption died with the file, which
is how a scoped exemption should end — removed with the thing it excused, not renewed or forgotten.

**One build failure worth recording, because it looked like a code error and was not.**
`RecipeDetailViewModel` failed to compile with *"value of type 'GetRecipeUseCase' has no member
'invoke'"* — while the SKIE-generated interface in the freshly built package clearly declared
`invoke(recipeId:) async throws`. The cause was Xcode's cached copy of the previous package build.
`xcodebuild clean` fixed it. **After `publish-spm.sh local` adds new API, clean before building** —
otherwise the error points at the Swift call site and hides the real cause.

**Not verified by me: the running app.** UI is the owner's gate.
