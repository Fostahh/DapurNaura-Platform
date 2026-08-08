---
status: approved
date: 2026-08-08
author: owner
drafted-by: agent
approved: 2026-08-08
---

# Filtering the cooking-class list by category

## Who this is for

Someone browsing the Dapur Naura class list who is only interested in one kind of class — they want
to drink-making classes, or only baking, without reading past the rest.

[ASSUMPTION] The owner described the feature, not the person. This is the agent's reading of who
benefits.

## What they need

**The class list can be narrowed to one category, and widened back to everything.**

The owner's instruction, given in Bahasa Indonesia on 2026-08-08 and recorded here as the agent's
English translation per DN-010:

> "Please build a feature to filter the cooking-class list by category. This category is new data,
> and it needs a change to its contract.
>
> Cooking classes are categorised into 3:
> 1. Minuman
> 2. Baking
> 3. Decor
>
> The filter takes the form of a Chip View, and its position is below the screen title and above the
> cooking-class list."

**Corrected by the owner the same day**, minutes later, when the agent asked which categories the
sample classes should carry:

> "I want a correction — the categories are MINUMAN, BAKING, COOKING. Makanan Kekinian is BAKING,
> Pastry goes to COOKING, Jajanan Pasar goes to MINUMAN."

**The three categories are therefore MINUMAN, BAKING and COOKING.** `Decor` from the first statement
is not a category. Both statements are kept above deliberately: this document is the record of what
was asked, and the correction is part of that record rather than a reason to rewrite it.

### The categories

There are exactly three, and **a class belongs to exactly one** of them — not none, not several.
Owner's decision, 2026-08-08.

| Category | What the user sees on the chip |
|---|---|
| `MINUMAN` | Minuman |
| `BAKING` | Baking |
| `COOKING` | Cooking |

[ASSUMPTION] The owner wrote the three names as capitalised identifiers. The chip wording above is
the agent's reading of how they should read to a user, and `Cooking` in particular is open — see
`## Open questions`. Per the platform rule, no category name is translated into English or out of
Bahasa Indonesia by the agent.

### The filter itself

- **It is a row of chips**, placed **directly below the screen title (*Kelas Masak*) and directly
  above the list of classes**. The owner specified both the form and the position.
- **One chip is active at a time**, and there is an additional chip for *everything* labelled
  **`Semua`**, which comes first and is what the screen opens on. Owner's decision, 2026-08-08.
  Choosing a category narrows the list; choosing `Semua` returns to the full list.
- **The chips are always reachable.** Whatever the list below is doing — loading, showing classes,
  or showing a failure — the user can still change or clear the filter. This matters because of the
  approach decision below: changing category re-requests the list, and a filter the user cannot
  undo while that request is in flight is a trap.
- **A category with no classes says so** rather than showing a blank screen. [ASSUMPTION] The owner
  did not raise the empty case; the agent's wording is *"Belum ada kelas di kategori ini."*

### Approach decisions the owner made

Recorded because they came from the owner, not the agent. They are *how* rather than *what*, and
they would normally live in a ticket — but an owner decision that is nowhere in writing gets
re-decided by the next session, so it is written here and the tickets trace to it.

- **The filtering is done by the server**, per category, rather than by the app over a list it has
  already fetched. Owner's decision, 2026-08-08, chosen over app-side filtering.
- **The category is new data on a cooking class, and the contract changes to carry it.** The owner
  said this in the instruction above. The wire shape itself belongs in `docs/contracts/` and is
  deliberately not described here.

Consequences the owner should expect, stated so approval is informed: **each chip tap is a network
request**, so the list area shows its loading state again on every change, and a category can fail
to load on its own. Before a backend exists this is exercised against the contract fixtures, which
means the stub has to do the filtering the server will later do.

### Statements this can be checked against

- The class list screen shows a row of chips between the title *Kelas Masak* and the list.
- The chips are `Semua`, `Minuman`, `Baking`, `Cooking`, in that order, and the screen opens with
  `Semua` active and every class listed.
- Exactly one chip is active at any moment.
- Choosing `Baking` leaves only baking classes in the list; choosing `Semua` again restores all of
  them.
- Every class in the list belongs to one category, so no class is missing from all three
  category-filtered lists, and none appears in two of them.
- Changing the chip while the list is still loading works, and the list that finally appears matches
  the chip that is active — not an earlier one.
- A category with no classes shows a short message saying so, not an empty screen and not a spinner.

## Out of scope

- **Searching classes by name**, and filtering by price or by purchase status. [ASSUMPTION] Not
  raised by the owner.
- **Remembering the chosen category between app launches** — every launch opens on `Semua`.
  [ASSUMPTION] Not raised by the owner.
- **Filtering the recipes inside a class.** [ASSUMPTION] Not raised; the class detail screen is
  unchanged by this.
- **Any screen for the owner to create, rename or reorder categories.** The three are fixed in this
  requirement. [ASSUMPTION] Not raised.
- **Showing a class's category anywhere other than the filter** — for example as a badge on each
  row. [ASSUMPTION] Not raised by the owner; the data will be there if it is wanted later.
- **Android.** Only the iOS app exists.

## Open questions

| Question | Why it is open |
|---|---|
| **Does the third chip read `Cooking` to the user, or something else?** | The owner supplied the three names as identifiers. `Minuman` is Bahasa Indonesia while `Baking` and `Cooking` are English words used in Indonesian kitchens, and the agent must not decide the user-facing wording of app content. |
| **Can a fourth category be added later?** | The owner named three. If more can arrive, the app must tolerate a category it has never heard of — otherwise a new one shipped by the server would break the class list on every phone already installed. The agent's plan is to build that tolerance in regardless, but whether growth is *expected* changes whether the owner needs a way to manage categories at all. |
