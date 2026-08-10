---
id: DN-036
type: product
title: iOS — the offline class schedule, with collapsible month sections and a materials sheet
status: done
source: docs/requirements/2026-08-09-offline-class-schedule.md
branch: ticket/DN-036-offline-class-schedule-ui
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/15
layer: ui
---

## Requirement (traced)

From [`../requirements/2026-08-09-offline-class-schedule.md`](../requirements/2026-08-09-offline-class-schedule.md),
approved 2026-08-09.

> "A month is a section; a class is a row inside it. […] A section opens and closes, with an arrow at
> its right-hand end. […] A section states how many of its classes can still be joined, as a bare
> number beside the arrow."

> "Each class is drawn as a ticket: a picture on the left, the class and its details in the middle,
> and the month and date standing apart on the right."

> "Every class can be pressed, including a full one. […] Being full removes the button, and nothing
> else."

> "The number of places left is never shown to the reader."

> "It uses the same bottom sheet the app already has."

The data layer is [DN-035](DN-035-product-offline-class-schedule-data.md).

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura/Presentation/CookingClassSelection/` — the entry this replaces
- `ios/DapurNaura/DapurNaura/Presentation/Components/NoticeSheet.swift` — the sheet to extend, and
  its doc comment, which already names the condition under which it should change
- `ios/DapurNaura/DapurNaura/Presentation/CookingClassList/` — the closest existing screen shape
- `ios/DapurNaura/DapurNaura/Presentation/DesignConstants.swift`
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` — §2 (ViewModel contract), §3 (one type per file,
  `Content` from plain values), §4 (routes, and *sheets are not routes*), §7 (three states),
  §9 (semantic fonts, 44pt, shared constants), §10 (no wording derived from data in Swift)

**Depends on DN-035 being built locally**, not merged — `publish-spm.sh local` puts the new API in
`ios/DNLibraryLocal` and the app is pointed at it. That wiring is never committed.

## Technical approach

**1. `OfflineClassSchedule/` — a screen with a ViewModel, unlike the selection screen.**

```
Presentation/OfflineClassSchedule/
├── OfflineClassScheduleView.swift          # ViewModel, .task, title
├── OfflineClassScheduleContent.swift       # three states; screen level
├── OfflineClassScheduleViewModel.swift     # state + which sections are collapsed
├── OfflineClassRoute.swift                 # owned by the feature it opens (§4)
└── Components/
    ├── OfflineClassMonthSection.swift      # header, arrow, count badge, its rows
    ├── OfflineClassRow.swift               # the ticket
    └── OfflineClassAvailabilityBadge.swift # phrase + tint
```

This one fetches, so §7's three states apply in full and `ContentUnavailableView` covers the empty
case — the fallback the requirement asks for without designing it into a feature.

**2. Collapse state lives in the ViewModel, not the section.**

```swift
private(set) var collapsedMonths: Set<String> = []
func toggle(_ monthKey: String)
```

Held above the rows so it survives a reload: the list refreshes on `.task`, and per-section `@State`
would silently reopen every section the reader had closed. It is screen state, not domain state, so
it belongs in the ViewModel rather than the library (§2 allows this — it is not a computation or a
format, it is what the screen is currently showing).

**Both sections start open**, per the requirement, which is what an empty `collapsedMonths` gives —
the default costs no code.

**3. The section header.**

Month title from `DNFormat.offlineClassMonthTitle`, a chevron that rotates on toggle, and the count
of joinable classes as a bare number beside it. **The number is absent, not zero**, when no class in
that month has places left — a `0` beside a chevron reads as an error.

The whole header is one button with a 44pt minimum height (§9).

**4. `OfflineClassRow` — the ticket.**

Picture left, details centre, month and day right, following the owner's reference. Details are the
weekday-and-date line, the class name, the price via `DNFormat.offlineClassPrice`, and the
availability badge.

**The row shows no quota number**, and `OfflineClass.remainingQuota` must not be read anywhere in
Swift. It exists so the library can derive the state; rendering it would publish how many people have
signed up.

The availability colour appears twice — on the badge and as the card's outline — which is the
requirement's *"identifiable by colour"* without tinting the whole card. Colours come from
`DesignConstants`; the *wording* comes from `DNFormat` (§10), the same split DN-026 settled for
`PurchaseStatusBadge`.

Per §4 the row names no `Route`; it takes values and a closure.

**5. `NoticeSheet` grows a bulleted form and an optional button.**

```swift
NoticeSheet(
    isPresented: Binding<Bool>,
    imageURL: String,
    title: String,
    message: String? = nil,
    bullets: [String] = [],
    actionTitle: String? = nil,
    action: (() -> Void)? = nil,
    allowsDragToDismiss: Bool = true
)
```

Owner's instruction, 2026-08-09: reuse the existing sheet rather than build a second one. Its doc
comment already named the trigger — *"split the chrome out when something needs different content"* —
and this is that moment, so the growth is earned rather than speculative.

**`bullets` is a list, not a comma-joined string.** The owner first proposed joining the materials
and splitting on commas; the agent showed that the existing *Segera Hadir* message contains a comma
(*"Mohon ditunggu, ya."*) and would have split into two bullets, and that a material containing a
comma would break the same way. The owner took the list.

**The button is absent when the class is full** — `actionTitle` nil. It reads
`Beli Kelas · HTM Rp150.000` and answers *"Pembelian lewat aplikasi belum tersedia."*, the same
sentence `PurchaseSection` already uses for the same situation.

**6. The Kelas Offline card pushes the schedule** instead of raising the notice.
`CookingClassSelectionView` loses its `offlineNoticeShown` state and its `NoticeSheet` overlay;
`Route` gains `case offlineClasses(OfflineClassRoute)`.

## Public API contract

None. Consumes DN-035's symbols; adds none.

**Version bump implied:** none.

## Out of scope

- **Buying.** The button reports that the app cannot do it, exactly as the online one does.
- **Showing the remaining quota**, in any form.
- **Converting `PurchaseSection` to `NoticeSheet`.** Still the natural second caller of the
  message-only form, and still a change to a screen the owner has already signed off — its own
  ticket, not this one.
- **A month that has no classes**, which DN-035 does not emit and this screen therefore never draws.
- **Swift tests.** UI is verified by the owner on the running app.
- **Android.** Does not exist.

## Test plan

**No automated tests, by policy.** What the owner is asked to check on the running app:

| Check | Expected |
|---|---|
| Tap Kelas Offline | The schedule pushes in, titled **Kelas Offline** — no *Segera Hadir* sheet |
| The sections | One per month with classes, calendar order, both open, arrow at the right |
| The count badge | A bare number of joinable classes; absent for a month where every class is full |
| Collapse a section, pull to reload | It stays collapsed |
| A row | Picture, weekday and date, name, `HTM Rp…`, availability badge — and **no quota number** |
| The three states | Green `MASIH BISA DAFTAR`, yellow `HAMPIR PENUH`, red `SUDAH PENUH`, each also on the card outline |
| Tap a green or yellow row | Sheet: class name, picture, bulleted materials, `Beli Kelas · HTM Rp…` |
| Tap the button | *"Pembelian lewat aplikasi belum tersedia."* |
| Tap the **full** row | The sheet still opens and the materials still read — **no button** |
| Back | Returns to the Kelas Online / Kelas Offline choice |
| Text size cranked up | Rows and sheet stay legible; the ticket does not clip |

`swiftlint lint` 0 violations, and `xcodebuild … build` succeeds — the DN-034 gate.

## Done when

- [ ] The Kelas Offline card pushes the schedule; the *Segera Hadir* overlay is gone
- [ ] Month sections collapse and expand, arrow at the right, collapse surviving a reload
- [ ] The count badge shows joinable classes and disappears rather than showing zero
- [ ] The ticket row renders picture, date, name, price, badge — and no quota anywhere in Swift
- [ ] `NoticeSheet` takes bullets and an optional button, and drops the button when full
- [ ] All wording comes from `DNFormat`; no Indonesian string added in Swift beyond screen chrome
- [ ] `#Preview`s cover loading, failed, empty, and the three availability states
- [ ] `swiftlint lint` clean and `** BUILD SUCCEEDED **`
- [ ] `project.pbxproj` carries no local package reference
- [ ] **Owner has verified the running app**
- [ ] Committed, not merged
- [x] PR merged — DapurNaura-iOS#15, merge commit `80a879f4`, 2026-08-10

## Implementation notes (2026-08-09)

**`NoticeSheet` had to give up two pieces to stay under the 200-line limit**, and both are genuine
components rather than fragments split off to satisfy a linter:

- **`NoticeBulletList`** — a list read down its left edge, which is why it is leading-aligned while
  the paragraph beside it is centred.
- **`SheetCloseButton`** — the floating X, unchanged in behaviour.

§3's `file_length` rule exists as *"pressure toward extracted View structs"*, and this is that
pressure working as designed.

**The paragraph form of `NoticeSheet` now has no caller.** The *Segera Hadir* notice was the only
one, and this ticket replaced it with a real screen. The parameter is kept — the owner asked for the
sheet to keep serving notices — and a `#Preview` keeps it visible so it is not silently lost.
`PurchaseSection` remains its natural second caller, in its own ticket.

**The stale-artifact trap fired again** (known issue 5). After switching to the local package the
build reported `cannot find type 'OfflineClassAvailability' in scope` while every other DNLibrary
type in the same file resolved — with the symbol demonstrably present in the framework header. The
documented fix cleared it:

```sh
xcodebuild … clean
rm -rf ~/Library/Developer/Xcode/DerivedData/DapurNaura-<hash>/SourcePackages
```

**`publish-spm.sh local` takes the app directory, not the `ios` directory.** It derives the package
location as `<ios-project-dir>/../DNLibraryLocal`, so passing `../ios` writes to the workspace root
rather than `ios/DNLibraryLocal`. The correct call is `./scripts/publish-spm.sh local ../ios/DapurNaura debug`.

**The local package is not optional this time.** `SPMDNLibrary` is private as of 2026-08-09, so its
release asset 404s and the remote dependency cannot resolve at all — the committed pin is
unbuildable until the owner makes that repository public again. The working tree therefore carries
the local wiring, and **it must not be committed**, exactly as the rule already says.

**Verified as far as an agent can.** `** BUILD SUCCEEDED **` on `DapurNaura Dev`, iPhone 17 Pro
simulator by id; `swiftlint lint` 0 violations. Tapping, collapsing and the sheet are the owner's
check — a tap needs a UI test this ticket does not add.

## Revisions during review (2026-08-10)

Four corrections from the owner on the running app. **The first two change the approved
requirement**, so it carries `corrected-by: DN-036` in its frontmatter and its prose is untouched —
the record of what was asked stays as it was asked.

1. **The availability colour is on the badge only.** The requirement had it *"carried on the class's
   outline and on the phrase's own background"*, and the day number picked it up too. Three things
   saying one thing turned a list into noise. The outline is now a neutral hairline and the date is
   plain; the badge alone carries the state, and it still carries the phrase, so nothing is
   communicated by colour alone.
2. **The buy button carries no price.** The requirement specified *"Beli Kelas · HTM Rp150.000"*. The
   price is already on the row the reader just pressed, and repeating it made the button the widest
   thing in the sheet for no new information. It now reads **Beli Kelas**.
3. **The navigation bar sat on top of the sheet**, back button and all. The sheet is an `.overlay` on
   this screen's *content*, and a `NavigationStack` draws its bar **above** content — so no overlay
   inside the stack can cover it. Apple's `.sheet` escapes this by presenting outside the hierarchy,
   which the owner ruled out in DN-033. The bar is therefore hidden while the sheet is up.
4. **Expand, collapse and the sheet are animated.**

**The sheet was appearing with no animation at all, and the reason is worth keeping.** It was built
inside `if let selectedClass`, so the view was *inserted* with `isPresented` already true — there was
no false-to-true change for `NoticeSheet`'s own animation to run against, and the transition never
fired. It is now mounted unconditionally and driven by a separate `isSheetShown`, with
`selectedClass` deliberately **not** cleared on dismiss: blanking the content the moment the sheet
starts leaving would animate an empty card off the screen.

A conditional view cannot animate its own arrival. That is the general lesson, and it will apply to
the next overlay someone writes here.
