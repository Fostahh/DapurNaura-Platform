---
id: DN-024
type: product
title: Data layer — class category, and filtering GET /classes by it
status: done
source: docs/requirements/2026-08-08-cooking-class-category-filter.md
branch: ticket/DN-024-cooking-class-category
commit: 308694b
pr: https://github.com/Fostahh/DNLibrary/pull/14
layer: data
---

## Requirement (traced)

From [`../requirements/2026-08-08-cooking-class-category-filter.md`](../requirements/2026-08-08-cooking-class-category-filter.md),
approved 2026-08-08:

> "Please build a feature to filter the cooking-class list by category. This category is new data,
> and it needs a change to its contract."

> "I want a correction — the categories are MINUMAN, BAKING, COOKING. Makanan Kekinian is BAKING,
> Pastry goes to COOKING, Jajanan Pasar goes to MINUMAN."

Two owner decisions from the same day govern the shape of this ticket:

- **A class belongs to exactly one category** — not none, not several.
- **The server does the filtering**, per category. The app does not fetch everything and narrow it
  locally. This is why the ticket touches the endpoint at all rather than just adding a field.

The chips themselves are [DN-025](DN-025-product-cooking-class-category-filter-ui.md). This ticket is
everything underneath them.

## Context

Read before starting:

- **`docs/contracts/classes.json`** and the **Revision 2026-08-08** section of
  [`../contracts/README.md`](../contracts/README.md) — revised by this ticket, and the authority for
  the DTO. The revision records the owner's sample-category assignment and the tolerance rule below.
- `DNLibrary/sharedLogic/src/commonMain/kotlin/id/dn/fostah/dnlibrary/domain/model/CookingClass.kt`
- `.../domain/usecase/GetCookingClassesUseCase.kt` — the public signature this ticket widens
- `.../domain/format/DNFormat.kt` — where the chip wording goes, per iOS ARCHITECTURE §10
- `.../datasource/remote/RemoteDataSource.kt` — `GET {baseUrl}/classes`
- `.../datasource/remote/StubRemoteDataSource.kt` — the fixture replay, which now has to filter
- `.../datasource/remote/network/responses/ClassesResponse.kt`
- `.../datasource/repository/CookingClassRepository.kt`
- `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` §2 (public API), §5 (nullability), §6 (testing)

**No overlap with any other ticket.** Every branch is merged as of DN-021; `DNLibrary/development`
is level with its remote, so this branches straight from `development` with nothing stacked under
it.

## Technical approach

**1. `CookingClassCategory` — a public enum, three entries.**

```kotlin
public enum class CookingClassCategory { MINUMAN, BAKING, COOKING }
```

Entry names are the owner's category identifiers and the wire values both. `MINUMAN` stays
Indonesian: it is content, and CODEBASE-ARCHITECTURE §7 keeps a domain term untranslated where
translating loses meaning.

**2. `CookingClass.category` is nullable, and null means one specific thing.**

```kotlin
/** Null when the server sent a category this version of the library does not know. */
val category: CookingClassCategory?
```

**The wire field is a `String`, not a serialized enum**, mapped to the domain by hand:

```kotlin
"MINUMAN" -> MINUMAN; "BAKING" -> BAKING; "COOKING" -> COOKING; else -> null
```

This deliberately departs from `PurchaseStatusResponse`, the enum-with-`@SerialName` pattern beside
it. The reason is that the two sets differ in kind: `purchaseStatus` has three values fixed by how
payment works, while **categories are a list the owner may extend**. A strict enum turns one new
server value into `SerializationException` → `DNError.Contract` → an *empty class list* on every
already-installed app. A `String` plus an explicit mapper costs five lines and fails softly on
exactly one class instead.

Two alternatives were considered and rejected: `coerceInputValues = true` on the shared `Json`
would relax decoding for every DTO in the library to fix one field, and an `UNKNOWN` enum entry
would force every future Swift `switch` to handle a case with no meaning to a user.

**Strictness is kept where the contract is firm.** `category` is non-null in the DTO, so a class
that omits it entirely still fails as a contract violation, exactly like a class with no `name`.
Tolerance is for unknown *values*, never for an absent field.

**3. The category travels down the stack as a parameter, not as state.**

```
GetCookingClassesUseCase.invoke(category: CookingClassCategory? = null)
  → ICookingClassRepository.getCookingClasses(category)
    → IRemoteDataSource.getCookingClasses(category)
      → GET {baseUrl}/classes?category=BAKING     // parameter omitted entirely when null
```

Null is not sent as an empty value — the parameter is absent, which is what the contract defines as
"every class". Ktor's `parameter()` is used rather than string concatenation so encoding is not
hand-rolled.

The default `= null` keeps the Kotlin call site `getCookingClasses()` compiling. iOS passes the
argument explicitly either way, so the app does not depend on SKIE generating the no-argument
overload.

**4. The stub filters.** `StubRemoteDataSource` replays the fixture; with server-side filtering it
must now *do* what the server will do, or the chips cannot be exercised before a backend exists.
It decodes the fixture and drops the classes whose `category` does not match the argument. Flagged
as a deviation: the stub stops being a pure replay and starts simulating behaviour. It is the
minimum needed for the owner to verify the screen, and the fixture stays verbatim.

**5. The chip wording lives here, not in Swift.** iOS ARCHITECTURE §10 puts display wording derived
from data in the library, so Android cannot word it differently:

```kotlin
DNFormat.categoryFilterLabel(category: CookingClassCategory?): String   // null → "Semua"
```

Null maps to `"Semua"` because the filter's value genuinely is `CookingClassCategory?` — the chip
for "no category" is one of the four labels a chip row needs, and Android will need the same four.

**The accepted cost, stated plainly:** the wording of `Cooking` is still an open question in the
requirement, and it now sits behind a library release. §10 accepts that trade explicitly, and
forbids the alternative — a Swift-side label added to dodge the release cycle.

## Public API contract

| Symbol | Change |
|---|---|
| `CookingClassCategory` | **new** public enum: `MINUMAN`, `BAKING`, `COOKING` |
| `CookingClass.category` | **new** property, `CookingClassCategory?` |
| `GetCookingClassesUseCase.invoke` | **signature widened** — gains `category: CookingClassCategory? = null` |
| `DNFormat.categoryFilterLabel` | **new** function, `(CookingClassCategory?) -> String` |

Nothing is removed and nothing is renamed. `CookingClass` is a `data class`, so the added property
moves its generated `copy`/`equals` — a source-compatible change for the app, which never constructs
one outside previews.

**Version bump implied: MINOR → `0.6.0`.** Public API grows and one public signature changes; no
behaviour fix, and `1.0.0` stays reserved for the App Store release.

## Out of scope

- **The chips, the screen, and anything visible.** [DN-025](DN-025-product-cooking-class-category-filter-ui.md).
- **`category` on the class-detail payload.** No screen shows it; the contract revision says so.
- **A categories endpoint.** The three are fixed in the requirement; the app does not discover them.
- **Filtering by anything else** — price, purchase status, name search.
- **Paging.** CODEBASE-ARCHITECTURE §10 sets the trigger at unbounded growth; a filtered list is
  smaller than the unfiltered one that already needs none.

## Open questions

Both are inherited from the requirement and neither blocks this ticket:

- **Does the third chip read `Cooking`?** Implemented as `Cooking`, marked `[ASSUMPTION]` in the
  requirement. One string in `DNFormat`, and a library release to change — see the cost above.
- **Will a fourth category be added?** The tolerance above is built regardless, which is what makes
  the answer non-blocking rather than merely unknown.

## Test plan

`./gradlew :sharedLogic:check` is the gate. Fixtures are JSON decoded through kotlinx per §6 — no
hand-built model objects.

| Test | Proves |
|---|---|
| The revised contract payload decodes | all three categories map, in the order the fixture sends them |
| `?category=BAKING` is on the request URL | the server, not the client, is being asked to filter |
| No `category` parameter when null | "every class" is an absent parameter, not `category=` |
| An unrecognised value decodes to `null` on that class, and the list still arrives | the tolerance rule — the payload does not fail |
| A class with no `category` field maps to `DNError.Contract` | tolerance did not become blanket nullability |
| `{"classes":[]}` maps to `Success(emptyList())` | an empty category is a normal answer the UI can render |
| The stub returns 3 for null, and 1 per category | every chip has content to show before a backend exists |
| `DNFormat.categoryLabel` for all four inputs | the wording is tested where it lives |

## Done when

- [x] `CookingClassCategory`, `CookingClass.category`, the widened use case and `DNFormat.categoryFilterLabel` exist
- [x] `GET /classes` carries `?category=` when asked and omits it when not
- [x] The stub filters, so each chip has content without a backend
- [x] Contract revised and the revision noted in `docs/contracts/README.md`
- [x] Tests above pass; `./gradlew :sharedLogic:check` green
- [ ] `GET /classes` carries `?category=` when asked and omits it when not
- [ ] The stub filters, so each chip has content without a backend
- [ ] Contract revised and the revision noted in `docs/contracts/README.md`
- [ ] Tests above pass; `./gradlew :sharedLogic:check` green
- [x] Committed, not merged — `308694b`
- [x] PR opened — [DNLibrary#14](https://github.com/Fostahh/DNLibrary/pull/14)
- [ ] PR merged, ticket marked `done` by the human
- [ ] Library published as `0.6.0` and the app bumped off the local package

## Implementation notes (2026-08-08)

**`categoryFilterLabel`, not `categoryLabel`.** Renamed while writing it. The function labels a
*selection*, and null means "no filter" → `"Semua"`. A class whose `category` is null means something
different — a value this app version does not recognise — and the shorter name invited exactly that
misuse from a future badge. The KDoc says so at the call site.

**SKIE generates no no-argument overload for the defaulted parameter.** The Swift face is
`invoke(category:)` only; `invoke()` does not exist there. Harmless, because the app passes the
argument explicitly, but the `= null` default is a Kotlin/Android convenience and nothing more —
do not rely on it from Swift.

**`CookingClassCategory` bridges to a Swift `@frozen enum` with `Hashable` and `CaseIterable`**
(`.minuman`, `.baking`, `.cooking`), so DN-025's stale-response guard can compare two optionals with
`==`. Checked in the generated `.swiftinterface`, not assumed.

**A test name with a comma does not compile on Kotlin/Native** —
`e: Name contains illegal characters: ","` from `compileTestKotlinIosSimulatorArm64`. Backticked
names are fine, commas in them are not; renamed. The Android host target accepted it, so this fails
on exactly one of the two platforms — which is why the gate is `check` and not `testAndroidHostTest`.

**`aMissingRequiredFieldMapsToAContractFailure` gained a `category`** in its fixture. Without it the
test would have failed for two reasons at once and stopped proving anything about `name`.

**Test counts, read from the result XML rather than the console:** 59 on the Android host, 58 on the
iOS simulator with 4 keychain cases `@Ignore`d — **117 total, up from 103**, which is exactly the 7
new tests × 2 platforms. Every new test was confirmed present in both platforms' XML by name.

## Notes

The fixture is copied verbatim in two places outside the umbrella repo —
`StubRemoteDataSource.CLASSES_JSON` and `GetCookingClassesUseCaseTest.CONTRACT_CLASSES_JSON`, both
carrying a comment saying they follow the contract. A contract revision means revising all three or
the comment becomes a lie; DN-020 found exactly this drift once already.
