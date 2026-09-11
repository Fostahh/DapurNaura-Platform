---
id: DN-048
type: product
title: iOS — choosing a bank account and sending proof of payment
status: in-review
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

**The bank's colour and written name are chosen here**, by switching on `Bank`. DN-026's rule: a
colour is a decision about this surface, so it stays in Swift.

**There is no logo and no placeholder.** Owner's decision, 2026-09-12, **superseding the
requirement** — see *The logo the requirement asked for* below.

### Screen two — the proof

**No fetch, so no `State` enum** — the same absence DN-033 and DN-040 recorded, for the same reason:
§7's three states are the outcomes of loading something, and this screen loads nothing. **It is not a
precedent for skipping one on a screen that fetches.**

What the ViewModel holds: the chosen image, the compressed bytes, and whether a send is in progress.

**The class name and the amount are repeated here**, not only on screen one. Owner's decision,
2026-09-11 — the requirement left it open because the drawing showed it without anyone being asked.
The user has left the app to type a transfer in between; the figure has to be checkable on the screen
where they confirm it.

**The picker offers the library and the camera** (requirement). `PhotosPicker` for the library,
which needs no permission; a camera sheet for the other, which needs DN-046.

**Refusing camera access is not a failure.** Owner's decision, 2026-09-11, translated: *"If the user
refuses camera permission that is fine, as long as there is still the option to upload from the
gallery. Maybe just make it informative."*

So the screen says why the camera did not open and **leaves the gallery exactly where it was.** The
user is not blocked, not sent to Settings, and not asked again — they have another way through and
the message points at it.

> **This is the first caller `ToastKind.information` has ever had.** DN-040 built three kinds because
> the component was meant to serve the app rather than that screen, and recorded that only `.error`
> was exercised. A refused permission is information, not an error — the user chose it — so this is
> the kind that fits, and it stops being untested code.

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

### A toast that outlives the screen that raises it

**This ticket raises a toast twice from a screen that is leaving.** Copying an account number says
so *and* pushes; sending proof says so *and* pops two levels. A toast owned by either screen dies
with the navigation that caused it, and with the countdown it was running.

**`ToastCenter`: a shared object any screen calls, with the root observing it.** Owner's design,
2026-09-12, carried over from their UIKit apps. `RootView` hosts the only `Toast` in the app, above
both flows, so a push, a pop and a flow swap all leave it standing.

> **It is injected, not a singleton.** Owner's decision, 2026-09-12, taken after the review: it is
> `@State` on `DapurNauraApp` beside `DapurNauraAppRouter` and reached with
> `@Environment(ToastCenter.self)`, so there is **one way to reach shared state in this app rather
> than two**. The cost is one property in each view that raises a toast — four today, two of which
> already declare the identical line for the router — and `.environment(ToastCenter())` in any
> `#Preview` of such a view, since `@Environment(Type.self)` traps rather than defaults.

> **In SwiftUI the emit half writes itself.** UIKit needs a delegate, a notification or a Combine
> subject, with the root subscribing and unsubscribing. Reading `ToastCenter.shared.message` inside
> a `body` *is* the subscription — no emit, no registration, nothing to tear down.
>
> **That read is one view deeper than the root, and it has to be.** The subscription lands on
> whichever `body` performs it, so reading it in `RootView` made every toast invalidate the app's
> root — the flow view and its navigation stack with it, while the user was navigating. `ToastHost`
> is that read and nothing else; the root overlays it. Added 2026-09-12, see *What the review
> changed*.

**Views call it. ViewModels never do.** Owner's rule, 2026-09-12: *"Toast is also a View, it
shouldn't be in the ViewModel."* A ViewModel publishes **what happened**; the View decides that a
toast is how it gets said.

**Where each sentence lives follows from where it is generated** — owner's rule, same day:

| String | Generated by | Owned by |
|---|---|---|
| *Email harus diisi.* | validation over this screen's state | `LoginViewModel` |
| *Gambar gagal diproses…* | compression failing, asynchronously | `PaymentProofViewModel` |
| *Nomor rekening tersalin* | the View writing the pasteboard | `PaymentDestinationView` |
| *Akses kamera tidak diizinkan…* | the View checking the camera | `PaymentProofView` |
| *Bukti pembayaran terkirim…* | the View deciding to pop | `PaymentProofView` |

`PaymentDestinationViewModel` therefore has nothing to do with toasts at all.

**`choose` became `async` and returns the complaint.** The compression failure happens inside the
ViewModel with nothing the View could observe, so the ViewModel reports it and the View decides it
is a toast. The preview still appears instantly — `proof` is set before anything is awaited.

**The boundary is enforced rather than remembered**: `no_toast_in_viewmodel` in `.swiftlint.yml`,
the third custom rule after `no_system_font` and `no_swift_number_formatter`. The workspace's own
finding is that **rules held wherever they were encoded and drifted wherever they were prose.**

> **Injection narrowed what the rule has to catch, and does not replace it.** It was written when
> `ToastCenter` was a singleton — reachable from anywhere, a ViewModel included. A ViewModel must
> now be *handed* one, which is visible in its `init`; the rule still fires either way, because
> receiving one means naming the type in a `*ViewModel.swift` file.

**Nothing is handed to the screen underneath.** `router.pendingToast` — built earlier in this ticket
— is gone, and `CookingClassDetailView` no longer touches the router at all.

**What this replaced.** A `ToastPresenter` injected into ViewModels was built first and rejected by
the owner: it fixed the navigation defect but made every ViewModel able to drive app-wide UI, which
is the opposite of what they had asked for.

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
- **Real account numbers.** The owner's to supply.
- **Bank logos of any kind**, including a placeholder standing in for one — see *The logo the requirement asked for*.
- **Offline classes.** The requirement describes the class detail's buy button and nothing else, so
  the Kelas Offline schedule keeps its *"Pembelian lewat aplikasi belum tersedia."* alert. The two
  buy buttons therefore behave differently after this ticket — **recorded, not fixed**, because
  extending the flow there is a product decision the requirement does not make.
- ~~**Changing `Toast` itself** — its look, its three seconds, its restart rule, its measured
  height. Only where it is mounted changes.~~ **Scope extended by the owner, 2026-09-12**, after a
  SwiftUI review of the component: the dismissal race, the observation scope, the fixed line height
  and the ignored Reduce Motion setting are fixed here rather than ticketed separately, and the
  clock moved from the banner into `ToastCenter`. **Its look, its three seconds and its restart
  rule are unchanged** — what moved is which type runs the timer. See *What the review changed*.
- **A toast queue.** One message at a time, newest wins. This moves the state; it does not stack it.
- **Making other transient UI app-wide.** `NoticeSheet` stays where it is.
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
| Screen two's amount | Matches screen one and the class price |
| Pick from the library | Preview appears; send becomes available |
| Take a photo | Camera opens **without the app closing** — the DN-046 check |
| Refuse camera access, or run on the simulator | An informative toast — *Akses kamera tidak diizinkan. Anda masih bisa memilih dari galeri.* — and the gallery still works |
| Back out of screen two, then return | The chosen image is gone; nothing was kept |
| Send | Pops **two** levels to the class detail, which reloads and shows one toast |
| The class after sending | Still reads **Belum Dibeli** — this is correct, and the toast is the only confirmation the proof was taken |
| **Pick a landscape photograph** | Every row stays inside the screen — the defect found in review, see below |
| **Copy an account number** | The toast is readable **on the proof screen**, not left behind |
| Where the toast sits | Over the navigation bar now, not below it — **accept or reject this** |
| Login with an empty field, then log in | Toast appears; it does not ride into the class list |
| Pick a large photograph and watch the button | Spinner and *Menyiapkan gambar…*, then the normal label — never grey and silent |
| **Deny camera access on a device, then tap *Kamera*** | The informative toast — **this is the row that was broken**, see *What the review changed* |
| **Tap the middle of the empty dropzone** | A choice of *Galeri* / *Kamera* — the area says *Ketuk*, so it answers |
| **Take a photo, then press *Ganti*** | *Kamera* is offered, so a badly framed receipt can be retaken |
| **Pick the same photograph twice in a row** | The second pick is accepted, not ignored |
| **Set the text size to the largest accessibility size** | Both payment screens scroll; nothing is cut off and the send button is reachable |
| **Raise a toast just as an older one expires** | The new message stays its full three seconds |

**The last row is the one to read twice.** A reviewer expecting the status to change will read a
correct build as broken; nothing records a payment, so nothing may claim one was made.

## Done when

- [x] Both screens live under `Presentation/Cookings/`, one type per file (§3)
- [x] Screen one renders `GetPaymentDestinationsUseCase` through all three states (§7) — no hard-coded cards
- [x] Colour and name are chosen in Swift; nothing about appearance comes from the library
- [x] **No bank mark is drawn and no space is reserved for one**; the requirement carries a `corrected-by: DN-048` pointer for it
- [x] **The route carries `BankBrand`, not `Bank`** — §4 forbids a route carrying a library model, so the app has its own bank vocabulary and maps once, in `BankBrand.init(_:)`
- [x] Copy writes `UIPasteboard`, shows the toast, and pushes screen two with the bank just copied — **and the toast survives the push**
- [x] Library *and* camera are both offered; refusing the camera is reported with `ToastKind.information` — its first caller — and leaves the gallery available
- [x] The camera cannot terminate the app — DN-046 shipped `NSCameraUsageDescription` first, which is why it was split out
- [x] Compression runs at pick time on a detached task; the preview shows the original immediately
- [x] The send button states why it is disabled while compression runs, and a failed compression drops the image with an explanation rather than spinning for ever
- [x] `PaymentProofContent` is back under §9's 200-line limit by extracting `ProofSummaryCard`, not by trimming
- [x] Send pops two levels and the toast is readable on arrival, with nothing handed over
- [x] **No ViewModel mentions a toast**, and `no_toast_in_viewmodel` enforces it
- [x] Exactly one `Toast` in the app, hosted by `RootView` — grepped, not assumed
- [x] Every message keeps its original wording, and sits with whichever layer generates it
- [x] **No purchase status is written anywhere** — checked across both new folders before offering review
- [x] Semantic fonts only (§9) — three fixed sizes were caught by `no_system_font` and replaced
- [x] The landscape-photograph defect is fixed and covered by a preview — see *Found in review*
- [x] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034) — `DapurNaura Dev`, simulator `4C82AD15-1365-4200-977C-C5DF10E11B1B`, re-run after the review fixes, 2026-09-12
- [x] `swiftlint lint --strict` reports 0 violations, including the new `no_toast_in_viewmodel`
- [x] **No prose comments outside `Components/`** — the rule is now written into CODEBASE-ARCHITECTURE §3, having been given twice
- [x] A clean build reports **no Swift warnings** — the two Swift 6 isolation warnings the owner found are fixed, not silenced
- [x] `project.pbxproj` and `Package.resolved` carry no local package reference — the app resolves `0.9.0` by range
- [x] Documentation sweep (DN-042) — enumerated in both repositories (3 tracked `.md` in iOS, 5 outside `docs/tickets/` in the umbrella). **Five documents were falsified by this ticket**: see *What the sweep found*
- [x] **The thirteen review findings are fixed, not deferred** — see *What the review changed*
- [x] The camera asks `AVCaptureDevice`, not `UIImagePickerController`, so a refusal on a device is answered the way the requirement asked
- [x] Both payment screens scroll, and neither truncates at `.accessibility3`
- [x] Everything tappable clears 44×44 (§9) — the *Ganti* capsule was 38
- [x] Re-run of `swiftlint lint --strict` and the build after the `Color+Hex` move
- [x] **`ToastCenter` is injected, not a singleton** — owned by `DapurNauraApp`, reached with `@Environment`, `#Preview` of `LoginView` injects one
- [x] **`ToastCenter` owns the clock**, so the stale-timer race cannot occur rather than being guarded — `Toast` takes a value and draws it
- [x] Diff reviewed by the owner — approved 2026-09-12, after the toast alignment and height rounds
- [ ] Committed
- [ ] PR opened
- [ ] PR merged

## What the sweep found

Unlike DN-047's sweep, nothing here was stale beforehand — **all five documents were made false by
this ticket**, which is what the gate exists to catch:

| Document | What became false |
|---|---|
| `CLAUDE.md` (umbrella) | the standing blocker said paid classes have **no purchase path**, and that the buy button answers *"Pembelian lewat aplikasi belum tersedia."* |
| `README.md` (umbrella) | *Where the project actually is* listed no payment screens |
| `docs/ARCHITECTURE-AND-WORKFLOW.md` | the same "no purchase path" claim, in the deferred-work list |
| `ios/DapurNaura/CLAUDE.md` | the screen list ended at the offline schedule, and closed *"Video and payment are still to build."* |
| `ios/DapurNaura/README.md` | *Features* named every screen except these two |

**The fifth was found by enumerating, not by grepping.** `ios/DapurNaura/CLAUDE.md` never says
"purchase" — its false sentence says *payment are still to build*, six words after a screen list that
reads as complete. A grep for the terms this ticket touched would have walked straight past it, which
is the failure DN-042 was written about.

**The blocker was rewritten, not deleted.** It still describes a gap — screens exist and nothing
records a payment — and now carries the constraint that made it survivable: *the screens must not
fake a status to hide it.* Deleting it would have read as "payment is done".

## The logo the requirement asked for

**The approved requirement specifies a logo in a white chip, and the app now has neither.** It says
so twice — *"The bank's logo, in a white chip"* under what each card carries, and a whole section
settling that *"Each logo sits in a white chip at the top-left of its card"*, answering the owner's
own question about placement.

**The requirement's prose is untouched.** It records what was asked for on 2026-09-11 and that is
still true of that day. What changed is the intent, so the correction is carried here and the
requirement gained only a `corrected-by: DN-048` pointer in its frontmatter — the one edit an
approved document permits.

**How it changed.** The owner asked whether the real marks could be found (2026-09-12). They can:
Mandiri publishes a brand guideline, and it states the mark may not be redrawn, modified or
recoloured, and that only supplied artwork may be used. BSI has no official download the search
surfaced — every hit was a third-party logo site hosting the mark without permission. Holding an
account at a bank grants no right to its trademark; those are separate things. Offered a monogram
instead, the owner's answer was to remove the placeholder altogether.

**Which is the better screen anyway.** An empty dashed square reserving space for a missing asset
reads as unfinished; the bank's name set in its own colour reads as a decision. And naming the bank
in text is what a transfer actually requires — it is also nominative use, the part that was never
in question.

**The colours stay deliberately off-brand.** BSI's published primary is `#00A39D` and the card uses
`#00726C`; Mandiri is blue and yellow and the card uses `#10365F` with `#F0C674`. The cards had to be
dark for white text, so the difference came from the layout — but it is worth keeping while there is
no licence. **They evoke; they do not reproduce.**

**One constant was renamed rather than deleted.** `bankLogoChipSize` and its corner radius were
shared with the copy button, which still needs them — so they became `bankCardButtonSize` and
`bankCardButtonCornerRadius`. A constant named for a view that no longer exists is how the next
reader is misled.

## The disabled send button

**Compression runs at pick time, and for a moment the preview is on screen while the bytes are
not ready.** `canSend` is `compressedProof != nil`, so the send button was grey with the photograph
plainly visible above it — and nothing said why. Raised by the agent, 2026-09-12; owner's answer:
*"maybe during compression, just show a loading indicator."*

**The button now explains its own disabled state**: a spinner and *Menyiapkan gambar…* while
`isPreparing`, the normal label otherwise. It stays disabled either way — this says why, it does not
let the tap through. For an audience the owner describes as not comfortable with technology, a
control that is grey for no stated reason is indistinguishable from a broken one.

**A stuck spinner is worse than a stuck button, so the failure path had to be closed first.**
`isPreparing` is *the absence of bytes*, and `compress` returns `Data?` — a nil would have spun for
ever where it previously only left a button grey. Compression coming back empty now drops the image
and says so: *Gambar gagal diproses. Silakan pilih ulang.* That is the only new user-facing string in
this change, and the only one that puts the user somewhere they can act.

**Two Swift 6 warnings came out of the same code**, reported by the owner from Xcode:
`proofMaxLongEdge` and `proofJpegQuality` are read by the compression that deliberately runs off the
main actor, and `SWIFT_APPROACHABLE_CONCURRENCY` isolates `DesignConstants` to the main actor by
default. Both are `let` constants of a `Sendable` type, so `nonisolated` is the honest fix rather
than a suppression — **and the comment says so**, because the keyword looks removable and is not.

> **Worth a decision later, not now:** those two are the only values in `DesignConstants` that are
> not about appearance. A long edge and a JPEG quality are how an image is *prepared*, not how it is
> *drawn*, and the isolation warning is arguably the type system pointing at that. Left where they
> are — moving them is a judgement the owner has not been asked for, and `nonisolated` is correct
> either way.

**`ProofSummaryCard` was extracted while doing it.** `PaymentProofContent` crossed SwiftLint's
200-line limit (§9). The order summary is a self-contained card and the screen already has a
feature-scoped `Components/` folder, so it moved there rather than the limit being worked around —
the screen now reads as four things composed: summary, dropzone, guidance, button.

## Found in review

**A landscape photograph made the whole screen wider than the display.** Owner's finding,
2026-09-11, with a screenshot: the order summary, the destination line, the guidance chips and the
send button were all drawn off both edges, each cut at a different place.

**The cause was not the image's file size**, which is what it looked like. `ProofDropzone.filled`
scaled the picture with `scaledToFill`, and a fill *reports a size larger than the space it was
offered* — that is what filling means. `PaymentProofContent` gives the dropzone
`.frame(maxHeight: .infinity)`, so a 4:3 landscape photograph filling a ~500pt-tall slot reported
~667pt of width on a 390pt screen. `VStack` sizes itself to its widest child, so every sibling row
inherited that width and was centred off-screen.

**`.clipped()` was there and could not help.** Clipping trims what is drawn; it never retracts what
a view claimed during layout. That is the part worth remembering, because the modifier reads as
though it should have prevented exactly this.

**The fix is that the picture no longer takes part in layout.** It is an overlay on an empty box:
the box is sized by the screen, and overlay content is sized by its host and cannot push back on it.

**A preview was added for the case rather than only the fix** — `#Preview("Bukti lanskap")` in
`PaymentProofContent`, with a 1200×900 image. Nothing else would catch a regression here: the empty
state was the only preview, and it is the filled state that breaks.

## What the review changed

A SwiftUI review of the branch on 2026-09-12 produced thirteen findings; the owner asked for all of
them, and extended this ticket's scope to cover the six that are `Toast`'s rather than this flow's.

**The one that was a real defect on a device:**

- **`UIImagePickerController.isSourceTypeAvailable(.camera)` is not a permission check.** It reports
  whether the hardware exists, so on a device where the user has denied access it returns `true` and
  the picker presents a black capture screen. *"Akses kamera tidak diizinkan…"* — the sentence the
  owner asked for on 2026-09-11 — could only ever appear on the simulator, where the camera is
  genuinely absent. `PaymentProofView` now asks `AVCaptureDevice.authorizationStatus(for: .video)`,
  requests access itself when the answer is `.notDetermined`, and keeps the hardware check in front
  for the simulator. **The test plan's camera row was passing for the wrong reason.**

**The rest of this flow:**

- **Both screens scroll.** `PaymentProofContent` was a `VStack` sized to the display; at the larger
  text sizes its content exceeded the screen with no way to reach the send button. It keeps its
  layout at every ordinary size — the dropzone still absorbs the slack — and scrolls only when it
  must.
- **A failed gallery load said nothing at all.** Both failure paths returned silently, and
  `isPreparing` is false while the item loads, so an iCloud photograph that fails to download left
  the user tapping a screen that never changed.
- **Re-picking the same photograph did nothing.** `.task(id:)` does not re-run for an equal
  selection, so after a failed compression the user's likeliest next move — choose that photo again
  — was a dead end. The selection is cleared once handled.
- ***Ganti* could only reopen the gallery**, so a receipt photographed badly could not be retaken.
  Both states now offer both sources through one confirmation dialog.
- **The *Ganti* capsule was ~38pt tall**, under §9's 44 × 44.
- **The empty dropzone said *"Ketuk untuk pilih bukti transfer"* and accepted no tap** — only the two
  chips below it were buttons. The area is now the button the sentence promises.
- **Dead code and literals:** `clearProof()` had no callers; `submit()` only re-read `canSend`;
  `PaymentProofContent` imported `DNLibrary` unused; `send()` popped by a hard-coded count rather
  than by route; bare spacing and radius literals became named constants; `fontWeight(.bold)` became
  `bold()`.

**`Toast`, under the extended scope:**

- **A finished countdown could clear the message that replaced it.** `Task.sleep` throws only while
  suspended, so a timer cancelled in the instant after it elapses still runs its last line — and
  `dismiss()` cleared unconditionally. A toast raised as a screen navigates, which this flow does
  twice, could be wiped the moment it appeared.

  **First guarded, then designed out.** The fix was an id-aware `dismiss(_:)` clearing only the
  message it was told to; the owner then asked whether the whole thing could be simpler, and it
  could. **`ToastCenter` owns the clock now** — `show` cancels the previous timer before starting
  the next, and `cancel()` sets `isCancelled` synchronously, so a timer whose sleep has just
  elapsed cannot reach `message`. One timer, one owner, and the race has nowhere left to live.

  What that deleted: `dismiss(_:)`, `Toast`'s `onDismiss` closure and its `.task(id:)` block, the id
  travelling back from the view — and then `ToastMessage.id` itself, which had no other reader.
  `Toast` is now a view that takes a value and draws it. **The behaviour is unchanged**: three
  seconds, newest wins, a second call restarts the clock.

  > **This reverses DN-040's *"this owns the clock; the caller owns the state"***, recorded because
  > that doc comment said so deliberately. Owner's decision, 2026-09-12: a view cannot call off a
  > countdown it has already finished, and the centre can.
- **The observation sat on the app's root.** Moved to `ToastHost`; see the note above.
- **The banner's line height was a fixed 48pt while the text inside it scaled.** The line *count*
  already followed the user's text size; the unit it was counted in did not, so the text lost its
  padding and then clipped. `@ScaledMetric` makes the two move together.
- **The entry slide ignored Reduce Motion**, and now falls back to opacity.
- **A message replacing a taller one was drawn at the previous line count for a frame** — the
  measurement lands after layout. The correction no longer animates, so it is invisible rather than
  a squash.
- **`extension ToastKind: Equatable {}` was redundant** — an enum with no associated values has both
  conformances already — and `ToastCenter` was reached two ways (`ToastCenter.show` but
  `ToastCenter.shared.dismiss`). Two entry points now, both instance methods: `show` and `clear`.
- **`ToastCenter` stopped being a singleton.** Raised as the one un-SwiftUI thing left in it, and
  the owner chose injection on 2026-09-12: `static let shared` and `private init` are gone, the
  three entry points are instance methods, and the App owns it as `@State` beside the router. What
  this buys is consistency — two shared observables reached one way — plus the seam a singleton
  removes. **Weighed and accepted:** one `@Environment` line per raising view, and a preview of such
  a view traps unless it injects one. `LoginView`'s is the only preview affected today.
- **`Color(hex:)` stopped being private in this ticket** and had two consumers. It moved out of
  `DesignConstants+Login` — §3 says `Constants/` holds `DesignConstants` and its extensions, and
  that shared code of this kind belongs in `Presentation/Components/`.

**What was left alone deliberately:** the `.semibold` and `.medium` font weights on both screens.
§9 reserves non-bold weights *for a stated reason* rather than forbidding them, the reason here is
the hierarchy inside a card, and changing them would restyle screens the owner has already checked
on a device. `bold()` replaced `fontWeight(.bold)` because that pair renders identically.

**Also not changed:** `RootView`'s flow transitions still ignore Reduce Motion. They are DN-043's,
the owner has verified them, and they were not among the findings — **recorded, not fixed.**

### The wrapped toast sat in the middle of its banner

**Owner's finding, 2026-09-12, with a screenshot** of the camera-refusal toast on the proof screen:
*"Jika multiple line, teksnya harus dimulai dari top left."* — translated, *"if it is multiple
lines, the text has to start from the top left."*

**The cause is the height rule meeting a default.** A banner is `lineCount × 48` tall (owner's rule,
2026-08-10) and `.frame(height:)` centres its content when no alignment is given, so a two-line
message sat with ~28pt above it and ~28pt below. One line never showed the problem, which is why it
survived DN-040.

**The fix gives the text an inset and pins it to the top**, and the inset is derived rather than
picked: the banner counts in `lineHeight`, the text measures in `UIFont`'s, and half the difference
between them is the space. **One line of text plus that inset is exactly one line of banner** — so a
single-line toast is pixel-identical to before, and a wrapped one now begins where a single-line one
does, with the slack falling to the bottom where nothing is written.

**The inset is applied after the measurement, deliberately.** Measured with it, the padding would be
divided by the line height along with the text and a one-line message would report as two.

**The first attempt truncated the message instead**, and the owner caught it on the next build: the
banner showed *"Akses kamera tidak diizinkan. Anda masih bisa m…"* on one line. The inset was right;
keeping `.frame(height:)` was not. **A fixed height is a cap**, and the inset came out of it before
the text was offered what remained — 48 less 28 leaves a single line's room, so the text truncated
to one line, was *measured* as one line, and stayed there. The loop had no way out, because the
text was never offered the room that would have grown it.

**`minHeight` caps nothing.** The text wraps at its natural width, is measured at its natural
height, and the banner takes the height the rule asks for. The two cannot disagree: `(N-1)` lines of
text are always shorter than `(N-1)` lines of banner, so the height is still an exact multiple of
`lineHeight` in every steady state and at every text size.

> **Worth keeping in mind beyond this screen.** The old code survived only because its cap happened
> to exceed what it capped — 48pt of box for 41pt of two-line text. A three-line message would have
> hit the same trap before this ticket, escaping over several layout passes rather than at once.

**Then the height rule itself went.** Owner's decision, 2026-09-12, on seeing the top-aligned
version: *"The Toast height calculation needs to be fixed, it should be fit the Text line +
padding."* Top-aligning had moved the empty space rather than removed it — 96pt of banner for 41pt
of text left a visible gap under the last line. **This supersedes the multiple-of-one-line rule of
2026-08-10.**

**The banner is now the text plus its inset, and nothing else decides its height.** What the old
rule existed for survives anyway: two toasts wrapping to the same number of lines are still the same
size, because the same font at the same width wraps to the same height. What is gone is the rounding
up to whole lines.

**A single-line toast is unchanged**, at `toastLineHeight` exactly — the inset is derived to make it
so, and that is the one part of 2026-08-10 still doing work.

**What this deleted:** the `GeometryReader`, the `lineCount` state, `lineCount(forTextHeight:)`, the
`.animation(nil, value:)` guarding its one-frame lag, and the height frame itself. Three rounds of
fixes to a measurement that the layout system was doing correctly on its own. **`Toast` no longer
measures anything.**

`#Preview("Pesan panjang")` already carried a message long enough to wrap, so the case is covered.

## Notes

**This is the first ticket that deliberately ships a dead end.** Every earlier screen either showed
data or moved the user somewhere; this one ends by returning them to a class that still says
*Belum Dibeli*. That was the owner's decision, taken with the alternative on the table: no new use
case, no local flag, no optimistic status — because a status the app invented would have to be
un-invented the day a backend disagrees with it.

**The alert it replaced still exists one screen away.** Removing it from the class detail did not
remove it from the app — Kelas Offline still shows it, which is the asymmetry the *Out of scope*
section records rather than papers over.

**It is blocked on the same gap as everything else.** A payment cannot be recorded until something
identifies who paid, and there is still no signed-in user — which is why the proof upload is the
half that was built and the submit is the half that was not.
