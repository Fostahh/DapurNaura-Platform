---
id: DN-012
type: product
title: iOS — cooking-class detail screen, with status-driven buy button and recipe tappability
status: done
source: docs/requirements/2026-08-06-cooking-class-detail.md
branch: ticket/DN-012-cooking-class-detail-ui
layer: ui
---

## Requirement (traced)

From [`docs/requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md)
(approved 2026-08-06). The whole document applies; the rules this screen must satisfy:

| The user… | Buy button | Price | Choosing a recipe |
|---|---|---|---|
| **has bought** the class | not shown | not shown | opens that recipe |
| **has paid, awaiting confirmation** | not shown — a short note says the payment is being checked | not shown | does nothing |
| **has not bought** the class | shown, and carries the price | on the button | does nothing |

> **The buy button reads `Beli Kelas · Rp125.000`** […] Choosing it does not buy anything: it shows
> a short message that buying inside the app is not available yet, and that is all.

> **No count of recipes is shown.** The owner's reason: this screen already lists every recipe the
> class contains, so a number adds nothing.

> The visual design is explicitly delegated to the agent and is not specified here.

## Context

Read before starting:

- The requirement document above — including its `## Statements this can be checked against`, which
  is the owner's acceptance list
- `DN-011-product-cooking-class-detail-data.md` — supplies `GetCookingClassDetailUseCase` and the
  stub replay this screen runs on. **DN-011 must land first.**
- `DN-009-product-cooking-class-list-ui.md` — the list screen this navigates from, and the MVVM
  shape to repeat (`@Observable`, `@MainActor`, `loading / loaded / failed`)
- `ios/DapurNaura/CLAUDE.md` — SKIE bridging notes: Kotlin `description` → `description_`, sealed
  results via `onEnum(of:)`, `try await useCase.invoke()`, `DNDataLayer.companion.stub()`
- The umbrella `CLAUDE.md` **local package rule** — the app builds against `ios/DNLibraryLocal`, and
  **that wiring is never committed**

Already true, and constraining:

- **Content is Bahasa Indonesia.** Every user-facing string on this screen is Indonesian, and the
  domain words stay as they are — `loyang` is not translated.
- **iOS work stacks on `ticket/DN-009-cooking-class-list-ui`**, which stacks on DN-003. The list
  screen only exists on that branch.
- **`purchaseStatus` is a UI hint, never a gate.** The screen varies on it; it never relies on it
  for protection. Protection is that the server never sent the content.
- `IPHONEOS_DEPLOYMENT_TARGET` is 26.2 while installed simulators run 26.0 — `xcodebuild` needs an
  override from the CLI (DN-009's discovery, still open).

## Technical approach

**Navigation.** The list screen's rows become selectable, pushing the detail screen with the class
id. This is the first navigation in the app, so it also introduces the container for it.

**`CookingClassDetailViewModel`** (`@Observable`, `@MainActor`) — `state` = `loading / loaded /
failed`, `load()` awaits `GetCookingClassDetailUseCase` via SKIE's async bridge and maps `DNError`
to Indonesian messages, reusing DN-009's mapping.

**`CookingClassDetailView`** — the design, which the requirement delegates:

- class picture as a header, then name and description
- the recipe list below it: picture, name, and — only when the class is bought — `portions` and
  `loyang` as two separate labels, never concatenated
- **status-driven, per the table above:**
  - bought → no button, no price; rows are tappable
  - awaiting confirmation → a note reading **"Pembayaran sedang dicek"**, no button, no price; rows
    are inert
  - not bought → a button reading **"Beli Kelas · Rp125.000"** (the class's own price, formatted as
    DN-009 formats prices); tapping it shows **"Pembelian lewat aplikasi belum tersedia."** and
    nothing else; rows are inert
- loading and error states reuse DN-009's spinner and its "Coba Lagi" retry

**Where a tapped recipe goes.** The recipe screen belongs to the *next* requirement, so this ticket
pushes a placeholder showing the recipe's name and a line saying the recipe page is not built yet.
`[ASSUMPTION]` — the agent's decision, not the owner's. It exists so the tappability rule is
actually verifiable on the running app: bought classes navigate, the other two do not. It is
expected to be replaced wholesale by the next requirement's ticket.

## Public API contract

None — no DNLibrary change. **No version bump, and `publish-spm.sh` is not run for this ticket**
beyond the `local` build needed to develop against DN-011.

## Out of scope

- **The recipe screen's real content** — ingredients, method, video. The next requirement.
- **Actually buying a class.** The button is a placeholder by the owner's decision.
- **Swift unit or UI tests** — per the platform's Definition of Done, UI is verified by the human.
- **Showing anything concrete about a pending payment** — reference number, date. The requirement
  settled on a short note only, which is why no contract change was needed.
- **A recipe count anywhere on this screen** — explicitly excluded by the owner.

## Test plan

No automated tests — `layer: ui`, and the platform verifies UI by hand.

Built with `xcodebuild` ("DapurNaura Dev") against `ios/DNLibraryLocal`, run on the simulator.
**The human verifies the running app before anything is committed.** What to check, taken from the
requirement's acceptance list — all three states are reachable in the stub (ids `1`, `2`, `3`):

1. Makanan Kekinian (bought) — no buy button, no price, each recipe shows portions and loyang as
   two separate values, tapping a recipe navigates
2. Pastry Dasar (awaiting confirmation) — no buy button **and no price anywhere**, the note is
   shown, tapping a recipe does nothing
3. Jajanan Pasar (not bought) — the button reads `Beli Kelas · Rp125.000`, tapping it shows the
   "belum tersedia" message and buys nothing, tapping a recipe does nothing
4. No recipe count appears in any of the three
5. No ingredients, method or video appear anywhere in the two unbought states

## Implementation notes (2026-08-06)

- **Five new files, three modified.** New: `CookingClassDetail/CookingClassDetailViewModel.swift`,
  `CookingClassDetailView.swift`, `RecipePlaceholderView.swift`, and two shared helpers —
  `Shared/Rupiah.swift` and `Shared/DNError+Message.swift`. Modified: the DN-009 list view and view
  model, plus the composition root.
- **The two helpers were lifted out of DN-009 rather than copied.** The price formatter and the
  Indonesian error vocabulary now exist once. Duplicating the error mapping would have been the
  worse failure: the same network problem would eventually describe itself two different ways
  depending on which screen the user was standing on.
- **Composition stayed at the root.** The list screen receives a
  `(String) -> CookingClassDetailViewModel` factory rather than the data layer itself, so
  `DapurNauraApp` remains the only place that knows a `DNDataLayer` exists. Navigation is
  value-based (`NavigationLink(value:)` + `navigationDestination`), so a detail view model is built
  when a row is opened, not once per visible row.
- **`project.pbxproj` gained nothing.** `DapurNaura/` is a synchronized folder, so the five new
  files joined the target automatically; the file's only diff is still the 21-line local package
  wiring that must never be committed.
- **A stale module cache cost one build cycle, and will do it again.** The first compile failed with
  *"value of type 'GetCookingClassDetailUseCase' has no member 'invoke'"* even though the freshly
  built XCFramework's header and `.swiftinterface` both declared
  `invoke(classId:) async throws`. Xcode had cached the pre-DN-011 module. `xcodebuild clean build`
  fixed it. `publish-spm.sh` prints this warning; it is real, and the symptom looks exactly like a
  wrong API name.
- **Build succeeded** for "DapurNaura Dev" on the iPhone 17 Pro simulator, against
  `ios/DNLibraryLocal` rebuilt with DN-011. A concrete Apple-silicon destination was used, per
  DN-013's x86_64 finding.
- **Nothing is committed.** UI work stops at the human's verification of the running app — that
  gate has not run yet.
- **For commit time:** this ticket's file lives in the umbrella, which currently sits on the DN-013
  branch; its commit belongs on the umbrella's `ticket/DN-012-cooking-class-detail-ui`.

## Done when

UI work:
- [x] Code implemented on `ticket/DN-012-cooking-class-detail-ui`
- [x] All three states verified on the running app by the owner, 2026-08-06 — *"sudah cocok dengan
      keinginan saya"*, the platform's UI gate, run before anything was committed
- [x] `project.pbxproj` kept out of the commit entirely — stronger than grepping it clean; the
      synchronized folder meant no project edit was needed, so the file was never staged
- [x] Committed as `ad281c8` on `ticket/DN-012-cooking-class-detail-ui`, not merged

Always:
- [ ] PR merged, ticket marked `done` by the human
