---
status: approved
date: 2026-09-11
author: owner
drafted-by: agent
approved: 2026-09-11
---

# Paying for a class by bank transfer

> **Every quotation below is the agent's English translation of an instruction the owner gave in
> Bahasa Indonesia on 2026-09-11**, per the platform's language rule. The originals are not stored.
> Where a translation could plausibly change the meaning, the point is raised in `## Open questions`
> rather than settled here.

## Who this is for

**Anyone who wants to buy a class and has not bought it yet.** Today they meet a button that says
the purchase is not available; this is what replaces that answer.

It is not for anyone else: a class already bought, or already awaiting verification, shows no buy
button at all and never reaches these screens.

## What they need

**A way to pay, which is a bank transfer made outside the app, and a way to prove they made it.**

The owner's instruction, translated, 2026-09-11:

> "When a user wants to pay, the user is taken to a page containing two cards arranged vertically.
> The first card, match the colour to Bank Mandiri, then there is a name and account number. The
> second card, match the colour to BSI, then there is a name and account number."

And, translated, the same day:

> "On the card there is an icon which, when pressed, copies the account number shown. Then a toast
> appears saying the account number has been copied, and navigates to the next screen, which has a
> button to upload proof of payment."

**This is the transfer-and-verify process the business already runs**, put into the app. The app
never moves money. It shows where to send it, then collects a photograph of the receipt.

> **This is the first half of something the platform deliberately deferred.** The blocker recorded
> on 2026-08-06 — no signed-in user, no purchase path — is unchanged. There is still no backend, so
> **nothing can receive the photograph and nothing can verify a payment.** Building these screens
> does not un-defer that, and this document does not make that decision. What it means in practice
> is set out under *What happens when it is sent*.

### Where these screens sit

**Two screens, pushed one after the other, reached from the class the user is buying.**

**The entry is the *Beli Kelas* button on the class detail screen.** Confirmed by the owner,
2026-09-11, translated: *"Correct, the entry point is that button."* It currently answers with a
"not available" notice; this replaces that answer.

**They are pushed onto the navigation stack, not presented as a sheet.** This follows from the
owner's instruction about what happens at the end, translated, 2026-09-11:

> "After the send button is pressed, it will pop back to the class page and refresh that page,
> because the status should change from notPurchased to pendingVerification."

*Pop back* is a stack operation. **This supersedes an earlier suggestion by the agent** that a
checkout should be presented modally with its own stack; the owner's answer settles it the other
way, and the reason is sound — the user is not interrupted and sent back, they are moving forward
through a purchase and then returning to where they started.

### Screen one — choosing where to transfer

**Two cards, one per bank, stacked vertically.** Owner's instruction, above.

**The user picks one.** Owner's instruction, translated, 2026-09-11, answering the agent's question
of whether both accounts are used: *"Pick one of the banks."* They are alternatives, not a sequence.

Each card carries:

- **The bank's name**, as text.
- **The bank's logo**, in a white chip. See *The bank logos* below.
- **A dummy account number**, following that bank's real format. Owner's instruction, translated:
  *"Make the name and account number dummy, but following Bank Mandiri and BSI standards."*
- **The name the account is held in**, also dummy.
- **A copy control**, which is what the user presses.

**The card's colour matches its bank.** Owner's instruction, above — *"match the colour to Bank
Mandiri"* and *"match the colour to BSI"*.

[ASSUMPTION] **The class being paid for, and the exact amount, are shown above the cards.** The owner
did not ask for this. It is here because a user who has left the app to type a transfer needs to know
what figure to type, and returning to check is the most likely reason they would abandon the flow.

#### The account numbers

**Mandiri is 13 digits. BSI is 10 digits.** The owner asked the agent to establish this, translated,
2026-09-11: *"Confirm the bank digits yourself. I personally don't know."* Both were checked against
public sources and the dummy numbers follow the real shape.

**The numbers and the account-holder name in the app today are placeholders.** They are dummy by the
owner's instruction, and replacing them with the real ones is a separate decision — see
`## Open questions`.

#### What pressing copy does

Three things, in order. Owner's instruction, above.

1. **The account number is copied** to the clipboard.
2. **A message appears** saying it has been copied.
3. **The app moves to screen two.**

**Pressing copy is therefore also how the user chooses a bank** — there is no separate selection.
The bank whose number was copied is the one screen two refers to.

> [ASSUMPTION] **Screen two names the account that was copied.** The owner did not ask for it. It is
> here because copying and immediately navigating away removes the number from view at the moment the
> user is about to type it elsewhere; showing it on the next screen is what makes that safe. The
> agent raised this as a concern on 2026-09-11 and the owner did not ask for the navigation to
> change, so the compensation is carried on screen two instead.

### Screen two — proving the transfer was made

**Its whole purpose is to send a photograph of the receipt.** Owner's statement, translated,
2026-09-11: *"the screen's function is actually to upload the payment proof image to the backend
(eventually)."*

**The owner asked the agent to propose the layout** — translated: *"I need suggestions for the next
screen, how should it look? Any suggestions?"* — and approved what follows on 2026-09-11 after seeing
it drawn: *"OK, everything fits."* **Everything in this section is therefore the agent's proposal,
approved rather than specified**, and is a starting point the owner may revise once it is on a
device.

The screen carries:

- **What is being paid for and how much**, repeated from screen one.
- **The account the user copied**, marked with that bank's colour.
- **One large area for the proof**, which is where the screen's attention goes. Empty, it invites a
  choice; filled, it shows what was chosen.
- **A short reminder of what must be legible** in the photograph: the amount, the date, and who
  received it. This exists to reduce proof that has to be rejected.
- **One action, to send it**, which does nothing until an image has been chosen.

#### Choosing the image

**From the photo library or from the camera.** Owner's decision, translated, 2026-09-11:

> "I want gallery plus camera — sometimes people photograph proof of payment in the form of a paper
> receipt, and that cannot be screenshotted."

**Both are needed for that reason.** A transfer made in a banking app produces a screenshot; a
transfer made at a counter or an ATM produces paper, and paper has to be photographed.

**The chosen image is shown before it is sent.** [ASSUMPTION] — the owner did not ask for a preview.
It is here because the user cannot otherwise tell which image was picked, and picking the wrong
screenshot is the most likely mistake on this screen. **It can be replaced** without leaving.

> **Using the camera requires the app to state why**, which is configuration this app does not yet
> carry. The owner was told and accepted it on 2026-09-11: *"The camera will be used."* Choosing from
> the library requires nothing. This is named here because it is a real cost the decision carries,
> not because a requirement should describe configuration.

#### What happens when it is sent

**The app returns to the class, and the class now reads as awaiting verification.** Owner's
instruction, above — *"pop back to the class page and refresh that page, because the status should
change from notPurchased to pendingVerification."*

The class detail screen already draws all three states and already shows **no buy button** while a
purchase is awaiting verification, so that someone who has transferred is not invited to transfer
again. That behaviour is unchanged; what is new is arriving in that state.

#### What it does, and what it will do

**Eventually the button makes an API call.** Owner's instruction, translated, 2026-09-11:

> "The Send button will make an API call, sending the image data — the BLOB — to the backend."

**For now it makes none.** Owner's decision, translated, the same day:

> "For now there is no need to build the API call. Just pop to the screen from before the payment
> flow happened."

So the button's whole behaviour today is **to return to the class detail screen** — the screen the
user was on when they pressed *Beli Kelas*. Nothing is sent, nothing is stored, nothing is retried.

**A message is shown on the way back.** Owner's decision, 2026-09-11, after the agent raised that
the class would otherwise look untouched: the app returns to the class detail and shows the toast
**Bukti pembayaran terkirim. Menunggu verifikasi.**

> **The class itself still reads *Belum Dibeli*.** With no API call there is nothing to change a
> purchase status, so the badge and the *Beli Kelas* button are unchanged. The message is what tells
> the user their proof was taken; **it is not a status change and must not be built as one.** When
> the API call lands, the status changes for real and the message keeps its job.

**There is still no signed-in user**, so even when the call exists, nothing yet identifies who paid.
That remains the owner's deferral of 2026-08-06.

### The image is made smaller before it is sent

**Compressed, not sent as the camera produced it.** Owner's decision, 2026-09-11.

Two reasons, both the owner's. Translated:

> "This will also reduce the load and the charge on the server database I am going to rent."

and, on why it must still be legible:

> "Dimension plus quality, so that an admin — or even AI, maybe in the future, really far in the
> future — can validate it easily, because the image is still clearly visible."

**So the target is set by what verification needs, not by a byte count.** It has to stay readable
enough that a person checking the payment can make out the amount, the date and who received it; a
receipt compressed past that point costs the owner more in rejected proof than it saves in storage.
**The exact dimension and quality belong to the ticket**, not here.

**The user is never shown a size limit.** Owner's decision, 2026-09-11, translated: *"no need to show
the size limit, our clients are likely mothers who are not confident with technology."* They choose
any photograph; the app makes it small. A number they cannot act on would be a burden, not a
safeguard.

### When sending fails

**The image is kept.** Owner's decision, 2026-09-11. Someone who has photographed a paper receipt
may already have thrown it away, so losing their photograph means losing the proof. A failure leaves
them on the screen with the image still attached and the action ready to press again.

**They are told what went wrong in the app's existing words.** The data layer already describes every
failure it can produce, in Bahasa Indonesia, and every other screen already uses those; this screen
uses the same ones. **No new wording is written for this feature**, and Android will say exactly the
same things.

## The bank logos

**The banks' real logos are used.** Owner's decision, translated, 2026-09-11: *"Let's just use bank
icons, for beauty."*

**The agent advised against this initially and then corrected itself, and the correction is the
recorded position.** Naming a bank you are actually transferring to, and showing its mark to identify
it, is descriptive use — it identifies the real destination rather than claiming any connection to
the bank. Payment screens across the Indonesian market do the same. What would be a problem is
implying the bank endorses or partners with Dapur Naura, or altering the mark; neither is done here.

**The logos are supplied by the owner as official assets, and not yet.** Owner's decision,
2026-09-11, translated: *"The bank logos can come later — I will add them myself when I feel they
are needed."* The agent does not draw them: an approximated bank logo is a distorted trademark and
is worse than none. **The chips hold a placeholder until then, and shipping that way is the owner's
choice rather than an unfinished edge.**

**Each logo sits in a white chip at the top-left of its card.** Owner's question, translated,
2026-09-11 — *"Where would the bank logo be good?"* — and approval of the answer the same day:
*"Correct."* The chip is white because both banks' marks are dark and would disappear against the
cards' colours.

## The wording

**All screen text is Bahasa Indonesia**, per the platform rule. The words below are the agent's and
were approved with the drawing rather than dictated; **the owner may change any of them.**

| Where | Text |
|---|---|
| Screen one, title | Pilih Rekening |
| Above the cards | Pembayaran untuk |
| Above the cards | Transfer tepat Rp … ke salah satu rekening di bawah ini. |
| On each card | a.n. … |
| Message after copying | Nomor rekening tersalin |
| Foot of screen one | Ketuk ikon salin untuk menyalin nomor rekening. Anda akan langsung diarahkan ke halaman unggah bukti. |
| Screen two, title | Bukti Pembayaran |
| On screen two | Rekening tujuan |
| Upload area, empty | Ketuk untuk pilih bukti transfer |
| Upload area, empty | Galeri atau kamera |
| Replacing the image | Ganti |
| Above the reminders | Pastikan terlihat jelas |
| The three reminders | Nominal · Tanggal · Penerima |
| The action | Kirim Bukti Pembayaran |

## Appearance

**It follows the app**, and every value is taken from what the app already uses rather than invented:
the amber of the primary button, the muted grey of secondary text, the light grey of filled areas,
the 20-point corner radius, the 56-point control height and the 24-point side margins.

**The two bank cards are blocks of their bank's colour** with white text, which makes them the
heaviest thing on screen one — correct, because they are what the user came for.

**The account number is the largest text on each card.** It is what the user has to read and copy;
the bank's name and the account holder are context around it.

**On screen two the upload area takes the space that is left**, so the screen reads as one task
rather than a form with an attachment.

## Out of scope

- **Taking payment in the app.** No gateway, no Midtrans, no card. The transfer happens in the user's
  banking app or at a counter, and the app never touches money. Owner's deferral of 2026-08-06 is
  unchanged.
- **Verifying that a payment arrived.** Nobody and nothing checks. Verification is the owner's manual
  process and stays outside the app.
- **Storing the photograph anywhere.** There is no backend to send it to.
- **Any notion of who paid.** No signed-in user, so nothing ties a payment to a person. Still
  deferred.
- **Changing what the class detail screen draws.** It already renders all three purchase states
  correctly; this work arrives at one of them, it does not redesign them.
- **Editing or cropping the image.** Whatever the user picked is what is sent.
- **A record of past payments**, a receipt, or any way to see a submitted proof again.
- **Cancelling a payment** once proof has been sent.
- **Android.** Does not exist.

## Open questions

- **Whether the user is told anything after sending.** Settled: the button pops back and makes no
  API call (owner, 2026-09-11). What is not settled is that the class then looks untouched — same
  *Belum Dibeli* badge, same *Beli Kelas* button — so pressing send appears to do nothing. A message
  on the way out, or on arrival, would close that gap without inventing a status the data cannot
  support.
- **The real account numbers and the real account-holder name.** Everything in the app today is
  dummy, by instruction. Whether the real ones are hard-coded, or come from the server when one
  exists, is undecided.
- ~~Whether the user can get back to screen one.~~ **Settled** (owner, 2026-09-11): yes, back
  works, and **a chosen image is discarded** when they leave. Picking the other bank starts the proof
  again.
- ~~What happens if sending fails.~~ **Settled** (owner, 2026-09-11): the image is kept and the
  existing failure wording is used. See above.
- **One gap in that wording, found while settling it.** The data layer describes a non-2xx response
  as *"the server is having problems, try again later"*, which is right for a server fault and wrong
  for a refused file — trying again will never work. It cannot happen while the image is compressed
  small, and it is a data-layer concern rather than a screen one. **To be resolved with the API call
  that does not exist yet.**
- ~~Whether the image is compressed, and whether a size limit is enforced.~~ **Settled** (owner,
  2026-09-11): it is compressed, and no limit is shown to the user. See above.
- **Whether the amount is shown on screen two** as well as screen one. It is in the drawing, but the
  owner has not been asked whether it should be.

