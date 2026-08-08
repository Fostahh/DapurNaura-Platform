---
id: DN-025
type: product
title: iOS — category filter chips on the cooking-class list
status: done
source: docs/requirements/2026-08-08-cooking-class-category-filter.md
branch: ticket/DN-025-cooking-class-category-filter-ui
commit: f076cd1
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/11
layer: ui
---

## Requirement (traced)

From [`../requirements/2026-08-08-cooking-class-category-filter.md`](../requirements/2026-08-08-cooking-class-category-filter.md),
approved 2026-08-08:

> "The filter takes the form of a Chip View, and its position is below the screen title and above the
> cooking-class list."

Settled with the owner the same day, before drafting:

- **One chip active at a time**, with a `Semua` chip first, which is what the screen opens on.
- **The chips stay reachable while the list below is loading or failed** — a consequence of the
  owner's choice to filter on the server: every chip tap is a request, and a filter that cannot be
  changed or cleared during that request is a trap.
- **A category with no classes says so** rather than showing a blank screen. `[ASSUMPTION]` the
  wording — *"Belum ada kelas di kategori ini."*

The data layer is [DN-024](DN-024-product-cooking-class-category.md).

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura/Presentation/CookingClassList/` — all four files
  (`CookingClassListView`, `CookingClassListContent`, `CookingClassListViewModel`,
  `Components/CookingClassRow`, `Components/PurchaseStatusBadge`)
- `ios/DapurNaura/DapurNaura/Presentation/DesignConstants.swift`
- `ios/DapurNaura/DapurNaura/Presentation/Components/LoadFailedView.swift`
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §2 (ViewModel contract), §3 (one type per file,
  `Content` constructible from state), §7 (`ContentUnavailableView` for empty), §9 (44pt targets,
  semantic fonts, shared constants), §10 (no wording in Swift)
- `ios/DapurNaura/CLAUDE.md` — the local package rule

**Depends on DN-024 being built locally**, not merged: `publish-spm.sh local` puts the new API in
`ios/DNLibraryLocal` and the app is pointed at it. That wiring is never committed.

## Technical approach

**1. The ViewModel owns the selection and reloads on change.**

```swift
private(set) var selectedCategory: CookingClassCategory?      // nil == Semua

func select(_ category: CookingClassCategory?) async {
    guard category != selectedCategory else { return }
    selectedCategory = category
    await load()
}
```

**Re-tapping the active chip does nothing.** Owner's revision, 2026-08-08, made while verifying the
screen: *"If the chip state isSelected = true, then user tap it again, no need to recall the API."*
The list on screen is already that category's answer, and refetching would replace it with a spinner
to arrive at the same list. `[ASSUMPTION]` this holds in the failed state too — the failure keeps its
own *Coba Lagi*, so re-tapping is not the only way back from one.

`State` keeps its three cases — the selection is not a fourth state, it is what the next load asks
for. The View wraps `select` in a `Task`, matching how `onRetry` already calls `load`.

**2. A stale response must never win.** `load()` captures the category it asked for and discards its
own result if the selection moved on while it was in flight:

```swift
let requested = selectedCategory
let result = try await getCookingClasses.invoke(category: requested)
guard requested == selectedCategory else { return }
```

This is the requirement's checkable statement *"the list that finally appears matches the chip that
is active"*. The ViewModel is `@MainActor`, so the comparison is not racing anything; the guard is
about ordering, not about threads. It is deliberately not solved by cancelling the previous task —
two requests are cheap, and cancellation would still need this guard to be correct.

**3. `CategoryFilterChips`** — new, in `CookingClassList/Components/`, used by one feature so it
stays at feature scope (§3: a component moves up on its second consumer, not in anticipation).

A horizontally scrolling row of capsule buttons. Labels come from `DNFormat.categoryLabel` per §10 —
the component holds no wording of its own. The order is `[nil, .minuman, .baking, .cooking]`, written
explicitly rather than derived from the Kotlin enum's entries: chip order is a screen decision, and
SKIE's `CaseIterable` bridging is not something to depend on for it.

Per §4 nothing below screen level names `Route`; these chips take a value and a closure.

**4. `CookingClassListContent` gains the chips above its state switch**, and takes
`selectedCategory` plus `onSelectCategory` alongside `state`. It stays constructible from plain
values, so every combination — loading with `Baking` active, failed with `Semua` active — is
previewable (§3).

The chip row sits **outside** the switch, which is what keeps it visible and tappable in all three
states. This is the same structural rule as §4's single `navigationDestination`: what must survive a
state change cannot live inside the branch.

**5. The empty category** uses `ContentUnavailableView` per §7, not a hand-rolled `Text`. It is
reached through `case .loaded` with an empty array — an empty result is a successful load, not a
failure, and must not offer *Coba Lagi*.

## Public API contract

None. This ticket adds no library symbols; it consumes DN-024's. No version bump.

## Out of scope

- **Showing a class's category on its row** — a badge beside `PurchaseStatusBadge`. Not asked for;
  the requirement lists it as out of scope.
- **Remembering the selection between launches.** Every launch opens on `Semua`.
- **Filtering the class-detail or recipe screens.** Untouched by this ticket.
- **Swift tests.** UI is verified by the owner on the running app; the platform Definition of Done
  requires tests for the data layer only, and `ios/DapurNaura/CLAUDE.md` says not to add them unless
  a ticket asks.
- **Android.** Does not exist.

## Open questions

- **The `Cooking` chip's wording** — inherited from the requirement. It is a `DNFormat` string, so
  changing it is a library release, not an app edit. Flagged again here because this is the ticket
  where the owner will actually see the word on screen.

## Test plan

**No automated tests, by policy.** What replaces them, and what the owner is asked to check on the
running app:

| Check | Expected |
|---|---|
| The screen opens | chips `Semua · Minuman · Baking · Cooking` between the title and the list, `Semua` active, all three classes listed |
| Tap `Baking` | only *Makanan Kekinian* |
| Tap `Cooking` | only *Pastry Dasar* |
| Tap `Minuman` | only *Jajanan Pasar* |
| Tap `Semua` again | all three back |
| Tap the chip that is already active | nothing happens — no spinner, no request |
| Tap two chips quickly | the list that settles matches the chip left active — never the earlier one |
| While the list is loading | the chips are still visible and still tappable |
| Text size cranked up | chips stay legible and tappable; the row scrolls rather than truncating |

`swiftlint lint` must report 0 violations, which is the standing state since DN-016.

## Done when

- [x] `CategoryFilterChips` exists at feature scope; labels come from `DNFormat`
- [x] The chip row sits between the title and the list and survives every state
- [x] Selecting a chip refetches through `GetCookingClassesUseCase`, and a stale response cannot win
- [x] An empty category shows `ContentUnavailableView`, not a spinner or a blank list
- [x] `#Preview`s cover loading, failed, loaded, and empty-with-a-category-active
- [x] `swiftlint lint` clean; app builds and runs against `ios/DNLibraryLocal`
- [x] Re-tapping the active chip issues no request (owner's revision, 2026-08-08)
- [x] **Owner has verified the running app** — approved 2026-08-08
- [x] Committed, not merged — `f076cd1`. `project.pbxproj` and `Package.resolved` were left
      unstaged rather than reverted, so the index carries the remote pin while the working tree keeps
      the local package; the staged file was grepped clean before committing.
- [x] PR opened — [DapurNaura-iOS#11](https://github.com/Fostahh/DapurNaura-iOS/pull/11)
- [ ] PR merged, ticket marked `done` by the human
- [ ] Repinned to SPMDNLibrary `0.6.0` after DN-024 is published

## Implementation notes (2026-08-08)

**Swapping to the local package left a stale module that fails in a very misleading way.** After the
`project.pbxproj` switch, the build reported:

```
CategoryFilterChips.swift:17:19: error: cannot find type 'CookingClassCategory' in scope
```

while every *other* DNLibrary type in the same files resolved — and the framework already sitting in
`Build/Products` did contain `categoryFilterLabel` and `enum CookingClassCategory` in its
`.swiftinterface`. So the symbol was present and the compiler still could not see it. What cleared it:

```sh
xcodebuild … clean
rm -rf ~/Library/Developer/Xcode/DerivedData/DapurNaura-<hash>/SourcePackages/artifacts/spmdnlibrary
```

The leftover remote artifact directory is what makes this worth writing down — a plain rebuild does
not remove it, and the error it produces looks like a missing symbol rather than a stale cache. It is
the same family of trap as the `0.5.0` fingerprint incident: SPM state that survives a rebuild.

**`-destination 'platform=iOS Simulator,name=iPhone 16 Pro'` fails by dumping the whole device
list.** The iOS 18.3.1 runtimes offer that name as both `arch:arm64` and `arch:x86_64`, and the
XCFramework has no x86_64 slice (known issue 2 in `ios/DapurNaura/CLAUDE.md`). **Build by simulator
id**, which is unambiguous:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=<sim-uuid>' build
```

**Verified as far as an agent can.** `** BUILD SUCCEEDED **`, `swiftlint lint` 0 violations, and the
app installed and launched on an iPhone 17 Pro simulator — the chip row renders
`Semua · Minuman · Baking · Cooking` between the title and the list, with `Semua` filled and all
three classes below it. **Tapping is not verified**: driving a tap needs a UI test this ticket does
not add, so the filtering itself is the owner's check. The behaviour underneath it is covered by
DN-024's stub tests.

## Notes

`PurchaseStatusBadge` holds its three Indonesian labels in Swift, which is the same class of thing
§10 sends to the library — and this ticket now puts category labels there, so the two sit side by
side in one folder wording data two different ways. Filed as
[DN-026](DN-026-technical-status-labels-in-swift.md) rather than fixed here: it is not this
requirement's scope, and moving it changes a string the owner has already verified on screen.
