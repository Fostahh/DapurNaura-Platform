# API contracts

**Status: `approved` (v1)** — approved by the owner on 2026-08-06.

Approved is not frozen. These are contracts, not requirements: they may still change while the UI
is built, and that is why they live here rather than in `docs/requirements/`. What "approved"
means is that DNLibrary and the UI may now be built against this shape without further sign-off.
A change after this point should be a deliberate, noted revision — not a silent edit.

These files are the **source of truth for the JSON shape**, used three times:

1. **Now, in the library** — DNLibrary's stub engine replays them, so the UI is built against the
   real serialization path with no backend.
2. **Now, over HTTPS** — a local Mockoon environment serves the same payloads to the Development
   build (DN-050), which exercises the transport the stub skips. It lives on the owner's machine and
   is committed nowhere, so **nothing keeps it in step with this directory but a person**.
3. **Later** — the backend is written to satisfy them.

They live here rather than in `docs/requirements/` deliberately: requirements are frozen once
approved, and this will change repeatedly while the UI takes shape.

> **Source of truth.** For *what was asked for*, `../requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

## Endpoints

| Endpoint | Returns | File |
|---|---|---|
| `GET /classes` | list of cooking classes; `?category=` narrows it to one category | `classes.json` |
| `GET /classes/{id}` | one class + its recipes | `class-detail-purchased.json` / `class-detail-pending.json` / `class-detail-locked.json` |
| `GET /recipes/{id}` | one recipe in full | `recipe.json` |
| `GET /offline-classes` | every scheduled in-person class, unnarrowed — the window is the client's rule (DN-035) | `offline-classes.json` |
| `GET /payment-destinations` | the bank accounts a class is paid into; no parameters (DN-047) | `payment-destinations.json` |

> **`offline-classes.json` was added by DN-035 and never listed here** — found and corrected during
> DN-047's sweep. The table is the index; a fixture missing from it is a fixture nobody knows to
> keep in step with the code.

**On `payment-destinations.json`:** the accounts are the business's, identical for every class and
every buyer, so the endpoint takes no parameters. **The numbers are dummy** by the owner's
instruction (requirement 2026-09-11) and follow each bank's real shape — Mandiri 13 digits, BSI 10.
Replacing them with the real accounts is a change to this file, not to any code. `bank` is a closed
set on the wire (`MANDIRI`, `BSI`): an unrecognised value fails the payload, because a bank the app
has no colour or logo for cannot be drawn at all.

## The rule that makes payment tamper-proof

`purchaseStatus` is a **UI hint, never a gate.** A client-side check is worthless — the user
controls the client and can flip any value.

**Protected content must be absent from the response, not hidden by it.**

| Status | `GET /classes/{id}` returns | `GET /recipes/{id}` |
|---|---|---|
| `NOT_PURCHASED` | metadata + recipe **names only** — no ingredients, steps or video | `403` |
| `PENDING_VERIFICATION` | same as above, plus payment reference | `403` |
| `PURCHASED` | everything | `200` |

A tampered `purchaseStatus` then unlocks nothing, because the payload never contained the content.
This is the only place the rule can be enforced. Do not add client-side checks and call it security.

## Why `purchaseStatus` is an enum, not `isPurchased: Boolean`

Payment is a bank/Midtrans transfer cross-checked by the server, so there is a real window between
paying and being unlocked. A boolean collapses that window and shows a paying customer the paywall
again — inviting a second transfer. The UI needs a distinct "waiting for confirmation" state.

## Revision 2026-08-08 — class category, and filtering by it (DN-024)

Requested by the owner on 2026-08-08 — see
[`../requirements/2026-08-08-cooking-class-category-filter.md`](../requirements/2026-08-08-cooking-class-category-filter.md).
A deliberate, noted revision of v1, which is what the *approved is not frozen* paragraph above
exists for.

**Every class carries a `category`**, and exactly one:

```json
"category": "BAKING"
```

| Value | Which sample class carries it |
|---|---|
| `MINUMAN` | Jajanan Pasar |
| `BAKING` | Makanan Kekinian |
| `COOKING` | Pastry Dasar |

The three sample assignments are the **owner's**, given on 2026-08-08. They are what the app is
verified against, so every category has exactly one class and no chip is dead on arrival.

**`GET /classes` accepts an optional `category` query parameter** — `GET /classes?category=BAKING`.

- **Omitted means every class**, in every category. It is not the same as an empty value.
- **The server does the filtering.** Owner's decision, 2026-08-08: the client does not fetch
  everything and narrow it locally, so this parameter — not the field — is what the class list
  actually uses.
- **A category with no classes is `200` with an empty `classes` array**, never `404`. An empty
  category is a normal answer, not a missing resource.
- Only the three values above are ever sent by the app.

**A `category` value the client does not recognise must not break the list.** The set of categories
belongs to the owner and may grow; an app already installed cannot be updated in step with the
server. So an unrecognised value decodes to *"no known category"* on that one class, and the class
still appears — where a strict enum would fail the whole payload and empty the screen. This is the
one place the client is deliberately tolerant.

**The field itself is not optional.** Tolerance covers unknown *values*, never an absent field: a
class with no `category` at all is a contract violation and is treated as one, exactly like a class
with no `name`. `purchaseStatus` keeps its strict enum for the same reason it always had one — its
three values are fixed by how payment works, not by what the owner decides to teach.

`class-detail-*.json` is **unchanged**. No screen shows a class's category, so the detail payload has
no reason to carry it; add it there when something needs it.

## Conventions

- **Ids are strings.** Costs nothing now and survives a switch to UUIDs later.
- **Prices are integer rupiah** — `150000` is Rp150.000. IDR has no minor unit in practice.
- **Array order is display order.** Steps and ingredients carry no explicit `order` field.
- **`videoTimestampSeconds` is nullable.** Not every step maps to a moment in the video.
- **Absent ≠ empty.** A locked class omits `ingredients`/`steps`/`videoUrl` entirely rather than
  sending empty arrays, so "locked" and "no data" stay distinguishable in the domain model.

## About the sample data (DN-011, 2026-08-06)

The *shape* below is the contract. The *values* are samples, and two owner decisions govern them:

- **Each class's `recipes` array holds exactly the `recipeCount` that `classes.json` advertises.**
  `classes.json` is the reference and is not edited to match the samples; the samples grow to match
  it. Where real content runs out, the existing recipes repeat in cycle — the 3rd repeats the 1st,
  the 4th the 2nd, and so on.
- **Repeated entries reuse the name, image, portions and loyang, but never the id.** Ids stay unique
  within a class, because no real API returns a duplicate id in one collection and a list UI needs
  them to tell rows apart.

`class-detail-pending.json` was added by DN-011 — `classes.json` has always listed Pastry Dasar as
`PENDING_VERIFICATION`, but no detail sample existed for it, so the one status with its own screen
treatment could not be exercised. Its recipe names (*Croissant*, *Danish Pastry*) are placeholders
invented with the owner's approval; there is no real content for that class yet.

## Settled at approval

- ~~**Ingredient grouping stays** — optional `group` per ingredient (*Bahan A* / *Bahan B*).~~
  **Revised 2026-08-07 by the owner, who supplied the first real recipe.** `group` is gone. It was
  the wrong shape: it separated an ingredient from the method that uses it, and the real structure
  is one level up.

  **A recipe is a list of `components`, and each component carries its own `ingredients` *and* its
  own `steps`.** Brownies Red Velvet has two: *Brownies* and *Toping creamcheese*. The owner's
  reason is the one that settles it — the split exists **so a student can prepare each component in
  its own bowl**. Ingredients and the method that consumes them must therefore travel together;
  a flat ingredient list with group labels cannot express that, and a flat step list cannot say
  which ingredients it draws on.

  A recipe with no natural split is **one component**, whose `name` may be `null` so the screen
  shows no heading. There is no separate "simple recipe" shape.

  An ingredient is `name`, `quantity`, optional `merk` (brand) and optional `note`. `merk` matters
  commercially — students are told which brand to buy, and which cheaper brand still works.
- **`videoTimestampSeconds` stays**, nullable, even though video is not yet in scope. Steps may
  render as a plain list for now; the field is carried so the contract does not change when the
  player arrives.

## Still open

- **Video hosting is undecided**, and it is the one thing that can still change this contract:
  a self-hosted or access-controlled provider means `videoUrl` becomes a short-lived **signed**
  URL, which cannot be cached and must be fetched per playback. Deferred by decision.
- **Image and video URLs are placeholders.** Real images come from the owner.
- **`difficulty` and `prepTimeMinutes`** are deliberately absent until the owner supplies them.
