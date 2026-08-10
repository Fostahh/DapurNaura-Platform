---
id: DN-035
type: product
title: Data layer — the offline class schedule, its date window and its availability rule
status: in-review
source: docs/requirements/2026-08-09-offline-class-schedule.md
branch: ticket/DN-035-offline-class-schedule
pr: https://github.com/Fostahh/DNLibrary/pull/19
layer: data
---

## Requirement (traced)

From [`../requirements/2026-08-09-offline-class-schedule.md`](../requirements/2026-08-09-offline-class-schedule.md),
approved 2026-08-09.

> "Everything still to come, out to the end of next month. […] Nothing in the past. […] The window
> ends one month out."

> "The state follows from how many places are left, and is not set by hand."

| Places remaining | State |
|---|---|
| more than ten | `MASIH BISA DAFTAR` |
| ten or fewer, but not none | `HAMPIR PENUH` |
| none | `SUDAH PENUH` |

> "A month is a section; a class is a row inside it."

> "The number of places left is never shown to the reader. […] The count decides the state and stays
> behind it."

The UI is [DN-036](DN-036-product-offline-class-schedule-ui.md).

## Context

Read before starting:

- `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` — §1 (no DI framework), §2 (domain models are not view
  models), and the `explicitApi()` gate
- `DNLibrary/sharedLogic/src/commonMain/kotlin/id/dn/fostah/dnlibrary/DNDataLayer.kt` — the single
  entry point every use case is reached through
- `datasource/remote/StubRemoteDataSource.kt` — how fixtures are replayed through the real decoding
  path, and `RemoteDataSource` above it
- `domain/format/DNFormat.kt` — where display wording lives, and why (§10 of the iOS document)
- `docs/contracts/README.md` and the existing contract files

Already true, and constraining:

- **There is no date type anywhere in this library**, and no date dependency. Every model to date
  carries strings and numbers only.
- **`DNFormat` is an `object` with no state.** A formatter that needs a locale or a clock does not
  fit that shape without changing it.
- **The stub is the server.** With no backend, whatever filtering the requirement describes has to
  happen against fixtures, exactly as DN-024 had to teach the stub to filter by category.

## Technical approach

**1. `kotlinx-datetime`, added as a dependency.**

The window rule (*"nothing in the past, out to the end of next month"*) and the weekday in
*"Rabu, 2 Sept 2026"* both need real calendar arithmetic — month boundaries, leap years, day-of-week.
Hand-rolling that in a library that ships to two platforms is the wrong trade, and `kotlinx-datetime`
is the Kotlin-official answer with SKIE-friendly value types.

`LocalDate` is the model's date type. **Not an instant and not a timestamp**: a class happens on a
day, not at a moment, and giving it a time zone would invent precision the domain does not have.

**2. The clock is injected, never read from the system inside a use case.**

```kotlin
public class GetOfflineClassScheduleUseCase internal constructor(
    private val repository: OfflineClassRepository,
    private val today: () -> LocalDate,
)
```

**This is the whole reason the window rule is testable**, and it is the same seam DN-006 cut for the
HTTP engine. A use case that calls `Clock.System.todayIn(...)` can only be tested on the day the test
happens to run: *"a class on 30 September is inside the window"* is true in August and false in
October, so the suite would rot on a calendar rather than on a code change.

`DNDataLayer` supplies the real clock, so no caller sees the seam.

**3. Models.**

```kotlin
public data class OfflineClass(
    public val id: String,
    public val name: String,
    public val imageUrl: String,
    public val price: Long,
    public val date: LocalDate,
    public val materials: List<String>,
    public val remainingQuota: Int,
)

public enum class OfflineClassAvailability { AVAILABLE, NEARLY_FULL, FULL }

public data class OfflineClassMonth(
    public val year: Int,
    public val month: Month,
    public val classes: List<OfflineClass>,
)
```

- **`materials` is a list, not a joined string.** It is a list in the domain and a list on the wire;
  joining it to be split again later loses any material that contains a comma. Settled with the
  owner on 2026-08-09, who had first suggested the joined form.
- **`remainingQuota` is carried, and `OfflineClass.availability` derives from it** as a computed
  property on the model — a total function of one field, with no I/O. It is not stored, so the two
  cannot drift.
- **The reader never sees `remainingQuota`.** It stays public because the availability rule is
  derived from it and a test has to be able to construct the boundary cases; the requirement's rule
  is about what the *screen* shows, and that is DN-036's job.

**4. The window rule, and what counts as "next month".**

```
date >= today   AND   date <= last day of (today's month + 1)
```

Both bounds are inclusive. **A class dated today is in** — owner's decision. The upper bound is the
*end* of next month, not "today plus 31 days": on 30 August the window still reaches 30 September,
and on 1 August it reaches the same day. Anchoring to the month boundary is what makes the screen
show *"August and September"* rather than a rolling four-and-a-half weeks.

**5. Grouping, and the month that is not there.**

Classes are grouped by `(year, month)`, months ascending, classes inside a month ascending by date.

**A month with no classes in the window produces no group at all.** The requirement does not say, and
an empty section with a heading and nothing under it is worse than no section: it reads as a loading
failure. It is covered by a test rather than by the fixture — see the correction under §7.

**6. `DNFormat` gains four functions**, per §10 — every one of these is wording derived from data,
which Android must not reimplement:

| Function | Result |
|---|---|
| `offlineClassPrice(value: Long)` | `HTM Rp150.000` |
| `offlineClassDate(date: LocalDate)` | `Rabu, 2 Sept 2026` |
| `offlineClassAvailabilityLabel(availability)` | `MASIH BISA DAFTAR` / `HAMPIR PENUH` / `SUDAH PENUH` |
| `offlineClassMonthTitle(year, month)` | `Agustus 2026` |

`offlineClassPrice` composes `rupiah` rather than reformatting — *"HTM "* prefixed to the existing
output, so the two can never punctuate a number differently.

**Indonesian weekday and month names live here**, hardcoded, for the same reason `rupiah` hardcodes
its separator: a student with an English phone must still read *Rabu*, because the date belongs to
the class and not to the reader's locale setting.

**7. Contract and stub.**

`docs/contracts/offline-classes.json` — a new approved wire shape, with `date` as ISO-8601
(`2026-09-02`) and `materials` as an array of strings. `StubRemoteDataSource` replays it through the
real decoding path, as every other fixture does.

**Quotas are chosen so all three states are reachable**: `AVAILABLE`, `NEARLY_FULL` and `FULL`.
[ASSUMPTION] the owner's poster states no quota, and the requirement asks that the sample data not
leave two of the three states unreachable — a state nobody can see on a screen is a state nobody
reviews.

**Correction to the plan above, made while building it.** The ticket first said the fixture would
hold only the owner's three September classes. It holds **eleven**, and the reason is that three
would have left the screen with a single section — so the sections, the arrows and the per-month
count, which are most of DN-036, could not be checked at all. The extra rows use the six August
dates the owner supplied as an example (12, 15, 19, 22, 26 and 29 August, all verified against a
real calendar) and repeat the same three class types, since the schedule is monthly and recurring.
It also carries **5 August** (already past) and **7 October** (beyond the window) so the window rule
is proven against the real fixture, not only against hand-built lists.

## Public API contract

New public symbols: `OfflineClass`, `OfflineClassAvailability`, `OfflineClassMonth`,
`GetOfflineClassScheduleUseCase`, `DNDataLayer.getOfflineClassSchedule`, and four `DNFormat`
functions. `kotlinx.datetime.LocalDate` and `Month` become part of the public surface.

Nothing existing changes; nothing is removed.

**Version bump implied:** **minor** — purely additive public API.

## Out of scope

- **Buying, booking or reserving.** No endpoint, no model, no state. The screen's button says the app
  cannot do it yet.
- **Showing the remaining quota to a reader.** Carried, never rendered — DN-036 enforces that.
- **A real backend.** `getOfflineClassSchedule` runs on the stub like everything else.
- **Time of day.** A class has a date; when it starts is not modelled and was not asked for.
- **Time zones.** The clock resolves one `LocalDate` in the system zone at the composition root.
- **Android.** Does not exist.

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`, both platforms. Cases, not "add tests":

**The window** — with the clock pinned to 2026-08-09:

| Class date | In the list? | Why |
|---|---|---|
| 2026-08-08 | no | yesterday |
| 2026-08-09 | **yes** | today is inside |
| 2026-08-12 | yes | later this month |
| 2026-09-30 | yes | last day of next month |
| 2026-10-01 | no | one day past the window |

Plus the December pin: with the clock at 2026-12-15, the window reaches 2027-01-31 — the year has to
roll, and an off-by-one on the month arithmetic shows up here and nowhere else.

**Availability** — 11 → `AVAILABLE`, 10 → `NEARLY_FULL`, 1 → `NEARLY_FULL`, 0 → `FULL`. The
boundaries are the point; 11 and 10 are the pair that catches a `>` written as `>=`.

**Grouping** — two months come back in calendar order; classes inside a month come back by date; a
month with no classes in the window produces no group.

**Formatting** — `HTM Rp150.000`; `Rabu, 2 Sept 2026` for a date whose weekday is known
independently; all three availability labels; `Agustus 2026`.

**Stub replay** — the fixture decodes through the real path, and the three sample classes land on
three different availability states.

## Done when

- [ ] `kotlinx-datetime` added, both platforms compiling
- [ ] Models, enum and use case implemented; `explicitApi()` clean
- [ ] The clock is injected and the window is proven at pinned dates, including the year roll
- [ ] Availability derived, never stored, with boundary tests at 11/10/1/0
- [ ] `DNFormat` gains the four functions; no Indonesian wording added anywhere else
- [ ] `docs/contracts/offline-classes.json` written; stub replays it through the real decoding path
- [ ] `./gradlew :sharedLogic:check` green on both platforms
- [ ] Committed, not merged
- [ ] PR merged, ticket marked `done` by the human

## Notes

**The first ticket to add a dependency to the data layer**, and the first to put a third-party type
in the public API. Both are worth naming: `LocalDate` crossing the SKIE boundary means the iOS app
takes a transitive dependency on `kotlinx-datetime`'s Swift face, and the same will be true of
Android's Kotlin one. That is accepted here because the alternative — a home-grown date triple — puts
calendar arithmetic in the one place this project cannot afford to get subtly wrong.

## Implementation notes (2026-08-09)

**`kotlinx-datetime` 0.7.1 works with Kotlin 2.3.21**, and the dependency is declared `api(...)` in
`commonMain` plus `export(...)` on the iOS framework — both are required, and for different reasons.
`api()` is what lets an Android consumer see `LocalDate` at all; `export()` is what puts the type in
the framework's own headers, without which Swift receives an opaque box it cannot construct and no
`#Preview` of an offline class is possible. It bridged cleanly: `LocalDate(year:month:day:)`,
`Month.september`, and `OfflineClass(id:name:imageUrl:price:date:materials:remainingQuota:)`.

**The clock is `() -> LocalDate`, not a `Clock`.** kotlinx-datetime 0.7 moved `Clock` to
`kotlin.time`, so taking the interface would have tied the seam to a type that had just moved. A
function of no arguments is smaller, has no deprecation surface, and is trivially pinned in a test.

**`else` on a `when` over `DayOfWeek` and `Month` is redundant** — both are ordinary Kotlin enums
here, so the compiler warns. Removed rather than left.

**Test names cannot contain a comma.** Kotlin/Native rejects backtick names with `,` as *"Name
contains illegal characters"*, which the Android host run accepts happily — so it fails only on the
half of `check` that runs second. Four names were rewritten.

**154 test cases pass on both platforms**, up from 117. The window is proven at pinned dates,
including the December year-roll and 31 January + 1 month, which is the case a naive
`plus(DatePeriod(months = 1))` on the day itself would get wrong.

**The fixture carries a class outside the window at each end** — 5 August (past) and 7 October
(beyond) — and a stub test asserts neither reaches a caller. The rule is therefore proven against
the real fixture and not only against hand-built lists.
