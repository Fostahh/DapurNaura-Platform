---
id: DN-040
type: product
title: iOS — the login screen, a reusable toast, and a hex colour palette
status: done
source: docs/requirements/2026-08-10-login.md
branch: ticket/DN-040-login-screen
commit: 70ed003
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/20
layer: ui
---

## Requirement (traced)

From [`../requirements/2026-08-10-login.md`](../requirements/2026-08-10-login.md), approved
2026-08-10:

> "A screen, no API call."

> "Login is the entry."

> "If logged in, navigate to CookingClassSelection and User unable to go back to the login screen."

> "The requirement for now is email and password must be filled if wanted to logged in. If user
> tapped login and the textfields are empty, then show a toast at the top underneath dynamic island
> (if have) and the padding top, trailing and leading should be 8."

> "What i mean validation is the validation of the textfield, but login validation is exist."

> "If both empty show email dan password harus diisi, if one of them empty, just follow the previous
> sentence but which field is empty."

> "It goes away after several second, i want to set it to 3 second. The Toast should be reusable, it
> has 3 state, error, information, and succeed. White > Information, Succeed > Green, Error > Red."

Settled with the owner on 2026-08-10, before approval:

- **Any credentials get in.** Nothing is sent, checked or stored — the only gate is that both boxes
  are non-empty.
- **`Lupa Password?`, `Lanjutkan dengan Google` and `Sign up` all show the existing `NoticeSheet`.**
  Only `Login` leads anywhere.
- **The toast is outlined**, carries **text and no icon** (*"for now"*), and clears after 3 seconds.
- **Password autofill is on.**
- **The Google mark is not supplied** — *"for now just create the UI without image asset."*
- **Colours are the agent's to choose**, then the owner's to revise: *"the color, for now you decide,
  after i tested it later, i will decide."* Same for every spacing below the Login button.
- **Colours live in `DesignConstants`**, as hex-backed variables: *"just move them into
  DesignConstants then, it already there, use the existing place to store colorpallete, FOR NOW ya."*

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura/App/DapurNauraApp.swift` — the composition root, whose `WindowGroup`
  this ticket changes for the second time (DN-033 was the first)
- `ios/DapurNaura/DapurNaura/Presentation/CookingClassSelection/CookingClassSelectionView.swift` —
  owns the `NavigationStack` and the app's single `navigationDestination`. **This ticket must not
  move either.**
- `ios/DapurNaura/DapurNaura/Presentation/Components/NoticeSheet.swift` — the "not built yet" sheet,
  and the precedent for how a shared overlay component is built here
- `ios/DapurNaura/DapurNaura/Presentation/DesignConstants.swift` — gains the palette
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §1/§2 (ViewModels), §3 (one type per file,
  `Content` from plain values), §4 (navigation, sheets are not routes), §5 (composition root),
  §7 (three states), §9 (semantic fonts, 44pt targets, shared constants), §10 (wording)

**DN-039 lands first**, and this ticket depends on it: the screen is the first built from fixed
colours rather than adaptive ones, and without the light-mode lock it renders white-on-white in dark
mode. Owner's scheduling, 2026-08-10.

**No DNLibrary work.** Nothing is fetched. No use case, no `publish-spm.sh` run, no version bump, no
repin — the *"No (UI only) → straight to `ios/DapurNaura/`"* branch of the workflow.

**This is the first screen in the app with a text field.** Nothing before it takes keyboard input, so
focus, field styling, autofill and keyboard avoidance have no precedent here to follow.

## Technical approach

### 1. The root swaps; it does not push

The requirement says the login screen cannot be returned to. That rules out pushing
`CookingClassSelection` onto the stack and hiding a back button — a hidden back button is still a
back gesture, and the login screen would sit underneath the whole app for the rest of the session.

Instead `DapurNauraApp` chooses which view is the `WindowGroup`'s content:

```swift
@State private var hasPassedLogin = false

WindowGroup {
    if hasPassedLogin {
        CookingClassSelectionView(factory: factory).environment(router)
    } else {
        LoginView(onLogin: { hasPassedLogin = true })
    }
}
```

`CookingClassSelectionView` keeps the `NavigationStack` and the destination registration exactly as
DN-033 left them. **Nothing about existing navigation changes** — the login screen is not in the
stack at all, so there is no route, no back button and nothing to suppress.

**It is called `hasPassedLogin`, not `isLoggedIn`, and the name is the point.** Nobody is logged in:
no credential was checked, no session exists, no identity is known. The platform's standing blocker
of 2026-08-06 defers all of that, and a flag called `isLoggedIn` would be the first thing to quietly
contradict it — the next screen to need a user would find something that looks like an answer.
**Nothing resembling a session store, an auth state object or a user model is introduced here.** One
boolean at the composition root, meaning *this launch has been past the login screen*, and it is
`@State` so it dies with the process — which is what makes *"every launch starts here"* fall out
rather than be implemented.

### 2. `Presentation/Login/` — with a ViewModel

```
Presentation/Login/
├── LoginView.swift             # screen: the notice sheet, the toast's clock, navigation
├── LoginViewModel.swift        # what was typed, and whether it is enough to go in
├── LoginContent.swift          # the layout, from plain values and closures
└── Components/
    └── LoginTextField.swift    # grey rounded field: icon, placeholder, optional reveal
```

**Owner's instruction, 2026-08-10, and it reverses this ticket's first plan.** The screen was built
without one, following DN-033's reasoning for the first screen that fetches nothing: §1 puts a
ViewModel between a View and a use case, and there is no use case here. Asked where validation
belongs, the owner answered *"ViewModel now"*, and the argument that settles it is testability —
logic in a View can only be exercised by driving the UI, while `attemptLogin()` is a function call.

`LoginViewModel` holds `email`, `password` and the toast, and answers one question. Three things
about it, all in the file:

- **No `State` enum**, which §2 otherwise requires. Loading, loaded and failed are the outcomes of
  *fetching something*, and this screen fetches nothing. The enum arrives with real authentication.
- **`email` and `password` are not `private(set)` where `toast` is.** §2's rule governs state the
  ViewModel derives and publishes outward; these two are input flowing the other way, and a
  `TextField` needs somewhere to put it.
- **It decides, it does not navigate.** `attemptLogin()` returns a `Bool` and the View acts on it —
  §4, and the router's own rule that a View may push while a ViewModel may not.

**On §10 and the Indonesian strings.** Wording *derived from data* belongs in DNLibrary — that is
what DN-026 enforced. These are static screen copy chosen by which box was left empty, and the
library has no notion of a login form to derive them from. They move there when credential rules
become real and Android needs the identical ones.

**It is built through `ViewModelFactory`** even though it injects nothing, so that the day login
gains a use case the wiring already has a home and no call site moves.

`LoginTextField` takes values and closures and names no `Route` (§3/§4). The reveal control is on the
password field only, and the field swaps between `SecureField` and `TextField` — **the swap must keep
focus**, which is the one thing that shape gets wrong by default. A single `@FocusState` binding held
across both branches is what fixes it.

### 3. Screen copy stays in Swift

§10 governs wording **derived from data** — a status, a price, a library error. Every string here is
static screen copy about a UI condition, the same category as `"Beli Kelas"` and `"Coba Lagi"`, and
the same argument DN-033 made for its card subtitles. **The exact strings come from the requirement's
wording table and this ticket must not reword them**, including the English words the design uses.

### 4. `Toast` — shared, three kinds, presented as an overlay

`Presentation/Components/Toast.swift`, following `NoticeSheet`'s shape rather than inventing a second
one: a view the caller puts in an `.overlay`, not a system presentation.

```swift
enum ToastKind { case information, success, error }

Toast(kind: ToastKind, message: String, isPresented: Binding<Bool>)
```

**It takes a value and an `onDismiss`, not a `Binding`.** Changed when the ViewModel landed: a
ViewModel publishes state `private(set)` (§2), so a component that writes straight back into it
could not be used from one. The component owns the clock, the caller owns the state.

- **Top-aligned, inset 8 on the top, leading and trailing.** Placed inside the safe area, so it sits
  below the Dynamic Island where there is one and below the status bar where there is not.
- **Clears itself after 3 seconds**, and showing it again while it is up restarts that 3 seconds
  rather than stacking a second toast.
- **Outlined in every kind**, per the owner — the white one would otherwise be invisible on this
  screen, which is itself white, and outlining all three keeps them one component rather than two
  designs.
- **Text only, no icon**, per the owner's *"for now"*. What that costs is recorded in the
  requirement: colour alone then separates success from error, and those two are the pair red-green
  colour blindness collapses. The message still reads correctly in every case.

**The Swift case is `.success`, while the owner said "succeed".** An identifier, not app content —
§8 and §10 govern what the user reads, and the user never reads this. Noted so it does not look like
a deviation.

**It lands at shared scope with one caller**, as `NoticeSheet` did. §3's *"a component moves up on
its second consumer"* is satisfied rather than waived: the owner asked for it to be reusable, and
named two kinds this screen cannot show.

### 5. `DesignConstants` gains the palette

Colours join `DesignConstants`, per the owner's instruction, in an **extension carried by
`DesignConstants+Login.swift`** — the same enum and the same call sites (`DesignConstants.primaryButton`),
split across two files only because DN-040 took the original past SwiftLint's 200-line limit, which
this repo holds at zero violations. The DN-033 card tints stay in the main file and are **not**
rewritten as hex: a working, reviewed decision, and re-expressing them adds risk for no gain.

```swift
private extension Color {
    init(hex: UInt32) { … }
}
```

**The hex initialiser is `private` to `DesignConstants.swift` deliberately.** Colours are defined in
one place; making the initialiser reachable from a view is an invitation to scatter hex literals
through the presentation layer, which is exactly what §9 forbids. The constraint costs nothing —
nothing outside this file has any business constructing a colour from a number.

Starting values, matched by eye from the supplied design and **expected to change once the owner has
seen the screen**:

| Name | Value | Where |
|---|---|---|
| `loginBackground` | `#FFFFFF` | the screen |
| `primaryButton` | `#E3A32E` | the Login button |
| `fieldBackground` | `#EBEBEF` | both fields, and the Google button |
| `fieldPlaceholder` | `#A9A9AE` | placeholder text and both field icons |
| `mutedText` | `#67768A` | subtitle, *Lupa Password?*, *Belum bikin akun?* |
| `emphasisText` | `#1A1A1A` | heading, *Sign up*, Google button text |
| `toastInformation` / `toastSuccess` / `toastError` | `#FFFFFF` / `#2E7D32` / `#D32F2F` | the three kinds |

### 6. Layout

The owner's numbers go into `DesignConstants`, not into the views (§9). They are **provisional** —
the owner intends to revise them after seeing the screen, and everything below the Login button was
left to the agent explicitly.

| Element | Placement |
|---|---|
| **Login** heading | centred horizontally; its top at **0.2 of the available height** — the owner's *"0.3 from the center vertical"*, read as three tenths above the middle |
| Subtitle | 5 below the heading; 32 either side |
| Email field | 40 below the subtitle; 24 either side; 16 beneath |
| Password field | 24 either side |
| **Lupa Password?** | 24 either side, trailing-aligned as the design draws it; 12 above, 24 below |
| **Login** button | 24 either side |
| Everything below | the agent's, then the owner's |

**The content sits in a `ScrollView`.** With a proportional top offset and a keyboard on screen —
the first keyboard this app has ever shown — a fixed layout can push the password field under it.
Scrolling is what keeps every field reachable on a small phone; nothing about the resting appearance
changes.

### 7. Autofill

`.textContentType(.emailAddress)` and `.textContentType(.password)`, with
`.keyboardType(.emailAddress)` and autocapitalisation off on the email field. Owner's decision,
2026-08-10, taken knowing that iOS will offer to save a credential that authenticates nothing.

### 8. The Google button has no mark

Text only — *"for now just create the UI without image asset."* **This is the one element knowingly
shipped incomplete**, and it should be built so the mark drops in beside the label without the button
being rebuilt.

## Public API contract

None. No DNLibrary symbols are added, changed or consumed beyond what already exists.

**Version bump implied:** none. No library change, no release, no repin.

## Out of scope

- **Authenticating anybody**, signing in with Google for real, creating an account, recovering a
  password. Every one of those is a destination this screen points at and none is built.
- **Any notion of a signed-in user** — no session, no user model, no token, no storage. Still
  deferred per 2026-08-06. `hasPassedLogin` is not the beginning of one.
- **Staying logged in between launches.** Nothing is stored, so every launch starts here — the
  owner confirmed this on 2026-08-10.
- **Logging out.** Nothing leads back to this screen.
- **Converting `PurchaseSection`'s alert to `NoticeSheet`.** Still the obvious cleanup, still out of
  scope, as it was in DN-033.
- **An icon on the toast**, and **dark mode support**. The first is the owner's *"for now"*; the
  second belongs to DN-039's out-of-scope for the same reason.
- **Swift tests.** UI is verified by the owner on the running app.
- **Android.** Does not exist.

## Test plan

**No automated tests, by policy.** What the owner is asked to check on the running app:

| Check | Expected |
|---|---|
| Launch the app | The login screen, not the class choice |
| Both boxes empty, tap Login | Toast: *Email dan password harus diisi.* — red, outlined, at the top |
| Email filled, password empty, tap Login | *Password harus diisi.* |
| Password filled, email empty, tap Login | *Email harus diisi.* |
| Wait after a toast appears | Gone after 3 seconds |
| Tap Login repeatedly while a toast is up | One toast, its 3 seconds restarting — never a stack |
| Both boxes filled with anything at all, tap Login | The Kelas Online / Kelas Offline choice |
| Try to get back | Nothing returns to login — no back button, no swipe |
| From there: open Kelas Online, a class, a recipe, back twice | Still works — DN-033's navigation is untouched |
| Kill and relaunch the app | Login again |
| The password reveal control | Toggles visibility **without losing focus or clearing the field** |
| Tap the password field | iOS offers a saved password if one exists |
| Tap *Lupa Password?*, *Lanjutkan dengan Google*, *Sign up* | The existing "not built yet" sheet, each closing cleanly |
| The Google button | Text only — no mark, and no gap where one was meant to be |
| Keyboard up on a small phone | Both fields and the Login button still reachable |
| Text size cranked up | Nothing clips; the layout still reads |
| Phone in dark mode | Still light — DN-039 |
| Rotate the phone | Nothing rotates — DN-039 |

`swiftlint lint` must report 0 violations, the standing state since DN-016.

**What an agent cannot verify** is every row above: a tap needs a UI test this ticket does not add.
The agent verifies that it compiles and lints clean, and nothing more — DN-034 scopes the gate to a
build with no simulator run.

## Done when

- [x] `DapurNauraApp` swaps its root on `hasPassedLogin`; `CookingClassSelectionView` still owns the
      `NavigationStack` and the single `navigationDestination`, unchanged
- [x] Nothing resembling a session, auth state or user model is introduced
- [x] `LoginView` / `LoginContent` / `LoginTextField` follow §3, and the reveal toggle keeps focus
- [x] `LoginViewModel` is `@MainActor @Observable final class`, does not import SwiftUI, does not
      navigate, and is built through `ViewModelFactory`
- [x] `Toast` is in `Presentation/Components/`, takes a kind, a message and a binding, insets 8 on
      three sides inside the safe area, outlines every kind, and clears after 3 seconds without
      stacking
- [x] The palette is in `DesignConstants`, the hex initialiser is private to that file, and no view
      carries a colour literal
- [x] Wording matches the requirement's table exactly, English words included
- [x] `#Preview`s for the content, the field and all three toast kinds
- [x] `swiftlint lint` clean, and `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034) —
      `DapurNaura Dev`, simulator `4C82AD15-1365-4200-977C-C5DF10E11B1B`, 2026-08-10
- [x] `project.pbxproj` carries no local package reference — nothing here needs one
- [x] **Owner has verified the running app** — approved 2026-08-11, after four rounds of feedback
      recorded under *Revisions during review*
- [x] Committed, not merged — `70ed003`
- [x] PR opened — [DapurNaura-iOS#20](https://github.com/Fostahh/DapurNaura-iOS/pull/20)
- [x] PR merged — [DapurNaura-iOS#20](https://github.com/Fostahh/DapurNaura-iOS/pull/20),
      merge commit `12dacac`, 2026-08-11

## Decisions taken during implementation (2026-08-10)

**Three things the requirement did not settle. Each is flagged rather than absorbed.**

1. **The wording of the "not built yet" notice.** The requirement says *Lupa Password?*,
   *Lanjutkan dengan Google* and *Sign up* show the app's existing notice, but `NoticeSheet` takes
   its title and message from the caller, and DN-033's are specific to Kelas Offline. What is used
   here is DN-033's phrasing generalised — **"Segera Hadir" / "Fitur ini sedang kami siapkan. Mohon
   ditunggu, ya."** — with the placeholder image the app already uses. **The owner has not chosen
   these words.**

2. **A 44pt tap target makes *Lupa Password?* sit lower than the owner's numbers alone would.**
   §9 requires 44pt for anything tappable, and the text is about 20pt tall, so its row is taller
   than the 12-above / 24-below spacing implies. The owner's numbers are applied unchanged around a
   row that is itself taller. **The alternative was a link too small to hit reliably**, and the
   owner has already said the spacing is theirs to revise after seeing the screen.

3. **Whitespace counts as empty.** The owner said the boxes must be *filled*; a space bar pressed
   by accident is not a password, and letting it through would be the one case where the screen's
   only rule quietly does not hold.

**And one reversal, on the owner's instruction the same day.** The screen was first built without a
ViewModel, on DN-033's reasoning. Asked where validation belongs in SwiftUI, the agent answered
*ViewModel*, called its own choice here the weakest part of the ticket, and offered to move it; the
owner said *"ViewModel now"*. `LoginViewModel` was added, `Toast` changed from a `Binding` to a
value plus `onDismiss` so it could be driven by `private(set)` state, and `makeLogin()` joined the
factory. **Recorded rather than quietly rewritten**, because the first decision was defensible and
the reason it was overturned — testability — is the part worth keeping.

## Revisions during review (2026-08-10)

Three from the owner, on the first screenshot of the running app:

1. **The password field was taller than the email field.** The reveal button stated a 44pt height
   for its tap target (§9), which made it the tallest thing in the row and pushed the whole field
   past its neighbour. Fixed at the level the bug was really at: **both fields and both buttons now
   state `loginFieldMinHeight`**, so equal height is guaranteed by construction rather than by two
   rows happening to contain equally tall things. The button states its *width* and fills the row's
   height, which is 56 — comfortably past the 44 §9 asks for.
2. **The toast is 40 tall for one line, and a multiple of 40 when it wraps.** Owner's decision. The
   text does not report its line count, so it is derived: measure the text's natural height and
   divide by one line of `UIFont.preferredFont(forTextStyle: .subheadline)`, which follows the
   user's text size so the division stays right when the text scales. The 8pt insets moved up to
   the container so the text is measured at the width it is actually drawn at — measured 16pt
   wider, a two-line message comes back as one and gets a 40pt banner it does not fit in.
3. **`DesignConstants` was split into `DesignConstants+Login.swift`.** Not asked for. DN-040's
   additions took the file past SwiftLint's 200-line limit, and it had already been paid for twice
   by cutting comments that carry the owner's own decisions. It is an extension of the same enum —
   no call site changed, nothing left the namespace — and the owner's *"use the existing place"*
   still holds in every sense except file count.

**One thing the owner should know about (2).** A fixed 40pt per line is exactly what was asked for,
and at very large accessibility text sizes a line of `.subheadline` grows past 40 and will clip.
Everything at default and moderate text sizes is unaffected.

Three more, from later rounds the same day:

4. **The toast's text was centred despite `multilineTextAlignment(.leading)`.** The two modifiers do
   different jobs: the text alignment rags lines *within* the block, while `.frame(maxWidth:)` places
   the block — and its alignment defaults to `.center`. Now `alignment: .leading`, so single and
   wrapped messages read the same way.
5. **The two field icons were different sizes and their placeholders started at different offsets.**
   SF Symbols share neither dimension — `envelope.fill` is wide and short, `lock.fill` narrow and
   tall — so a first fix that stated only the *column* left the glyphs unequal. Both are now drawn to
   fit one square with `.resizable().scaledToFit()`. The square is `@ScaledMetric`, so the icons keep
   pace with the labels as text scales rather than shrinking against them.
6. **The root swap had no transition** and read as a glitch rather than a move. It is now a push —
   the app arrives from the trailing edge as login leaves by the leading one — held in a `ZStack` so
   the two views coexist for the duration, with `withAnimation(.snappy)` at the mutation. **No
   Reduce Motion check**, deliberately: the owner removed that from DN-038, and reintroducing it here
   would quietly reverse a decision already made.

**A UIKit constraint warning appears when a field is tapped, and it is not ours.** The conflict is
between `_UIRemoteKeyboardPlaceholderView` and `_UIKBCompatInputView` over `accessoryView.bottom` and
`inputView.top` — all private UIKit, and this app contains no `NSLayoutConstraint`,
`UIViewRepresentable` or input accessory of its own. The accessory in question is the AutoFill bar,
which exists because `textContentType` asks for it; the constraints that disagree are Apple's. UIKit
breaks one and carries on. It is strongly associated with the Simulator's *Connect Hardware Keyboard*
being on. **Recorded so nobody hunts it in our code.**

## Notes

**The first screen in this app that takes keyboard input**, and the first built from fixed colours
rather than adaptive system ones. Both are why DN-039 exists and why it runs first.

**It is also the first screen whose main action does nothing real**, and the requirement is explicit
about why that is acceptable here where it was not for the offline buy button: the owner rejected
*"show an alert that the class has been bought"* on 2026-08-09 because it stated that money had
changed hands. A Login button that lets anyone through states nothing false to the user — it asks
for two values and honours them. What it does not do is check them, and nothing on screen claims
otherwise.
