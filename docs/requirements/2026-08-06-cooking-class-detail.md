---
status: approved
date: 2026-08-06
author: owner
drafted-by: agent
approved: 2026-08-06
---

# Cooking class detail

## Who this is for

Someone using the Dapur Naura app who wants to know what a cooking class actually contains.

Three people arrive at this screen, and they must not be treated the same way:

- **A user who has bought the class**, wanting to reach the recipes they paid for.
- **A user who has paid but whose payment has not been confirmed yet**, wanting to know their money
  arrived.
- **A user who has not bought it**, deciding whether it is worth buying. [ASSUMPTION] The owner did
  not describe this person directly; they follow from the decision to include unbought classes.

## What they need

**Opening a class shows what is inside it.** From the list of cooking classes, choosing one opens a
screen for that class, showing the class itself and the recipes it teaches. The owner refers to this
screen as *"halaman list resep"* — the recipe-list page. It is the same screen; there is not a
separate one.

The owner's instructions, given verbally in Bahasa Indonesia on 2026-08-06 and recorded here as the
agent's English translations per DN-010:

> "I want the user to be able to see the detail of a cooking class, which contains a list of the
> recipes available in that cooking class. As for how it looks, for now I leave that to you — what
> you think is best for this."

> "If the cooking class status is already purchased, then there is no buy button on the recipe list
> page, and the recipes can be tapped and move to the recipe detail page. Otherwise, show the buy
> button, and the recipes cannot be tapped and cannot move to the recipe detail page."

> "Oh right — in case double payment happens, for the awaiting-verification status the buy button
> is not shown either."

The visual design is explicitly delegated to the agent and is not specified here.

### What every class shows, whatever its status

- the class name, its picture, and its description — [ASSUMPTION] the owner said "detail kelas"
  without naming individual pieces of information; these are the agent's reading of it
- **the list of recipes in the class** — the part the owner named explicitly — each showing its
  name and its picture, in the order the server sends them

**No count of recipes is shown.** The owner's reason: this screen already lists every recipe the
class contains, so a number adds nothing.

### What changes with purchase status

| The user… | Buy button | Price | Choosing a recipe |
|---|---|---|---|
| **has bought** the class | not shown | not shown | opens that recipe |
| **has paid, awaiting confirmation** | not shown — a short note says the payment is being checked | not shown [ASSUMPTION] | does nothing |
| **has not bought** the class | shown, and carries the price | on the button | does nothing |

**The buy button reads `Beli Kelas · Rp125.000`** — the class name of the action, then that class's
own price. Choosing it does not buy anything: it shows a short message that buying inside the app is
not available yet, and that is all. Owner's decision, 2026-08-06: the place for it is prepared now,
even though payment itself is deferred, and the wording is already the final wording so only the
behaviour changes when payment arrives.

Because the price rides on the button, it is not repeated elsewhere on the screen. [ASSUMPTION] The
owner chose this variant knowing the price would otherwise appear twice.

**The awaiting-confirmation note says only that the payment is being checked** — no reference
number, no date, nothing else about the transaction. Owner's decision, 2026-08-06. This matters
beyond the screen: it means the existing contract already carries everything this requirement needs,
and no contract revision is required to build it.

**Why the awaiting-confirmation case has no buy button.** The owner's own reason: to avoid a double
payment. A user who has already transferred money and is then shown a buy button may conclude the
transfer failed and send it a second time. This is the reason that state is distinguished from
"not bought" at all.

### What a bought class shows in addition

Each recipe in the list also shows its **portions** and its **loyang**. [ASSUMPTION] These are two
separate pieces of information and must never be merged into one.

### Recipes are selectable only when the class is bought

In a bought class, choosing a recipe opens that recipe. In every other case a recipe cannot be
chosen and leads nowhere.

**What the recipe screen itself contains is not specified here** — it is the subject of the
requirement written after this one. Owner's decision, 2026-08-06. This requirement settles only
which recipes can be opened and which cannot.

### Statements this can be checked against

- In a bought class: no buy button, no price, every recipe shows its portions and its loyang, and
  choosing a recipe opens it.
- In an awaiting-confirmation class: no buy button and no price anywhere on the screen, a note that
  the payment is being checked, and choosing a recipe does nothing.
- In an unbought class: a button reading `Beli Kelas · Rp125.000` is present, choosing it never
  completes a purchase, and choosing a recipe does nothing.
- No recipe count appears on the screen in any state.
- In any class that is not bought, the ingredients, the method and the video are **absent from the
  screen and absent from the data behind it** — not merely hidden. A user who tampers with the app
  gains nothing, because the content was never sent.

## Out of scope

- **What the recipe screen shows** — ingredients, method, video. Owner's decision: the next
  requirement. Only the ability to open it is settled here.
- **Actually buying a class.** Payment is deferred; the button is a placeholder.
- **`difficulty` and `prepTimeMinutes`** — deferred until the owner supplies the values.
- **Offline access or caching.** [ASSUMPTION] Not raised by the owner.
- **Searching or filtering recipes within a class.** [ASSUMPTION] Not raised by the owner.
- **Android.** [ASSUMPTION] Only the iOS app exists today.

## Open questions

**None.** Four were raised while drafting and all were settled by the owner on 2026-08-06:

| Question | Settled as |
|---|---|
| Does the buy button appear while a payment is awaiting confirmation? | **No** — the owner's reason was the risk of a double payment |
| Does the awaiting-confirmation state need data the contract does not carry yet? | **No** — a short note only, so the contract stands unchanged |
| Should a recipe count be shown? | **No** — the screen already lists every recipe |
| What should the buy button say? | `Beli Kelas · Rp125.000` |
