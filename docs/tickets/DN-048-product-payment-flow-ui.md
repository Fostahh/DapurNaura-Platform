---
id: DN-048
type: product
title: iOS — choosing a bank account and sending proof of payment
status: todo
source: ../requirements/2026-09-11-payment-flow.md
branch: ticket/DN-048-payment-flow-ui
layer: ui
---

## Requirement (traced)

From [`2026-09-11-payment-flow.md`](../requirements/2026-09-11-payment-flow.md), approved
2026-09-11. The whole document is this ticket's specification; what follows is what shapes the
build.

On the journey:

> "On the card there is an icon which, when pressed, copies the account number shown. Then a toast
> appears saying the account number has been copied, and navigates to the next screen, which has a
> button to upload proof of payment."

On the end of it:

> "After the send button is pressed, it will pop back to the class page and refresh that page,
> because the status should change from notPurchased to pendingVerification."

And on what that means today:

> "For now there is no need to build the API call. Just pop to the screen from before the payment
> flow happened."

**The layout of the second screen is the agent's proposal, approved by the owner on 2026-09-11
after seeing it drawn** — the requirement records that distinction and this ticket inherits it. It
is a starting point the owner may revise on a device, not a specification to defend.

## Context

Read before starting:

- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §2 ViewModel contract, §3 layout, §4 navigation,
  §7 states
- `.../Presentation/Cookings/CookingsFlowView.swift` — owns the stack these screens push onto
- `.../Presentation/Cookings/CookingClassDetail/Components/PurchaseSection.swift` — the *Beli Kelas*
  button, which currently raises a "not available" alert and is the entry
- `.../Presentation/Components/Toast.swift`, `ToastKind.swift`, `ToastMessage.swift` — built by
  DN-040, reused here rather than rebuilt
- `docs/tickets/DN-046-technical-camera-usage-description.md` — **must be merged first**, or opening
  the camera terminates the app

**These screens are pushed, not a flow module.** §3's rule is that a folder earns the flow-module
tier by being a presentation context entered by a root swap or a modal; payment is neither. It is
two routes on the `Cookings` stack, which is exactly what *"pop back"* requires.

## Technical approach

### Where the files go

Two feature folders under the existing flow, per §3's `<Flow>/<Feature>/` layout:

```
Presentation/Cookings/
  PaymentDestination/     PaymentDestinationView / Content / ViewModel, PaymentRoute
  PaymentProof/           PaymentProofView / Content / ViewModel
```

`PaymentRoute` carries both cases and is wrapped by `Route` like every other feature enum. It lives
with `PaymentDestination`, the screen the flow is entered at.

### Screen one — the destinations

**A real fetch, so a real three-state screen** (§2, §7): loading, loaded, failed. It calls
`GetPaymentDestinationsUseCase` from DN-047 and renders what comes back. **It does not hard-code two
cards** — the list is data, and a third account appearing later must not need this screen edited.

**The bank's colour and logo are chosen here**, by switching on `Bank`. DN-026's rule: a colour is a
decision about this surface, so it stays in Swift. The logo is an asset for the same reason.

**The logo is a placeholder until the owner supplies the files.** Owner's decision, 2026-09-11 —
recorded in the requirement. Shipping with the placeholder is the choice, not an unfinished edge.

**Pressing copy does three things in order** (requirement): copies the number, shows the toast
*Nomor rekening tersalin*, then pushes screen two carrying the destination that was copied.

### Screen two — the proof

**No fetch, so no `State` enum** — the same absence DN-033 and DN-040 recorded, for the same reason:
§7's three states are the outcomes of loading something, and this screen loads nothing. **It is not a
precedent for skipping one on a screen that fetches.**

What the ViewModel holds: the chosen image, the compressed bytes, and whether a send is in progress.

**The picker offers the library and the camera** (requirement). `PhotosPicker` for the library,
which needs no permission; a camera sheet for the other, which needs DN-046.

> **What happens when the camera is refused is not in the requirement and needs deciding.** The
> honest options are to fall back to the library silently, or to say why the camera cannot open and
> offer Settings. **Raised in `## Blocked` rather than chosen here.**

**Compression happens when the image is picked, in the background.** Agent's recommendation, agreed
by the owner 2026-09-11. The preview appears immediately from the original while compression runs
behind it, so the send is instant and the delay lands where nobody is waiting.

- **Target: legible before small.** The owner's constraint is that an admin — or software, later —
  must still read the amount, date and recipient. The agent's starting values are **1600px on the
  long edge at JPEG 0.8**, typically 150–400 KB; these belong to this ticket and may be tuned once
  real receipts are seen.
- **The user is never shown a size limit** (requirement). An internal ceiling exists only as a guard
  against something pathological.

**Sending does not send.** Owner's instruction: no API call. The button pops back to the class
detail and shows the toast *Bukti pembayaran terkirim. Menunggu verifikasi.*

> **The class still reads *Belum Dibeli* afterwards**, because nothing changed the data. The
> requirement is explicit that the toast is not a status change and **must not be built as one** —
> no local flag, no faked `PENDING_VERIFICATION`. When the API call lands, the status changes for
> real.

### Getting a message onto the previous screen

**Popping two screens and then showing a toast on the one underneath is the only genuinely new
mechanism in this ticket.**

The straightforward shape: `DapurNauraAppRouter` gains a pending message that the class detail
consumes once on appear, and the flow sets it as it pops. §4 permits this now because **a caller
exists** — the rule it has to satisfy is that a convenience with no caller is worse than none, and
this one has exactly one.

**The pop is two levels**, not one: the user came from class detail through both screens.

### Going back

**Back works, and a chosen image is discarded.** Owner's decision, 2026-09-11. Returning to screen
one to pick the other bank starts the proof again — the image belongs to the destination it was
gathered for.

## Public API contract

None. No DNLibrary change; this consumes what DN-047 publishes.

**Version bump implied:** none. **But this ticket cannot start until DN-047 is published and the app
repinned** — the Swift here calls API that no released version carries.

## Out of scope

- **Any API call.** Owner's instruction. Nothing is sent, stored or retried.
- **Changing the purchase status**, locally or otherwise. See above; the requirement forbids it.
- **Editing, cropping or rotating the image.**
- **A record of past payments**, a receipt, or seeing a submitted proof again.
- **Cancelling a payment** once proof is sent.
- **Real account numbers**, and **real bank logos.** Both are the owner's to supply.
- **Redesigning the class detail screen.** It already draws all three purchase states; this work
  arrives at one of them.
- **Android.**

## Test plan

UI, so no unit tests (platform Definition of Done — the data layer only). What was run:
`xcodebuild … build` to `** BUILD SUCCEEDED **` and `swiftlint lint` to 0 violations.

What the owner is asked to check on the running app:

| Check | Expected |
|---|---|
| *Beli Kelas* on a class not yet bought | Opens screen one, showing both accounts |
| The amount shown | Matches the class price exactly |
| Tap copy on Mandiri | Toast *Nomor rekening tersalin*; screen two opens; paste elsewhere gives that number |
| Screen two's destination line | Names the bank just copied, not the other one |
| Pick from the library | Preview appears; send becomes available |
| Take a photo | Camera opens **without the app closing** — the DN-046 check |
| Refuse camera access | Whatever `## Blocked` settles |
| Tap *Ganti* | Lets a different image be chosen |
| Send | Returns to the class detail; toast *Bukti pembayaran terkirim. Menunggu verifikasi.* |
| The class after sending | Still *Belum Dibeli*, still offering *Beli Kelas* — **correct, not a bug** |
| Back from screen two | Returns to screen one; any chosen image is gone |
| A class already bought, or awaiting verification | No *Beli Kelas* button; these screens unreachable |
| A very large photograph | Compresses without a visible stall |

## Done when

- [ ] Both screens exist under `Cookings/`, following §3's layout
- [ ] Screen one renders `GetPaymentDestinationsUseCase` with all three states, not hard-coded cards
- [ ] Colour and logo chosen in Swift by switching on `Bank`; nothing about appearance in the library
- [ ] Copy writes the clipboard, shows the toast, and pushes screen two with that destination
- [ ] Library and camera both offered; camera does not terminate the app
- [ ] Compression runs at pick time, off the main thread; the preview is immediate
- [ ] Send pops two levels and the class detail shows the toast once
- [ ] **No status is changed anywhere** — grep the diff for it before offering review
- [ ] Back from screen two discards the image
- [ ] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034)
- [ ] `swiftlint lint` reports 0 violations
- [ ] `project.pbxproj` and `Package.resolved` carry no local package reference
- [ ] Documentation sweep (DN-042)
- [ ] Owner has verified the flow on the running app
- [ ] Committed
- [ ] PR opened, naming [DN-047's PR](../tickets/DN-047-product-payment-destinations-data.md) under `### Dependencies`
- [ ] PR merged

## Blocked

**One decision is missing and it is small: what happens when the user refuses camera access.**

The requirement does not cover it because the question did not come up. The options:

- **Fall back to the library silently.** Simplest; the user gets a picker either way. But someone who
  meant to photograph a paper receipt is left without an explanation.
- **Say why, and offer Settings.** Honest and standard, and the only route back for someone who
  refused by accident. Costs a message and a link.

**The agent would take the second**, because the paper-receipt case is the whole reason the camera is
there, and a silent fallback strands exactly the user it was added for. **The owner decides before
this ticket starts.**
