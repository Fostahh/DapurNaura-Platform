---
id: DN-033
type: product
title: iOS — open on a choice between Kelas Online and Kelas Offline, with a reusable "not built yet" sheet
status: done
source: docs/requirements/2026-08-09-cooking-class-selection-entry.md
branch: ticket/DN-033-cooking-class-selection-entry
commit: 5089dc9
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/14
layer: ui
---

## Requirement (traced)

From [`../requirements/2026-08-09-cooking-class-selection-entry.md`](../requirements/2026-08-09-cooking-class-selection-entry.md),
approved 2026-08-09:

> "I want it changed to CookingClassSelection. […] it does not need data from remote, this is only
> static data. If Kelas Online is pressed, then navigate to ListCookingClass. If Kelas Offline is
> pressed, show a bottom sheet containing a Placeholder Image with a fixed height size and text
> describing that the feature is being built, please wait."

> "No need for a button at the bottom of the bottom sheet, insert a floating view with an X icon […]
> make this bottom sheet a component that will be shared across screens, make it customisable, such
> as receiving an image and also text in its init parameters."

> "Yes there is a back button, and the title becomes Kelas Online."

Settled with the owner on 2026-08-09, before drafting:

- **Kelas Offline is not dimmed or disabled** — it is pressed like any other card, and the sheet
  answers it.
- **No artwork.** Placeholder URLs in the `https://placehold.co/...` style the contract fixtures
  already use.
- **Screen title `Dapur Naura`**; cards pink and salmon, per the reference image.
- **All user-facing wording was the agent's proposal and the owner accepted it in full.** It is a
  table in the requirement, and this ticket must not reword it.

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura/App/DapurNauraApp.swift` — the composition root, whose `WindowGroup`
  is what this ticket changes
- `ios/DapurNaura/DapurNaura/App/Navigation/` — all four files
- `ios/DapurNaura/DapurNaura/Presentation/CookingClassList/CookingClassListView.swift` — currently
  owns the `NavigationStack` and the app's only `navigationDestination`
- `ios/DapurNaura/DapurNaura/Presentation/Components/RemoteImage.swift`
- `ios/DapurNaura/DapurNaura/Presentation/DesignConstants.swift`
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §3 (one type per file, `Content` from plain values),
  §4 (single registration, `NavigationLink(value:)`, route ownership, sheets are not routes),
  §9 (semantic fonts, 44pt targets, shared constants), §10 (no wording derived from data in Swift)

**No DNLibrary work.** The screen is static, so there is no use case, no `publish-spm.sh` run, no
version bump, and the app stays on the committed remote package throughout. This is the *"No (UI
only) → straight to `ios/DapurNaura/`"* branch of the workflow.

## Technical approach

**1. The `NavigationStack` moves up, and the class list stops being the root.**

`CookingClassListView` owns the stack and the app's single `navigationDestination` today. Both move
to `CookingClassSelectionView`, which becomes the `WindowGroup`'s content. The list then loses its
`factory` and its `@Environment(DapurNauraAppRouter.self)` — it becomes an ordinary pushed screen
with a ViewModel and a title.

§4's rule that the registration must sit on **content that always renders** is why it moves rather
than being duplicated: the selection screen has no state switch at all, so it is the safest place
the registration has ever sat.

**2. A new route, owned by the feature it opens (§4).**

```swift
// CookingClassList/CookingClassListRoute.swift
enum CookingClassListRoute: Hashable {
    case list
}

// Navigation/Route.swift
enum Route: Hashable {
    case classList(CookingClassListRoute)
    case classes(ClassRoute)
    case recipes(RecipeRoute)
}
```

**Why a one-case enum rather than a bare `case classList` on `Route`.** §4 splits routes per feature
and wraps them, and the wrapper is dropped only at module boundaries — not when a case looks small.
It also has a concrete next case: the list already filters by category, so a deep link into
*Kelas Online, Baking* is `case list(category:)` here, added without touching `Route`. `ClassRoute`
could not host it — that file lives in `CookingClassDetail/`, and a route is owned by the feature it
navigates **into**.

**3. `CookingClassSelection/` — a screen with no ViewModel, deliberately.**

§1 puts a ViewModel between the view and a use case. There is no use case here: the two choices are
literals, nothing is fetched, and §7's three states do not exist because nothing can fail. A
ViewModel would hold no state and forward no events. **This is not a precedent for skipping one on a
screen that loads anything** — it is the absence of the thing a ViewModel exists to manage.

```
Presentation/CookingClassSelection/
├── CookingClassSelectionView.swift        # stack, destination registration, sheet state
├── CookingClassSelectionContent.swift     # the two cards; screen level, so it may name Route
└── Components/
    └── ClassKindCard.swift                # picture, title, subtitle, tint — no Route (§4)
```

**The two cards are written out literally, not iterated over a Swift enum.** A `ClassKind` enum
carrying Indonesian labels would be a domain enum worded in Swift, which is exactly what DN-026 took
out of `PurchaseStatusBadge`. These are not two instances of a type — they are two different things
that do two different things, and a collection of two with a `switch` on the element to decide the
action is longer than writing both.

Static screen copy in Swift stays in Swift. §10 governs wording **derived from data** — a status, a
price, an error. `navigationTitle("Kelas Online")` and a card's subtitle are neither, and the app
already holds this kind of string (`"Beli Kelas"`, `"Coba Lagi"`).

**4. Online pushes with `NavigationLink(value:)`; offline sets sheet state.**

Per §4 `NavigationLink(value:)` is the only permitted form, and per §3 the `Content` view is screen
level so it may name `Route`. `ClassKindCard` takes values and nothing else; the link and the button
wrap it from outside. The sheet is `@State` on `CookingClassSelectionView` — **sheets are not
routes** (§4).

**5. `NoticeSheet` — shared, in `Presentation/Components/`, and written by hand.**

```swift
NoticeSheet(
    isPresented: Binding<Bool>,
    imageURL: String,
    title: String,
    message: String,
    allowsDragToDismiss: Bool = true
)
```

It lands at shared scope rather than feature scope even though this ticket gives it one caller, and
§3's *"a component moves up on its second consumer"* is satisfied rather than waived:
[`PurchaseSection`](../../ios/DapurNaura/DapurNaura/Presentation/CookingClassDetail/Components/PurchaseSection.swift)
already shows the same *not available yet* message as an alert. **That second caller is not
converted here** — see *Out of scope*.

**It is not built on `.sheet`.** Owner's instruction, 2026-08-09: *"I want this Bottom Sheet to be
its own Custom View, not Apple's framework API."* It is a `ZStack` the caller puts in an `.overlay`
— a scrim, a card that transitions in from the bottom edge, and a drag gesture. Two things fall out
of that, and both were requirements the `.sheet` version had to fight for:

- **The X floats above the card**, which is where the owner asked for it. Nothing drawn inside a
  `.sheet` escapes the sheet's own background, so the `.sheet` version had to clear that background
  with `.presentationBackground(.clear)` and draw a fake surface to have anywhere to float in.
- **The height follows the content.** `.presentationDetents` needs a number, so the `.sheet` version
  measured its own content with a `GeometryReader` and fed the result back into the detent — a loop
  whose first frame was a guess, with an over-estimating fudge factor to keep the error on the
  invisible side. A `VStack` is already the height of what is in it. All of that is deleted.

**The cost is stated in the file**: the system behaviours `.sheet` supplied are now ours to write.
Drag-to-dismiss is implemented **behind `allowsDragToDismiss`**; anything else found missing has to
be added there rather than inherited.

**The flag defaults to `true`, and this ticket's only call site passes `false`** — owner's decision,
2026-08-09: not needed on the Kelas Offline notice yet, but the behaviour should be there for the
next caller. The default points that way deliberately, so a later screen gets the conventional
behaviour without knowing the flag exists, while opting out stays visible at the call site.

The gesture is attached unconditionally and gated by its mask —
`including: allowsDragToDismiss ? .all : .subviews`. **`.subviews`, never `.none`:** `.none`
disables every gesture in the subtree, which includes the close button's tap, leaving no way out of
a sheet that can no longer be dragged away. Gating the mask also keeps one code path, where a
`some Gesture` that sometimes exists would have to be erased or duplicated to type-check.

- **The picture is a fixed height**, per the requirement — so one notice cannot be twice the size of
  another. The *sheet* is content-sized; the *picture inside it* is not.
- **44pt tap target on the X** (§9), drawn as a 32pt disc.
- **Tapping the scrim also closes it.** Not asked for; added because a modal backdrop that swallows
  taps and does nothing reads as a frozen screen. Flagged to the owner rather than slipped in.
- **The four parameters are the whole customisation.** No `content:` closure. Both callers in sight
  want the same shape — a picture, a heading, a line of explanation — so the sheet is not generic
  over its content. Split the chrome out into its own view when something needs different content,
  **not before**.

**6. `DesignConstants` gains the card and sheet values** (§9 — no colour or radius literals in a
view). The file starts importing SwiftUI to hold two `Color`s; it is a Presentation-layer file, and
§2's no-SwiftUI rule is about ViewModels.

## Public API contract

None. No DNLibrary symbols are added, changed or consumed beyond what already exists.

**Version bump implied:** none. No library change, no release, no repin.

## Out of scope

- **Building Kelas Offline.** This delivers the choice and the notice, nothing behind them.
- **Converting `PurchaseSection`'s alert to `NoticeSheet`.** It is the obvious second caller and the
  reason the component is shared, but it changes a message on a screen the owner did not ask about,
  on a card they have already signed off. Worth a separate ticket once `NoticeSheet` has been seen
  running.
- **Remembering the choice** between launches, or skipping the screen for a returning user.
- **Any change to the class list** other than its title and the fact that it is now pushed — its
  category filter, rows and behaviour are untouched.
- **Real artwork.** Placeholder URLs throughout.
- **Swift tests.** UI is verified by the owner on the running app; `ios/DapurNaura/CLAUDE.md` says
  not to add them unless a ticket asks.
- **Android.** Does not exist.

## Test plan

**No automated tests, by policy.** What the owner is asked to check on the running app:

| Check | Expected |
|---|---|
| Launch the app | The choice screen, titled `Dapur Naura`, two cards — Kelas Online above Kelas Offline |
| Both cards | Equally bright; offline is not dimmed or marked unavailable |
| Tap Kelas Online | The class list pushes in, titled **Kelas Online**, chips and classes as before |
| Back from the list | Returns to the choice screen |
| Open a class, then a recipe, then back twice | Still works — the destination registration survived the move |
| Tap Kelas Offline | A bottom sheet with a picture at a fixed height and the wording from the requirement |
| The sheet's X | Floating **above** the card, top-trailing, closes the sheet |
| Swipe the sheet down | **Nothing** — drag is off at this call site. The X and the backdrop are the ways out |
| The `Pesan panjang` preview | Drag is on there (the default), so a drag past 120pt closes it and a shorter one springs back |
| Tap the dimmed backdrop | Also closes it |
| A longer message | Makes the sheet taller rather than clipping — check the `Pesan panjang` preview |
| Tap Kelas Offline again | Opens again cleanly |
| Text size cranked up | Cards and sheet stay legible; nothing clips |

`swiftlint lint` must report 0 violations, which is the standing state since DN-016.

**What an agent cannot verify** is the same limit as DN-025: a tap needs a UI test this ticket does
not add, so every row of the table above is the owner's check. The agent verifies that it compiles
and lints clean, and nothing more — DN-034 scopes the gate to a build, with no simulator run.

## Done when

- [x] `CookingClassSelectionView` is the `WindowGroup`'s content, owning the `NavigationStack` and
      the app's single `navigationDestination`, with `.id(route)` intact
- [x] `CookingClassListView` no longer owns a stack or a factory, and is titled `Kelas Online`
- [x] `CookingClassListRoute` lives in the list feature's folder and is wrapped by `Route`
- [x] `ClassKindCard` names no `Route`; the link and the button wrap it from outside
- [x] `NoticeSheet` is in `Presentation/Components/`, is our own view rather than `.sheet`, takes
      image URL, title and message, sizes itself to its content, and closes by a floating X
- [x] Wording matches the requirement's table exactly
- [x] `#Preview`s for the content, the card and the sheet
- [x] `swiftlint lint` clean, and `xcodebuild … build` reports `** BUILD SUCCEEDED **` — the gate
      DN-034 introduced, whose first application this is
- [x] `project.pbxproj` carries no local package reference — nothing here needs one
- [x] **Owner has verified the running app**
- [x] Committed, not merged
- [x] PR opened
- [x] PR merged — [DapurNaura-iOS#14](https://github.com/Fostahh/DapurNaura-iOS/pull/14),
      merge commit `2621092`, 2026-08-09. **The umbrella docs branch is pushed and still needs
      merging into `development`** — it takes no PR by policy

## Revisions during review (2026-08-09)

Three corrections from the owner while checking the previews, recorded because each changed a
decision rather than a detail:

1. **The card title rendered underneath its picture.** The card reserved `classCardImageOverlap` of
   head room — the part of the circle rising *above* the card. The part that matters is the part
   hanging *inside* it, which is the complement. Fixed as a derived value,
   `classCardImageHeadRoom = imageSize - imageOverlap + rowSpacing`, so changing either input cannot
   reintroduce it.
2. **The X was to float above the sheet, not sit inside it**, and the sheet was to size itself to its
   content instead of `.medium`.
3. **The sheet was to be our own view, not `.sheet`** — which subsumed (2) and deleted the
   workarounds it had needed. See *Technical approach* §5.
4. **The card is full width with only its top corners rounded**, its fill carried through the home
   indicator, and **the close control is a rounded square rather than a disc.** Given as a reference
   screenshot from another app, with *"the content is already right"* and *"no button"* — so only
   the sheet's frame and the close control changed, and the picture, heading and message were left
   alone. Worth recording that the inset floating-card look this replaced was **not** a design
   choice: it was forced by `.sheet`, which cannot paint below its own safe area. Owning the view
   is what made the reference reachable.
5. **Drag-to-dismiss was not wanted at this call site**, so it became a flag rather than a deletion.
   The owner had commented the gesture out; it is restored behind `allowsDragToDismiss`.

**One process failure, recorded because the fix is a habit and not a rule — and because the history
no longer shows it.** The owner's commented-out gesture and a placeholder `Text` used to check that
the sheet grows with its content were both **committed by the agent**: it staged files by path —
correctly, never `git add -A` — but did not read the diff before committing. **Staging explicitly
and reviewing what is staged are different acts**, and only the second catches someone else's
work-in-progress sitting in a file you are about to commit.

The placeholder was 249 characters on one line, so `swiftlint` had gone from its standing 0
violations to one error and two warnings — while the agent reported it clean, from a run made
*before* the owner's edit. **Reporting a check as passing without re-running it after the file
changed is the same failure a second time**, and it is the one worth remembering: the build gate
DN-034 added would not have caught either, because both compiled.

The owner caught it, and authorised an amend before the branch was pushed — so the commits read as
though it never happened. That is exactly why it is written here.

## Notes

**The first ticket whose screen fetches nothing.** Every screen so far has been a rendering of a
`DNDataLayer` call, and the rules in `CODEBASE-ARCHITECTURE.md` are written for that shape. Two of
them do not apply here and the reasoning is recorded above rather than left to be re-argued: no
ViewModel (§1/§2), and no three-state switch (§7).
