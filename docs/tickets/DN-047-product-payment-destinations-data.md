---
id: DN-047
type: product
title: Data layer — the bank accounts a class is paid into
status: in-review
source: ../requirements/2026-09-11-payment-flow.md
branch: ticket/DN-047-payment-destinations-data
layer: data
---

## Requirement (traced)

From [`2026-09-11-payment-flow.md`](../requirements/2026-09-11-payment-flow.md), approved
2026-09-11:

> "When a user wants to pay, the user is taken to a page containing two cards arranged vertically.
> The first card, match the colour to Bank Mandiri, then there is a name and account number. The
> second card, match the colour to BSI, then there is a name and account number."

And:

> "Make the name and account number dummy, but following Bank Mandiri and BSI standards."

The requirement establishes **two accounts, each carrying a bank, an account number and the name it
is held in**, and that both are placeholders until the owner supplies real ones. Digit counts were
established by the agent at the owner's request and are recorded there: **Mandiri 13, BSI 10.**

## Rationale for it living here

**The owner chose the library over the app**, 2026-09-11, translated:

> "Put it in DNLibrary. I am still undecided whether to start the Android app or the back-end first
> — to be safe, better to put it in DNLibrary."

**The agent had recommended hard-coding it in Swift** on the grounds that two unchanging dummy values
do not yet need a journey through the library, and that §4 warns against structure with no caller.
**The owner's reasoning is better and it is recorded because of that**: if Android may come before
the backend, Swift-side constants are something that has to be written a second time in Kotlin, and
the second copy is the one that drifts. The library is where both platforms can read the same answer.

This is also what the architecture already says: bank accounts are **data**, not view context, and
§1 puts all data behind `DNDataLayer`.

## Context

Read before starting:

- `DNLibrary/sharedLogic/src/commonMain/kotlin/id/dn/fostah/dnlibrary/domain/model/CookingClass.kt` —
  how a domain enum is declared, and `PurchaseStatus` as the shape to follow
- `.../domain/usecase/GetCookingClassesUseCase.kt` — the shape every use case takes
- `.../datasource/remote/StubRemoteDataSource.kt` — how fixtures are replayed through the real
  decoding path
- `docs/contracts/README.md` — the wire shape is the source of truth for DTOs and for the backend
- `docs/tickets/DN-026-technical-status-labels-in-swift.md` — **why the bank's colour does not
  belong here**

**The accounts are not per class.** They are the business's, and every class is paid into the same
two. Nothing about this is parameterised by a class id.

## Technical approach

### The model

```kotlin
public data class PaymentDestination(
    val bank: Bank,
    val accountNumber: String,
    val accountHolderName: String,
)

public enum class Bank { MANDIRI, BSI }
```

**`accountNumber` is a `String`, not a number.** It is an identifier that happens to be digits —
leading zeros are significant, it is never arithmetic, and BSI's 10 digits would fit an `Int` while
Mandiri's 13 would not. Modelling it as a number would silently destroy accounts beginning with zero.

**The bank is an enum, not a display string**, and this is the load-bearing decision in the ticket.
The app has to draw each bank in its own colour and eventually its own logo, and **both of those live
on the app side** — the colour because DN-026 settled that a colour is view context, the logo because
it is an image asset. So the app can only render banks it already knows about. An enum makes that
limit explicit and gives Swift an exhaustive switch; a free-form code would make the same limit
implicit and fail at runtime the first time the server sent something unrecognised.

**The consequence, stated rather than discovered: adding a third bank needs an app release.** That is
true whichever way this is modelled, because the logo asset has to ship with the app regardless.

**What is deliberately not on the model:** the bank's colour, its logo, its display name, and any
formatting of the account number. All four are the app's, per §10 and DN-026's precedent.

### The use case

```kotlin
public sealed interface PaymentDestinationsResult {
    public data class Success(val destinations: List<PaymentDestination>) : PaymentDestinationsResult
    public data class Failure(val error: DNError) : PaymentDestinationsResult
}

public class GetPaymentDestinationsUseCase internal constructor(
    private val repository: IPaymentRepository
) {
    public suspend operator fun invoke(): PaymentDestinationsResult
}
```

**Corrected while reading the code, 2026-09-11.** This ticket first wrote the return type as
`DNResult<List<PaymentDestination>>`. **There is no such type and there must not be** —
CODEBASE-STANDARD §2 keeps generics out of the public API because they are the roughest corner of
Swift interop, so every use case declares its own concrete sealed result. `OfflineClassScheduleResult`
is the shape to copy. Nothing throws across the boundary either way.

Entered through `DNDataLayer` like the rest, and the repository is `internal` so the constructor
cannot be called from outside.

**Order is the server's and is preserved.** The requirement draws Mandiri first and BSI second; the
list arrives in that order and the app does not sort it.

### The contract

A new fixture, `docs/contracts/payment-destinations.json`, replayed by `StubRemoteDataSource` through
the real decoding path — so the DTO and the parsing are exercised even though no server exists.

**The values in it are the dummy ones from the requirement.** Replacing them with real accounts is a
content change to the fixture and, later, a server concern; it is not a code change.

## Public API contract

**Added:** `PaymentDestination`, `Bank`, `GetPaymentDestinationsUseCase`, and its accessor on
`DNDataLayer`.

**Changed:** nothing. **Removed:** nothing.

**Version bump implied: MINOR.** New public API, purely additive — so the app's
`upToNextMajorVersion` range picks it up on *Update to Latest Package Versions* with no
`project.pbxproj` edit (DN-030).

## Out of scope

- **Sending anything to a server.** This ticket reads two accounts; DN-048 collects a photograph and
  sends nothing. The upload API does not exist and is not designed here.
- **The bank's colour, logo or display name.** App-side, per DN-026.
- **Real account numbers.** Dummy by the owner's instruction; the requirement records that the real
  ones are undecided.
- **Any per-class or per-user variation.** Same two accounts for everybody.
- **Changing `PurchaseStatus` or anything about how a purchase is recorded.** Nothing here writes.

## Test plan

`./gradlew :sharedLogic:check` is the gate — both platforms, as always.

- **The use case returns both destinations, in fixture order**, through the stub.
- **The decoding is exercised**, not bypassed: a fixture missing a field, or carrying an unknown
  bank, fails as a `Contract` error rather than producing a half-built model. Strict JSON is already
  configured (DN-002) and this test is what proves it applies here.
- **Account numbers survive as written**, including a leading zero — the test that would have caught
  modelling them as a number.
- **Failure paths**: the engine seam (DN-006) drives a network failure and a non-2xx response through
  `MockEngine`, and each maps to the right `DNError`.

## Done when

- [x] `PaymentDestination`, `Bank` and the use case exist, `explicitApi()` clean
- [x] Reachable through `DNDataLayer` — `getPaymentDestinations`
- [x] `docs/contracts/payment-destinations.json` added, and described in `docs/contracts/README.md`
- [x] The stub replays it through the real decoding path
- [x] Tests written **and run** — `:sharedLogic:check` green, **85 tests on each platform, 0 failures** (up from 77), 2026-09-11
- [x] The account number is a `String`, and `aLeadingZeroInAnAccountNumberSurvives` proves it
- [x] No colour, logo or display name anywhere in the library
- [x] Documentation sweep (DN-042) — enumerated in both repositories. **Four documents corrected, three of them stale before this ticket**: see *What the sweep found*
- [ ] Diff reviewed by the owner
- [ ] Committed
- [ ] PR opened
- [ ] PR merged
- [ ] Published, and the app repinned — **DN-048 cannot start until this is released**

## What the sweep found

**Three of the four documents corrected were already wrong before DN-047 touched them**, and that is
the part worth recording:

| Document | What was stale | Since |
|---|---|---|
| `DNLibrary/CLAUDE.md` | the `domain/model/` and `domain/usecase/` lists omitted everything DN-035 added | 2026-08-10 |
| `DNLibrary/README.md` | *What it provides* listed neither the offline schedule nor recipes | 2026-08-10 |
| `DNLibrary/README.md` | described `@Ignore`d Keychain tests in `src/iosTest/` — **that folder has not existed since DN-031** | 2026-08-08 |
| `docs/contracts/README.md` | the endpoint table never listed `offline-classes.json` | 2026-08-10 |

**Corrected in full rather than only where DN-047 touched them**, for DN-041's reason: a reader
meeting a half-stale list cannot tell which half, and the natural inference is the wrong one.

**An incomplete inventory reads exactly like a complete one**, which is why a month passed without
anyone seeing it. The lists now say the folder is the source of truth, in the same move DN-041 made
when it removed screen counts.

## Notes

**DN-048 depends on this being published, not merely merged.** The app builds against the local
package while the two are in flight, and the committed app state does not compile until the release
and the repin. That is the local package rule working as designed.

**This is the first data-layer work since DN-035**, and the first whose data has no server behind it
even in principle yet — the contract fixture is being written ahead of the backend rather than
transcribed from one. That is the same position `classes.json` was in, and it is why the contract
folder exists.
