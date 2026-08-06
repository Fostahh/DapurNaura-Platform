# API contracts

**Status: `approved` (v1)** — approved by the owner on 2026-08-06.

Approved is not frozen. These are contracts, not requirements: they may still change while the UI
is built, and that is why they live here rather than in `docs/requirements/`. What "approved"
means is that DNLibrary and the UI may now be built against this shape without further sign-off.
A change after this point should be a deliberate, noted revision — not a silent edit.

These files are the **source of truth for the JSON shape**, used twice:

1. **Now** — DNLibrary's stub engine replays them, so the UI is built against the real
   serialization path with no backend.
2. **Later** — the backend is written to satisfy them.

They live here rather than in `docs/requirements/` deliberately: requirements are frozen once
approved, and this will change repeatedly while the UI takes shape.

## Endpoints

| Endpoint | Returns | File |
|---|---|---|
| `GET /classes` | list of cooking classes | `classes.json` |
| `GET /classes/{id}` | one class + its recipes | `class-detail-purchased.json` / `class-detail-pending.json` / `class-detail-locked.json` |
| `GET /recipes/{id}` | one recipe in full | `recipe.json` |

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

- **Ingredient grouping stays** — optional `group` per ingredient (*Bahan A* / *Bahan B*).
- **`videoTimestampSeconds` stays**, nullable, even though video is not yet in scope. Steps may
  render as a plain list for now; the field is carried so the contract does not change when the
  player arrives.

## Still open

- **Video hosting is undecided**, and it is the one thing that can still change this contract:
  a self-hosted or access-controlled provider means `videoUrl` becomes a short-lived **signed**
  URL, which cannot be cached and must be fetched per playback. Deferred by decision.
- **Image and video URLs are placeholders.** Real images come from the owner.
- **`difficulty` and `prepTimeMinutes`** are deliberately absent until the owner supplies them.
