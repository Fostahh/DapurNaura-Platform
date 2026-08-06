---
id: DN-011
type: product
title: Data layer — fetch one cooking class with its recipes
status: in-review
source: docs/requirements/2026-08-06-cooking-class-detail.md
branch: ticket/DN-011-cooking-class-detail
layer: data
---

## Requirement (traced)

From [`docs/requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md)
(approved 2026-08-06) — the parts this ticket is responsible for:

> "**the list of recipes in the class** — the part the owner named explicitly — each showing its
> name and its picture, in the order the server sends them"

> Each recipe in the list also shows its **portions** and its **loyang**. […] These are two separate
> pieces of information and must never be merged into one.

> In any class that is not bought, the ingredients, the method and the video are **absent from the
> screen and absent from the data behind it** — not merely hidden.

The three purchase states each produce a different screen, so the data layer must carry the status
and must carry it faithfully — see the requirement's status table.

**This is the first ticket in this workspace to trace to a real requirement document.** DN-008 and
DN-009 quoted verbal instructions because no document existed; that gap is now closed, and `source:`
above is a genuine link rather than a flagged deviation.

## Context

Read before starting:

- [`../requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md)
  — the whole thing; it is short and it is frozen
- [`../contracts/class-detail-purchased.json`](../contracts/class-detail-purchased.json) and
  [`../contracts/class-detail-locked.json`](../contracts/class-detail-locked.json) — the payloads
- [`../contracts/README.md`](../contracts/README.md) — **"Absent ≠ empty"**: a locked class omits
  `ingredients`/`steps`/`videoUrl` entirely rather than sending empty arrays. Array order is display
  order. `purchaseStatus` is a UI hint, never a gate.
- `DN-008-product-cooking-class-list.md` — the vertical-slice pattern this repeats exactly
- `DN-009-product-cooking-class-list-ui.md` — the stub path (`DNDataLayer.stub()`) this extends
- `DNLibrary/CODEBASE-STANDARD.md` §1–§3 — layering, DTOs `internal`, domain models `public`,
  sealed results, never throw across the boundary

Already true, and constraining:

- **Locked recipes carry fewer fields than purchased ones.** `class-detail-purchased.json` gives
  each recipe `portions` and `loyang`; `class-detail-locked.json` gives neither. The DTO must make
  them nullable, and the domain model must keep "absent" distinguishable from "empty".
- **There is no `PENDING_VERIFICATION` detail sample.** `classes.json` lists Pastry Dasar (id `2`)
  in that state, but no detail file exists for it — so the stub cannot currently produce the state
  the requirement gives its own screen treatment to. Addressed below.
- This stacks on the DN-008 → DN-009 DNLibrary branch chain, which is still unmerged.

## Technical approach

### 1. Contract sample maintenance (`docs/contracts/`)

Folded into this ticket rather than filed separately: these files are this ticket's own test
fixtures, and a ticket that edits JSON purely so the next ticket can consume it is ceremony, not
work. Both changes are **sample-data** changes — the agreed *shape* does not move, so this is not a
contract revision in the sense `contracts/README.md` guards against.

- **Add `class-detail-pending.json`** — Pastry Dasar, id `2`, `purchaseStatus:
  "PENDING_VERIFICATION"`, recipe names and images only. Identical in shape to the locked sample:
  the requirement settled that this screen shows only a short "payment is being checked" note, so
  **no payment-reference field is needed** and the contract shape stands unchanged.
- **Expand the detail samples so each class holds exactly its `recipeCount`.** Owner's decision,
  2026-08-06: `classes.json` is the reference and **is not edited** — the detail samples grow to
  match it, by repeating the recipes that already exist in cycle. The owner's own wording: if only
  2 exist and the count is 5, then the 3rd repeats the 1st, the 4th repeats the 2nd, the 5th
  repeats the 1st.

  | Class | `recipeCount` | Detail sample becomes |
  |---|---|---|
  | `1` Makanan Kekinian (purchased) | 6 | Brownies / Cheese Cake, cycled 3× — with `portions` and `loyang` |
  | `2` Pastry Dasar (pending) | 4 | Croissant / Danish Pastry, cycled 2× — names only |
  | `3` Jajanan Pasar (locked) | 8 | Klepon / Risoles, cycled 4× — names only |

  **Ids stay unique while the content repeats** — owner's decision. A repeated entry reuses the
  name, image, portions and loyang, but takes the next id (`11, 12, 13, 14, 15, 16`). Two rows
  sharing an id would break list identity in SwiftUI, and no real API returns a duplicate id in one
  collection.

  **`[ASSUMPTION]` Croissant and Danish Pastry are invented placeholder names.** Pastry Dasar has no
  recipe content anywhere in the repo — `recipe.json` covers only Brownies — and it is the only
  sample carrying `PENDING_VERIFICATION`, so it could not simply be left out. The owner approved
  inventing them and can replace them at any time; images stay `placehold.co` like every other
  sample.
- Note the new file in `contracts/README.md`'s endpoint table.

**No ripple into DN-008.** Because `classes.json` is untouched, DN-008's fixture — which quotes it
verbatim — does not move, and its tests keep passing unchanged.

### 2. The slice (`DNLibrary/sharedLogic`)

Repeats DN-008's pattern exactly; nothing here is a new idea.

- **DTOs (`internal`)** — `ClassDetailResponse`, `RecipeSummaryResponse`. `portions` and `loyang`
  are **nullable**, everything else non-null, matching the contract.
- **Domain models (`public`)** — `CookingClassDetail` (the class plus its recipes) and
  `RecipeSummary` (`id`, `name`, `imageUrl`, `portions: String?`, `loyang: String?`). Nullable
  stays nullable: *absent ≠ empty*, and the UI needs to tell the two apart.
- **Sealed result (`public`)** — `CookingClassDetailResult.Success/Failure`, reusing the existing
  `DNError`. Concrete, not generic, per §2.
- **Data source (`internal`)** — `GET {baseUrl}/classes/{id}`, same `X-Api-Key` header as DN-008.
- **Repository (`internal`)** — DTO → domain, exceptions → `DNError`. Nothing throws past it.
- **Use case (`public`)** — `GetCookingClassDetailUseCase`, taking the class id.
- **`DNDataLayer`** exposes it alongside `getCookingClasses`.
- **`StubRemoteDataSource`** replays the three detail samples by id (`1` purchased, `2` pending,
  `3` locked), through the real decoding path, with the same simulated latency as DN-009.

## Public API contract

Added: `CookingClassDetail`, `RecipeSummary`, `CookingClassDetailResult`,
`GetCookingClassDetailUseCase`, and its accessor on `DNDataLayer`. Nothing is removed or renamed.

**Version bump implied:** **minor** under `0.x` — purely additive on top of DN-008/DN-009.

## Out of scope

- **`GET /recipes/{id}` and the recipe screen** — the requirement defers it explicitly to the next
  requirement document.
- **All iOS UI** — DN-012.
- **Payment, entitlement enforcement.** Enforcement is server-side by contract design; the client
  never gates on `purchaseStatus`.
- **Expanding the detail samples to their full recipe counts** — needs content from the owner.
- **Replacing the stale `API_BASE_URL`** in the xcconfigs — still needs a real backend.

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`. Fixtures quote the contract files verbatim (§6),
driven through the factory + `MockEngine`:

1. The purchased payload decodes — **6** recipes, in contract order, each with `portions` **and**
   `loyang` populated and distinct
2. The locked payload decodes — **8** recipes, `portions` and `loyang` **null**, proving absent
   survives as absent rather than becoming `""`
3. The pending payload decodes — **4** recipes, `purchaseStatus = PENDING_VERIFICATION`
4. Every recipe id within a single class is unique, even where the name and image repeat — the
   property the repeated sample data exists to exercise
5. Each class's recipe list length equals the `recipeCount` `classes.json` advertises for it
6. The request path is `/classes/{id}` with the id interpolated, and carries the API key header
7. HTTP 404 → `Failure(Http(404))`; HTTP 500 → `Failure(Http(500))`
8. Malformed JSON → `Failure(Contract)`; a missing required field → `Failure(Contract)`
9. A connection failure → `Failure(Network)`
10. `DNDataLayer.stub()` returns each of the three states for ids `1`, `2` and `3`
11. DN-008's existing list tests stay green — `classes.json` is untouched, so its fixture does not
    move

## Implementation notes (2026-08-06)

- **The gate is green on both platforms**, and the counts were read from the test-result XML
  rather than trusted from "BUILD SUCCESSFUL":

  | | before | after |
  |---|---|---|
  | Android host | 21 tests, 0 skipped | **35 tests**, 0 skipped, 0 failures |
  | iOS simulator | 20 tests, 4 skipped | **34 tests**, 4 skipped, 0 failures |

  The 4 skipped are the pre-existing `@Ignore`d Keychain cases — the hostless iOS test process has
  no keychain. The 14 new tests are `GetCookingClassDetailUseCaseTest` (11) and three additions to
  `DNDataLayerStubTest`, and both suites appear in **both** platforms' XML, so nothing silently
  ran nothing.
- **`explicitApi()` was verified, not assumed** — `sharedLogic/build.gradle.kts:14`. The playbook
  names this exact claim as one that was once false in this workspace.
- **Three refactors of DN-008 code, each to avoid duplicating something at the second endpoint.**
  They change no behaviour and are covered by DN-008's untouched tests, which stay green:
  1. `PurchaseStatusResponse.toDomain()` extracted — the three-branch `when` would otherwise be
     written twice.
  2. `Throwable.toDNError()` extracted in the repository — the six-clause catch ladder would
     otherwise be written twice, and a second copy is how two endpoints drift into different error
     vocabularies. `CancellationException` is still rethrown before the generic catch.
  3. `RemoteDataSource` gained `url()` and `authenticate()` helpers, so the base-URL trimming and
     the API-key header exist once rather than per endpoint.
- **An unknown class id in the stub throws** (`NoSuchElementException` → `DNError.Unknown`) rather
  than returning a plausible class. The real endpoint would 404, and a stub that invents data hides
  a broken navigation path — which is exactly what DN-012 will be exercising.
- **Naming for the Swift side:** `CookingClassDetail`, `RecipeSummary`,
  `CookingClassDetailResult`, `DNDataLayer.getCookingClassDetail(classId)`. `RecipeSummary` is
  deliberately not `Recipe` — the full recipe is a different model arriving with the recipe-detail
  requirement, and two types called the same thing would be worse than a slightly long name.
- **Nothing is committed.** The branch was cut from `ticket/DN-009-cooking-class-list-ui` (the tip
  in DNLibrary, still unmerged), so the stack is now
  DN-001 → DN-002 → DN-004 → DN-006 → DN-008 → DN-009 → **DN-011**.
- **Flagged for commit time:** the contract samples this ticket edits live in the *umbrella* repo,
  which is still sitting on `ticket/DN-010-bilingual-prompt-protocol` with DN-010's uncommitted
  docs. Nothing is lost — but the umbrella commits must be split deliberately: DN-010's docs on the
  DN-010 branch, the contract samples and this ticket file on a DN-011 branch.

## Done when

Data-layer work:
- [x] Contract samples added/corrected; `contracts/README.md` notes them
- [x] Slice implemented as above; `explicitApi()` clean
- [x] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [x] Committed, not merged — DNLibrary `7ffc189`, umbrella `56093f8`, both on
      `ticket/DN-011-cooking-class-detail`

Always:
- [ ] PR merged, ticket marked `done` by the human
