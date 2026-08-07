---
id: DN-020
type: product
title: Data layer — fetch one recipe in full, as a list of components
status: in-review
source: docs/requirements/2026-08-06-recipe-detail.md
branch: ticket/DN-020-recipe-detail-data
layer: data
---

## Requirement (traced)

From [`../requirements/2026-08-06-recipe-detail.md`](../requirements/2026-08-06-recipe-detail.md),
approved 2026-08-06:

> "Opening a recipe shows how to make it. From the recipe list inside a bought class, choosing a
> recipe opens that recipe in full."

> - **the recipe's pictures** — the recipe carries more than one
> - **the recipe name**
> - **portions** and **loyang** — two separate pieces of information, never merged into one
> - **the ingredients**, with their quantities […]
> - **the steps, in order**, as the numbered method to follow

Deferred by the owner, and therefore modelled but never surfaced: the video, `difficulty`,
`prepTimeMinutes`.

### Correction to the requirement — read this before the quote above

**The approved document is wrong about the shape of the ingredients, and it has not been edited.**
It carries `corrected-by: DN-019` in its frontmatter for exactly this reason.

It says ingredients are one flat list whose entries carry group labels (*Bahan A* / *Bahan B*).
Those labels were the agent's sample invention. On 2026-08-07 the owner supplied the first real
recipe and the true shape is one level up:

> "So this is one recipe. Sometimes one recipe can have several methods. The ingredients are split
> **to make it easier for the user to prepare them in separate bowls**."
>
> — owner, 2026-08-07, agent's English translation per DN-010

**A recipe is a list of components; each component carries its own ingredients *and* its own
method.** The owner's reason is what fixes it: the split exists so a student can measure each
component into its own bowl before starting. Ingredients and the method that consumes them therefore
have to travel together — group labels say what goes together but not what to *do* with each set.

**What survives from the requirement is the need**, which is still exactly right: *the parts of a
recipe must not be merged into one list.* Only the shape changed, and shape lives in
`docs/contracts/`, which is revisable by design.

The owner also added, the same day: an ingredient carries an optional **`merk`** (brand) and an
optional **`note`**. `merk` is commercial advice, not decoration — the audience is people learning to
cook for income, and the owner names both the brand to buy and the cheaper one that still works
(*"Procis oles untuk varian ekonomis"*, *"sesuaikan dengan harga jual"*).

## Context

Read before starting:

- **`docs/contracts/recipe.json`** — the approved shape and the **authority for this ticket's DTOs**.
  Revised 2026-08-07 from the owner's real recipe. Build against this file, never against the
  requirement's prose or against guesses.
- **`docs/contracts/README.md`** — the endpoint table, and *"The rule that makes payment
  tamper-proof"*: `GET /recipes/{id}` returns **403** unless the class is `PURCHASED`. Content is
  absent from the payload, not hidden by the client.
- **`docs/tickets/DN-011-product-cooking-class-detail-data.md`** — the closest sibling. Same shape of
  work, one level down. Match its DTO/domain split and its test structure rather than inventing new
  ones.
- **`DNLibrary/docs/CODEBASE-ARCHITECTURE.md`** §1–§3 — layering, DTOs `internal`, domain models
  `public`, typed errors. §2: the public API is a binary contract.

Already true, and constraining:

- **`portions` no longer signals "locked".** Owner's decision, 2026-08-07: it means *no value*, and
  whether a class is locked is answered by `purchaseStatus` alone. Brownies Red Velvet genuinely has
  no portions value, in a class that **is** bought. Do not reintroduce the old reading — it is now
  contradicted by the fixture.
- **`recipe.json` is the only recipe fixture.** Owner's decision, 2026-08-07: the stub **cycles** it
  for every other recipe id, reusing the content under the requested id, so every row in a bought
  class opens. This mirrors what `class-detail-*.json` already does with repeated recipes.
- **`videoTimestampSeconds` is carried and never surfaced.** Video is deferred; carrying the field
  means the contract does not change when a player arrives.
- **There is no backend.** Everything runs through `StubRemoteDataSource`.

## Technical approach

**Domain models** — `domain/model/Recipe.kt`, all `public`:

```kotlin
public data class Recipe(
    val id: String,
    val classId: String,
    val name: String,
    val images: List<String>,
    val portions: String?,      // null = no value. NOT a lock signal — see purchaseStatus
    val loyang: String?,
    val videoUrl: String?,      // carried, not surfaced until video ships
    val components: List<RecipeComponent>
)

public data class RecipeComponent(
    val name: String?,          // null = a recipe with no natural split; no heading is shown
    val ingredients: List<Ingredient>,
    val steps: List<RecipeStep>
)

public data class Ingredient(
    val name: String,
    val quantity: String,
    val merk: String?,
    val note: String?
)

public data class RecipeStep(
    val text: String,
    val videoTimestampSeconds: Int?
)
```

**Use case** — `GetRecipeUseCase`, sealed result in the shape DN-008/DN-011 established:
`RecipeResult.Success(recipe)` / `RecipeResult.Failure(DNError)`. Exposed through `DNDataLayer`.

**Wire layer** — `internal` DTOs in `network/responses/RecipeResponse.kt` mirroring the contract,
plus mappers. `RemoteDataSource.getRecipe(id)` performs `GET {baseUrl}/recipes/{id}`.

**Stub** — `StubRemoteDataSource` replays `recipe.json` through the real decoding path, **cycling it
for any requested id**: the returned `Recipe.id` is the id that was asked for, everything else is the
fixture's. Ids stay unique per request, which is what a list UI needs.

**Nullability is per field, and it is meaning.** `name` and `quantity` are non-null; `merk`, `note`,
`portions`, `loyang`, `videoTimestampSeconds` and `RecipeComponent.name` are nullable and their
absence is information. A DTO must not coerce an absent value into `""` — that would make "the owner
gave no brand" indistinguishable from "the brand is blank".

## Public API contract

**Added:** `Recipe`, `RecipeComponent`, `Ingredient`, `RecipeStep`, `GetRecipeUseCase`,
`RecipeResult` and its cases, `DNDataLayer.getRecipe`.

**Changed:** nothing. **Removed:** nothing.

**Version bump implied: minor** — purely additive, so no consumer breaks.

## Out of scope

- **The screen.** DN-021.
- **Video playback**, `difficulty`, `prepTimeMinutes` — deferred by the owner. `videoUrl` and
  `videoTimestampSeconds` are carried in the model and surfaced nowhere.
- **Enforcing entitlement client-side.** The server returns 403 and omits the content. A client-side
  check would be security theatre — `docs/contracts/README.md` says so explicitly.
- **Real content for other recipes.** *Cheese Cake*, *Croissant* and the rest have no written recipe.
  The stub cycles Brownies; that is a fixture decision, not a product one.
- **A `recipes` endpoint returning many.** Only `GET /recipes/{id}`.

## Open questions

**None.** The shape was settled with the owner on 2026-08-07, and the four content questions
(red velvet colouring at 2 tetes, butter quantities, *"DN (Owner)"*, no portions) were answered the
same day.

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`, both platforms green. **Report counts read from
the test-result XML**, not inferred from `BUILD SUCCESSFUL`.

1. **The real fixture decodes.** `recipe.json` → a `Recipe` with **2 components**; *Brownies* has 6
   ingredients and 4 steps, *Toping creamcheese* has 7 and 6.
2. **Components keep ingredients with their own method.** Assert the topping's ingredient list
   contains creamcheese and *not* dark chocolate — the failure this ticket exists to prevent is a
   merge back into one list.
3. **Order is preserved**, for components, ingredients and steps. A method read out of order is
   wrong in a way a kitchen notices.
4. **`merk` and `note` survive as separate values**, and are `null` where the fixture has null —
   never `""`.
5. **`portions` is null and that is not an error.** Explicitly assert this recipe has no portions
   while its class is `PURCHASED`, so the old "null means locked" reading cannot come back unnoticed.
6. **The stub cycles.** Requesting id `13` returns the Brownies content **with `id == "13"`**.
7. **Failure maps to `DNError`** on the same paths DN-008/DN-011 already cover.
8. **A malformed payload fails as `DNError.Contract`**, not as an exception crossing the boundary.

## Done when

Data-layer work:

- [x] Implemented on `ticket/DN-020-recipe-detail-data`
- [x] Unit tests written and passing — `./gradlew :sharedLogic:check`, counts read from XML
- [x] `CODEBASE-ARCHITECTURE.md` known-violations table checked
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human
- [ ] Library published and the app bumped off the local package

## Notes

**This is the level of the domain the product actually sells.** The class list and the class detail
are navigation; this is the content students paid for.

**It is also the first ticket whose `source:` points at a requirement known to be partly wrong.**
That is safe only because of what DN-019 put in place: the requirement carries `corrected-by:`, the
corrected shape lives in `docs/contracts/recipe.json`, and every document now states that where the
requirement and reality disagree the correction is recorded in the ticket. The correction is in
`## Requirement (traced)` above rather than hidden in an implementation note, so anyone reading this
ticket top to bottom meets it before the quote it modifies.

Filed by the agent at `status: todo` on 2026-08-07. **DN-020 must land before DN-021.**

## Implementation notes (2026-08-07)

**Delivered as specified.** `Recipe` → `components[]` → `ingredients[] + steps[]`,
`GetRecipeUseCase`, `RecipeResult`, `DNDataLayer.getRecipe`, internal DTOs and mappers, and the stub
cycling `recipe.json` under whatever id is asked for.

**Verified:** `./gradlew :sharedLogic:check` → **103 tests, 0 failures, 0 errors** (52 Android host,
51 iOS simulator; 4 skipped on iOS, pre-existing keychain cases). Up from 89 — the 14 new results are
this ticket's 7 tests across both platforms, and each was confirmed present by name in the
test-result XML rather than inferred from the count.

### Two stale copies of the contract were found and fixed

The contract lives in `docs/contracts/`, but two places embed **verbatim copies** of it, and both had
drifted the moment `class-detail-purchased.json` was revised:

- `StubRemoteDataSource.kt` — its comment already says *"verbatim copies … if the contract is
  revised, these are revised with it"*, so this was the documented obligation being honoured.
- `GetCookingClassDetailUseCaseTest.kt` — a second copy, feeding `MockEngine`. **This one is the
  more dangerous of the two**: it kept passing precisely because it was stale, so the suite was
  green while testing a fiction.

### A test that asserted a rule the owner had overturned

`aPurchasedClassDecodesWithPortionsAndLoyangOnEveryRecipe` ended with
`detail.recipes.forEach { assertNotNull(it.portions) }` — the "null portions means locked" reading,
written into an assertion. The owner overturned that on 2026-08-07, and the first real recipe is the
counter-example: no portions at all, in a class that **is** bought.

Renamed to `aPurchasedClassDecodesPortionsAndLoyangAsTwoSeparateValues`, and it now asserts what is
actually true — a bought class carries recipes both with and without portions. `DNDataLayerStubTest`
carried the same assumption and got the same treatment.

**This is the argument for the new test in this ticket** — *a null portions is not an error and does
not mean locked*. Two tests had quietly encoded the old rule; the new one exists so a third cannot,
because it fails loudly if anyone reintroduces the reading.

**Local package rebuilt** with `publish-spm.sh local ../ios/DapurNaura debug`, and the SKIE bridge
verified in the generated interface: `invoke(recipeId:) async throws -> any RecipeResult`.
