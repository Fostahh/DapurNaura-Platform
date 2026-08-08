---
id: DN-026
type: technical
title: PurchaseStatusBadge words a domain enum in Swift, which §10 sends to the library
status: todo
branch: —
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

- [ ] `DNFormat.purchaseStatusLabel` exists with tests; `:sharedLogic:check` green
- [ ] `PurchaseStatusBadge` holds no Indonesian string
- [ ] The §10 row in the iOS known-violations table records it
- [ ] Owner has verified the badge still reads correctly on the running app

## Notes

Filed autonomously at `status: todo` — a noticed problem, not a request. **Scheduling it is the
owner's**, per the autonomy table in `CLAUDE.md`.
