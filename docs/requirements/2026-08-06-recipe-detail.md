---
status: approved
date: 2026-08-06
author: owner
drafted-by: agent
approved: 2026-08-06
---

# Recipe detail

## Who this is for

Someone who has bought a cooking class and is now **cooking from one of its recipes** — most likely
with the phone on the kitchen counter, hands busy, reading as they go.

This is the screen the whole app exists to deliver. Everything before it — the class list, the class
detail — is navigation; this is the content the owner's students paid for.

## What they need

**Opening a recipe shows how to make it.** From the recipe list inside a bought class, choosing a
recipe opens that recipe in full.

The owner's instruction, given verbally in Bahasa Indonesia on 2026-08-06 and recorded here as the
agent's English translation per DN-010:

> "For the recipe detail — the page must have images, video not now, the recipe name; difficulty and
> prepTimeMinutes not now either; steps must be displayed."

Asked what else belongs on the page besides images, name and steps, the owner added **ingredients,
portions and loyang**.

### What the screen shows

- **the recipe's pictures** — the recipe carries more than one
- **the recipe name**
- **portions** and **loyang** — two separate pieces of information, never merged into one
- **the ingredients**, with their quantities, kept in their groups: a recipe is not one flat
  ingredient list. Where the source groups them (*Bahan A*, *Bahan B*) the screen keeps those
  groups and their names; ingredients that belong to no group are shown too. [ASSUMPTION] Ungrouped
  ingredients appear in an unlabelled section above the labelled groups — the owner specified that
  ingredients are shown, not how grouping is laid out.
- **the steps, in order**, as the numbered method to follow

### What is deliberately absent, for now

The owner's words were *"not now"* for each of these — they are deferred, not rejected:

- **the video**
- **`difficulty`**
- **`prepTimeMinutes`**

The steps therefore render as a plain ordered list. [ASSUMPTION] Each step already carries a
timestamp pointing into the video; that information is simply not used yet, and carrying it means
nothing has to change when the video arrives.

### Reaching this screen

A recipe can only be opened from a class the user has bought — that rule is set by the cooking-class
detail requirement, and this screen does not relax it. [ASSUMPTION] If this screen is ever reached
without entitlement, it shows an error rather than any part of the recipe; the protection is that
the server never sends the content, not that the screen hides it.

### Statements this can be checked against

- Opening a recipe from a bought class shows its pictures, its name, its portions, its loyang, its
  ingredients with quantities, and its steps in order.
- Ingredient groups survive: a recipe whose source has *Bahan A* and *Bahan B* shows two named
  groups, not one merged list.
- Ingredients with no group are still shown. [ASSUMPTION]
- Portions and loyang appear as two separate values.
- No video, no difficulty and no preparation time appear anywhere on the screen.

## Out of scope

- **Video playback** — deferred by the owner. Video hosting is also still undecided, and it is the
  one open decision that could still change the agreed data shape.
- **`difficulty` and `prepTimeMinutes`** — deferred by the owner, and the values do not exist yet.
- **Cooking aids** — timers, step check-off, keeping the screen awake, scaling quantities to a
  different number of portions. [ASSUMPTION] None were raised; a kitchen screen invites them, so
  they are named here to keep them out of this one deliberately rather than by omission.
- **Offline access.** [ASSUMPTION] Not raised by the owner.
- **Android.** [ASSUMPTION] Only the iOS app exists today.

## Open questions

**None.** The scope was settled in one exchange with the owner on 2026-08-06: images, name,
portions, loyang, ingredients and steps are in; video, difficulty and preparation time are *"not
now"*.
