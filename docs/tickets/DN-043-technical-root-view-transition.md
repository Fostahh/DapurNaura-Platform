---
id: DN-043
type: technical
title: The login transition never animates, because the flag it animates lives on an App rather than a View
status: in-review
source: —
branch: ticket/DN-043-root-view-transition
layer: ios
---

## Rationale

**The owner reported that nothing animates when login succeeds.** DN-040 wrote the transition
correctly and it has never run once.

```swift
// DapurNauraApp.swift, as DN-040 left it
@State private var hasPassedLogin = false      // ← @State on an App, not a View

ZStack {
    if hasPassedLogin {
        CookingClassSelectionView(factory: factory).transition(.move(edge: .trailing))
    } else {
        LoginView(...) { withAnimation(.snappy) { hasPassedLogin = true } }
            .transition(.move(edge: .leading))
    }
}
```

**`withAnimation` installs a transaction on the *view* update cycle.** `hasPassedLogin` is `@State`
on `DapurNauraApp`, which is an `App` — a `Scene`, not a `View`. Changing it re-evaluates the scene
body to produce new `WindowGroup` content, and the transaction does not cross that boundary. The
`ZStack`'s `if`/`else` therefore swaps with no animation attached, and `.transition(...)` — which
only runs when an animated transaction accompanies the insertion and removal — degrades to an
instant cut.

**Nothing was wrong with the `ZStack` or the transitions.** DN-040's comment predicts exactly the
symptom the owner reported — *"a bare if/else swaps the root between two frames, which reads as the
app having glitched rather than moved"* — and reaches for a `ZStack` to prevent it. The container was
never the problem; the transaction was, and it never arrived.

**The codebase corroborates it.** Every transition that works lives inside a `View`; the only one
that does not is the only one on an `App`:

| Site | Declared in | Animates |
|---|---|---|
| `NoticeSheet.swift:94` | a `View` | yes |
| `Toast.swift:108` | a `View` | yes |
| `OfflineClassMonthSection.swift:34` | a `View` | yes |
| `DapurNauraApp.swift:60` | an **`App`** | **no** |

Checked before writing this: nothing in the project calls `.animation(nil)`, sets a `Transaction`
with `disablesAnimations`, or otherwise suppresses animation. The four `.animation(_:value:)` sites
all belong to other components.

### Why this is not a one-line fix

Moving the flag into a `RootView` fixes the defect in about forty lines. The owner asked for more,
and gave the reason on 2026-09-11 — translated from the exchange, recorded here because there is no
requirement document:

> "Login flow should have its own stack too. Because later on, Login can go into Forgot Password
> flow, or even Register flow. After that, flow completed, it does popToRoot which goes back to
> LoginView."

> "Authentication flow will have a lot of screens in the future, for example Onboarding screens,
> Login (done), Forgot Password, Registration and can be much more. That's why I wanted to
> anticipate it, encapsulate it into 1 module, which can be called as AuthFlow."

**The agent argued for deferring the module** on the grounds that §4 forbids structure with no
caller. **The owner's reasoning carried it**: onboarding plus login plus forgotten passwords plus
registration is a known multi-screen flow, not a hypothetical, and a container built now costs a
folder while one retrofitted later costs a rearrangement. Recorded because the argument should not
need running twice.

The owner also raised having hit, in production elsewhere, a business requirement needing a
navigation controller pushed on top of another. **That instinct is right and its mechanism does not
port** — see *Technical approach*.

## Context

Read before starting:

- `ios/DapurNaura/DapurNaura/App/DapurNauraApp.swift` — the composition root, and where the defect is
- `ios/DapurNaura/DapurNaura/App/Navigation/DapurNauraAppRouter.swift` — `path` and nothing else
- `ios/DapurNaura/DapurNaura/Presentation/Cookings/CookingClassSelection/CookingClassSelectionView.swift` —
  held the main flow's `NavigationStack` when this ticket started. **The original plan was to leave
  it alone**; the owner's restructure mid-ticket made that wrong, and the stack moved out. See
  *The restructure*.
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §3 folder layout, §4 navigation, §5 composition root

Two rules in §4 constrain the shape and were checked rather than assumed:

- *"a convenience method nothing calls is worse than none"* — which is why no `popToRoot()` is added
  here, and why `AuthRoute` does not yet exist.
- *"The discarded allocation is accepted… do not 'fix' it by making the ViewModel optional"* — the
  agent had offered to stop `factory.makeLogin()` running on every body pass. **The document already
  rules against that**, so it was dropped from scope rather than done.

## Technical approach

**Four files added, four edited, and `Presentation/` reorganised into flow modules. No
`project.pbxproj` change at all** — `DapurNaura/` is a synchronized folder, so every move and every
addition joins the target on its own.

**1. `RootView` — the fix.** A real `View` owning the swap, so `withAnimation` lands in view-land
where transactions propagate. It switches on `router.root` inside a `ZStack`, each branch carrying
the transition DN-040 wrote.

**2. `RootRoute` — `.auth` / `.main`.** Replaces `hasPassedLogin`, and inherits its caution verbatim:
it names which screens are on show and nothing about who is using them. The naming argument DN-040
made against `isLoggedIn` applies unchanged.

**3. `root` moves onto the router, `path` stays, the auth path does neither.** The rule this ticket
writes into §4:

> A flow's path lives on the router only if it must **survive** something, or be **reached from
> outside** the view that draws it.

`root` qualifies on reachability — a logout control, or a 401 handler once a backend exists, must be
able to force `.auth` from outside `RootView`. `path` qualifies on both. **The auth flow's path
qualifies on neither, so it is `@State` in `AuthFlowView`** — which is what makes *"login cannot be
returned to"* structural: the swap destroys the view and the stack goes with it, leaving no stale
array for anyone to remember to clear.

**4. Two flow modules, `Auth/` and `Cookings/`.** `AuthFlowView` owns the auth `NavigationStack` with
`LoginView` as its root; `CookingsFlowView` owns the main one, opening onto the Kelas Online / Kelas
Offline choice. Every screen lives under one flow, shared components stay in `Components/`, and
`DesignConstants` moves to `Constants/`. Adding onboarding later is a folder, a route case and a
`switch` arm.

**The second module was not in the original plan** — the owner restructured mid-ticket, which turned
out to expose something. See *The restructure*.

**5. `LoginView.submit()` — the keyboard leaves before the screen moves.** Added on the owner's
instruction of 2026-09-11, *"fix it now rather than it becomes bigger problem later"*, against a risk
flagged before the first build rather than an observed defect.

Login is the app's only screen with a keyboard, so it is the only place two system animations want
the same moment: the keyboard retracting and `RootView` sliding the flow away. Run together, the
field stack reflows *while* it is travelling — the screen appears to wobble on its way out rather
than to leave. `submit()` resigns first responder, waits 250ms, then calls through.

**Not `@FocusState`.** `LoginTextField` owns its focus internally and must, to carry the cursor
across the `SecureField`/`TextField` swap the reveal button performs — logic DN-040 took care to get
right. Hoisting focus out of it to gain a flag to clear would disturb that for no gain over asking
app-wide. **The 250ms is the one real cost**, and deleting the `Task.sleep` restores the immediate
swap if it reads as lag; the dismissal itself is worth keeping either way.

### The one arrangement that is simply wrong

The owner's UIKit instinct — obtain a fresh stack when the flow demands one — is correct, and
**SwiftUI reaches it through a different door:**

| Intent | UIKit | Here |
|---|---|---|
| Fresh stack, no way back | swap `window.rootViewController` | swap `router.root` |
| Fresh stack, user returns | present a second `UINavigationController` | `.sheet` / `.fullScreenCover` around a new stack |
| Stack pushed inside a stack | possible, discouraged | **broken — never** |

Nesting a `NavigationStack` inside another produces duplicated or missing navigation bars, toolbars
attaching to the wrong stack, and a back gesture fighting itself. Written into §4 as a **must**,
because it is the failure this module's shape exists to make unreachable.

### What is deliberately not built

**No `AuthRoute`, and no `navigationDestination` in `AuthFlowView`.** Nothing pushes yet — *Lupa
Password?* and *Sign up* still raise the "Segera Hadir" notice DN-040 gave them, and changing that is
a product decision nobody has made. An enum whose cases nothing constructs, resolved by destinations
that would have to be invented, is precisely the structure §4 forbids. The container is what was
asked for; the vocabulary lands with the first screen that needs it, in three lines.

## Public API contract

None. No DNLibrary symbols touched, no Swift API consumed by anything outside this app.

**Version bump implied:** none. No library change, no publish, no repin.

## Out of scope

- **Forgot Password, Registration, Onboarding.** No requirement exists for any of them. This ticket
  builds the flow they will live in, not the screens.
- **The payment flow.** Discussed at length while settling the shape and agreed to be a
  `fullScreenCover` owning its own stack, with an outcome closure rather than a delegate, and an
  outcome mirroring `PurchaseStatus` rather than a `Bool`. **None of it is built here** and no ticket
  exists yet.
- **`popToRoot()` on the router.** No caller until a pushed auth screen completes.
- **The `factory.makeLogin()` allocation per body pass.** §4 rules it accepted; see *Context*.
- **Login's behaviour.** Validation, toast, notice sheet and copy are untouched. If this ticket
  changes what login *does*, the approach was wrong.
- **Every other screen's behaviour.** The restructure moved files and relocated one `NavigationStack`.
  No screen draws anything different, and none was meant to — which is exactly why the navigation
  regression pass above exists rather than being assumed.

## Test plan

UI, so there is nothing to unit test (platform Definition of Done — tests are required for the data
layer only). What was run:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=4C82AD15-1365-4200-977C-C5DF10E11B1B' build
swiftlint lint
```

What the owner is asked to check on the running app — **the defect is visual and only this can
confirm it:**

| Check | Expected |
|---|---|
| Fill both boxes, tap Login | The app **slides in** from the trailing edge as login leaves by the leading edge |
| Watch login as it leaves | It should move, not vanish. A cut means the fix did not take |
| Leave a box empty, tap Login | Toast naming the empty box. Unchanged from DN-040 |
| Tap *Lupa Password?* / *Sign up* | "Segera Hadir" notice. Unchanged from DN-040 |
| Relaunch | Starts at login again |

**The main flow's stack moved out of `CookingClassSelectionView` into `CookingsFlowView`, so every
push and pop wants re-checking** — a `navigationDestination` that fails to register does not error,
it simply does nothing when tapped:

| Check | Expected |
|---|---|
| Kelas Online → class list → a class → a recipe | Each pushes. **A tap that does nothing means the destination did not register** |
| Back from each, all the way to the choice | Returns one level at a time, state intact |
| Kelas Offline → the schedule, then back | Pushes and returns |
| A category chip on the list | Reloads the list; the chip row stays tappable |
| The title on the choice screen | Still "Dapur Naura" — it moved with the screen, not the stack |
| A locked recipe | Still inert |

**Two risks were flagged before the first build. One is fixed; one cannot be fixed blind.**

- ~~**The keyboard.**~~ **Fixed** — `LoginView.submit()` dismisses it and waits. What to check is
  that the 250ms pause between tapping Login and the screen moving reads as deliberate rather than
  as lag.
- **The navigation bar, still open.** `CookingsFlowView` contains a `NavigationStack`, and
  sliding a whole stack in can flicker its title for a frame or two. **Deliberately not
  pre-emptively "fixed":** the mitigations all trade something real — keeping both flows mounted
  would defeat the destroy-on-swap guarantee this ticket exists to establish — and choosing one
  against an unobserved symptom risks paying that price for nothing. **If the owner sees it, it gets
  a ticket with a description of what it actually does.**

## Done when

- [x] `RootView` owns the swap, and it is a `View`
- [x] `RootRoute` added; `hasPassedLogin` gone from `DapurNauraApp`
- [x] `router.root` added; the main flow's `path` unchanged
- [x] `AuthFlowView` owns the auth `NavigationStack`, with its path as `@State`
- [x] Every screen lives under a flow module — `Auth/` or `Cookings/`; `DesignConstants` in `Constants/`
- [x] `CookingsFlowView` owns the main stack; `CookingClassSelectionView` reduced to content + title
- [x] No `AuthRoute`, no `popToRoot()`, no placeholder screens
- [x] `LoginView.submit()` dismisses the keyboard and waits before the swap
- [x] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034) — `DapurNaura Dev`, simulator
      `4C82AD15-1365-4200-977C-C5DF10E11B1B` (iPhone 16 Pro), 2026-09-11 — re-run after the keyboard fix and after the DN-041 fast-forward
- [x] `swiftlint lint` reports 0 violations, 2026-09-11
- [x] `project.pbxproj` carries no local package reference — and is not modified at all
- [x] Documentation sweep (DN-042) — enumerated with `git ls-files '*.md'` in both repositories,
      five documents corrected, 2026-09-11 — re-applied after DN-041 merged, then again after the restructure
- [ ] Owner has verified the transition on the running app
- [ ] Committed, not merged
- [ ] PR opened
- [ ] PR merged

## The restructure, and the migrating stack it exposed

**The owner reorganised `Presentation/` mid-ticket**, on 2026-09-11, after the first build was
already green: the five class screens grouped under `Cookings/` (first named `Classes/`, renamed the
same day), and `DesignConstants` moved to `Constants/`. Pure file movement — no Swift content
changed, and the build stayed green.

**It contradicted a rule this ticket had just written**, which is how the real problem surfaced. §3
now said a folder earns the flow-module tier *only by owning a `NavigationStack`* — and `Cookings/`
owned none. The main flow's stack was still inside `CookingClassSelectionView`. The owner's call,
stated plainly:

> "It should have their own NavigationStack since it's the main module of the app, it's like Home in
> another application."

**Following that turned up something worth more than the symmetry.** The main stack had been
*migrating*: it lived on `CookingClassListView` until DN-033 made the Kelas Online / Kelas Offline
choice the root, at which point it moved to `CookingClassSelectionView` — **two hosts in two
tickets**, each time landing on whichever screen happened to be first, dragging the
`navigationDestination` along. It would have moved a third time the day anything opens ahead of the
choice.

`CookingsFlowView` ends that. The flow owns the stack; what it opens onto is an ordinary screen that
can be replaced without navigation moving with it. `CookingClassSelectionView` loses its
`NavigationStack`, its `navigationDestination`, its router dependency and its `ViewModelFactory` —
down to content and a title.

**The lesson is about where the rule came from.** The migrating stack had been visible in two tickets'
comments and nobody had read it as a pattern. Writing down *why* a flow owns its stack is what made
the third migration predictable instead of routine.

## The DN-041 overlap, and how it was handled

~~**Merge DapurNaura-iOS#21 first.**~~ **Cleared 2026-09-11** — the owner merged it (`cc88dec`) and
this branch was fast-forwarded onto it before any commit existed here.

Recorded because the handling generalises. This branch was cut from `development` per the standing
practice of not stacking, and DN-041 was still open on the same three documents. Rather than resolve
a stash-pop conflict, the doc edits made here were **discarded and re-applied on top of DN-041's
merged text** — the Swift work touched no file DN-041 touched, so the fast-forward was clean and the
result is a correct merge rather than a reconciled one.

One consequence worth noting: **before the merge, `ios/DapurNaura/CLAUDE.md` had no `hasPassedLogin`
paragraph to correct** — DN-041 is what added it. Re-applying after the merge is what caught it.
Sweeping the documents before the lower ticket landed would have missed a sentence this ticket
falsifies.

## Notes

**The defect had been shipped, merged and reviewed without anyone seeing it**, which is the part
worth carrying forward. DN-040's PR was approved, the transition was in the diff and read correctly,
and `swiftlint` was clean — because the code *is* correct. What it was missing was a property of
where it lived, and nothing in the pipeline inspects that. The build gate (DN-034) compiles it; the
linter checks its shape; only the owner running the app could have caught it, and the animation's
absence is easy to read as a design choice rather than a failure.

**It took four exchanges to land the shape, and three of them were the agent pushing back on scope.**
The first two were useful — they established that login cannot be a poppable stack entry, and that
the auth path should not sit on the router. The third was not: the agent argued to defer the module
on a rule about callerless structure, and the owner's answer, that onboarding is coming, had simply
not been in evidence yet. **The lesson is not "concede earlier" but "ask what is coming before
arguing that nothing is."**
