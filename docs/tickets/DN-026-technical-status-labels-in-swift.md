---
id: DN-026
type: technical
title: PurchaseStatusBadge words a domain enum in Swift, which §10 sends to the library
status: in-review
branch: ticket/DN-026-status-labels-in-swift
layer: ui
---

## Rationale

`PurchaseStatusBadge` turns a DNLibrary enum into user-facing wording in Swift:

```swift
// ios/DapurNaura/DapurNaura/Presentation/CookingClassList/Components/PurchaseStatusBadge.swift
private var label: String {
    switch status {
    case .purchased: "Sudah Dibeli"
    case .pendingVerification: "Menunggu Verifikasi"
    case .notPurchased: "Belum Dibeli"
    }
}
```

iOS `docs/CODEBASE-ARCHITECTURE.md` §10 puts display wording derived from data in DNLibrary, and
names *error wording* as an example — `DNError.userMessage` moved there under DN-016 for exactly
this reason. A status label is the same shape of thing: a total function from a library enum to a
string a user reads. The argument §10 gives applies unchanged — **an Android app is planned, and a
label written in Swift is a label Android reimplements**, after which one platform can say
*"Menunggu Verifikasi"* and the other something almost like it.

**Noticed while implementing DN-024/DN-025**, which put `DNFormat.categoryLabel` in the library for
precisely this reason. The two now sit in the same folder wording library enums two different ways,
and that inconsistency is the actual defect — not the strings themselves, which are correct.

**Not urgent, and deliberately not bundled into DN-025.** Moving these three strings changes wording
the owner has already verified on a running screen, and it costs a library release to land. It should
travel with the next release that is happening anyway, rather than causing one.

## Approach, in outline

- `DNFormat.purchaseStatusLabel(status: PurchaseStatus): String` in DNLibrary, with tests — beside
  `categoryLabel` and `rupiah`.
- `PurchaseStatusBadge` calls it. **The colour stays in Swift**: a tint is view context, not data,
  and §10's boundary is the view.
- `CookingClassDetail`'s pending-verification notice wording is worth checking at the same time — if
  it also words a status in Swift, it belongs in the same move.

## Out of scope

- Any wording change. This moves strings; it does not rewrite them.
- Colours, icons, or anything else in the badge.

## Done when

- [x] `DNFormat.purchaseStatusLabel` exists with tests; `:sharedLogic:check` green — **112 tests**,
      0 failures, up from 108
- [x] `PurchaseStatusBadge` holds no Indonesian string
- [x] The §10 row in the iOS known-violations table records it
- [ ] **Owner has verified the badge still reads correctly on the running app** — the one box the
      agent cannot tick

## Notes

Filed autonomously at `status: todo` — a noticed problem, not a request. **Scheduling it is the
owner's**, per the autonomy table in `CLAUDE.md`.

## Implementation notes

**The detail screen's notice was checked, and deliberately stays in Swift.** The ticket asked whether
`CookingClassDetail`'s pending-verification wording belongs in the same move. It does not, and the
evidence is that the two strings differ for the same state: the badge reads *"Menunggu Verifikasi"*
and `PurchaseSection` reads *"Pembayaran sedang dicek"*. A canonical label of an enum would be one
string; two phrasings of one state is view context — the detail screen has room for a sentence and a
reason to reassure someone who has already transferred money. `DNFormat`'s own contract draws exactly
this line, and only the canonical label crossed it.

Also left in Swift, for the same reason: *"Pembelian lewat aplikasi belum tersedia."* describes the
missing purchase path rather than wording a status.

**The colour stayed too**, as the ticket required — a tint is a decision about this badge on this
surface.

**`isPurchased` was simplified by the owner during review**, and the agent's framing of it was wrong.

```swift
- switch detail.purchaseStatus {          + detail.purchaseStatus == .purchased
-   case .purchased: true
-   default: false
- }
```

The agent had flagged the `default: false` as a latent hazard — *"a new status silently reads as not
purchased"*. **That is true of both versions**, so the change does not address it, and the concern
was misframed to begin with: `isPurchased` is a boolean predicate, not a total mapping. Answering
"is this exactly `PURCHASED`?" is *supposed* to be non-exhaustive, and `false` is the safe default
for a gate over content the server never sent anyway.

What the change actually buys is idiom, and it is worth having: three lines become one that says what
it means, and the `default:` keyword disappears — which matters because that keyword pattern-matches
against the §10-adjacent checklist item *"no `default:` in a switch over a sealed Kotlin type"* and
made a reader stop on code that was never wrong. Removing a false signal is worth a one-line diff.

Verified after the change: `** BUILD SUCCEEDED **`, `swiftlint` 0 violations. It rides in this
ticket's commit — one line, found in this ticket's review, on the same screen family.
