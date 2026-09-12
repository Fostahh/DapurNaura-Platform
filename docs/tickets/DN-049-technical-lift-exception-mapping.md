---
id: DN-049
type: technical
title: The exception-to-DNError mapping is copied in three repositories, and the second copy said when to stop
status: done
source: —
branch: ticket/DN-049-lift-exception-mapping
layer: data
---

## Rationale

**`private fun Throwable.toDNError()` now exists three times, identically**, in
`CookingClassRepository`, `OfflineClassRepository` and `PaymentRepository`.

**The second copy named the condition for lifting it, and DN-047 met it.** From
`OfflineClassRepository`:

> "The same mapping `CookingClassRepository` uses, kept here rather than shared because that one is
> `private` to its file. Two short `when`s that agree beat one shared symbol that has to be widened
> — and if a third endpoint appears, that is the moment to lift it."

DN-047 added the third endpoint. **The judgement was already made; this ticket only carries it out.**

**It was deliberately not done inside DN-047.** Lifting it touches two repositories that ticket had
no other reason to open, and a refactor riding along inside a feature is what DN-039 and DN-046 were
split out to avoid — a reviewer looking at payment destinations should not have to also check that
class fetching still maps its errors correctly.

**Nothing is broken.** All three copies agree today, which is exactly why this is worth doing now
rather than after they stop agreeing. The risk is not the duplication, it is that a fix applied to
one copy leaves two endpoints reporting a failure differently from the third.

## Context

Read before starting:

- `datasource/repository/CookingClassRepository.kt`, `OfflineClassRepository.kt`,
  `PaymentRepository.kt` — the three copies, each `private` to its file
- `domain/model/DNError.kt` — the target type, and `userMessage` beside it
- `docs/CODEBASE-ARCHITECTURE.md` §3 — the repository is where exceptions die

**Check they are still identical before lifting.** If one has drifted, the drift is the finding and
this ticket reports it rather than quietly picking a winner.

## Technical approach

One `internal` extension in `datasource/repository/`, and the three copies deleted.

**It stays `internal`.** It maps Ktor and kotlinx exceptions, which are implementation detail; making
it public would put Ktor's vocabulary in the Swift API.

**It does not move to `domain/`.** `DNError` is domain, but the *mapping* is about what the transport
throws, and §1 points dependencies inward — a domain file that knew about `ResponseException` would
invert that.

**Order matters and must be preserved exactly**, most specific first:

```kotlin
is ResponseException -> DNError.Http(response.status.value)
is HttpRequestTimeoutException -> DNError.Network
is JsonConvertException -> DNError.Contract
is SerializationException -> DNError.Contract
is IOException -> DNError.Network
else -> DNError.Unknown(message)
```

`HttpRequestTimeoutException` before `IOException` and `JsonConvertException` before
`SerializationException` are both load-bearing — reordering them changes which `DNError` a failure
becomes without changing a test that only checks the common paths.

## Public API contract

None. Everything involved is `internal`.

**Version bump implied:** none in itself. If it rides with other work, that work's bump applies.

## Out of scope

- **Changing what any exception maps to.** A pure lift: same cases, same order, same results.
- **Adding cases**, including the `Http(4xx)` gap the payment requirement records — that one is a
  wording change to `userMessage` and belongs with the upload API.
- **Touching the repositories otherwise.**

## Test plan

`./gradlew :sharedLogic:check` — the existing suite already covers every branch through all three
endpoints, so a green run after the lift is the proof. **No new tests are needed and none should be
added**: if the existing ones do not catch a broken mapping, that is a finding about the suite, not
a reason to write a fourth copy of the same assertions.

## What was found and done, 2026-09-12

**The three copies were still byte-identical** — the drift the *Context* section told this ticket to
check for had not happened, so there was no finding to report and the lift was a pure move.

`Throwable.toDNError()` now lives once, `internal`, in
`datasource/repository/ThrowableToDNError.kt`. **The `when` body was verified byte-identical to the
original by diff**, not by eye, because the case order is the one thing here that can break silently.

**Eighteen imports went with it — six per file**, including `DNError` itself, which none of the three
repositories referenced once the mapping left: they name only their own sealed results. The compiler
and ktlint would have caught these, but they are worth naming because "delete the function" reads
like a smaller change than it is.

| | Before | After |
|---|---|---|
| Definitions of the mapping | 3 | **1** |
| Lines across the three repositories | — | **−48** |
| New file | — | +18 |

**`CancellationException` was left exactly as it was** — caught separately and rethrown ahead of the
general catch, in all three repositories. It is coroutine control flow rather than a failure, and
folding it into the mapping would swallow cancellations. Now written into
`docs/CODEBASE-ARCHITECTURE.md` §3 so it is a rule rather than a habit.

**No tests were added, deliberately**, as the *Test plan* requires. The suite stayed at 85 on both
platforms, which is the point: the existing tests already drive every branch through all three
endpoints, so an unchanged green run is the proof the lift changed nothing.

## Done when

- [x] One `internal` mapping exists; all three private copies are gone
- [x] Case order preserved exactly — verified by diffing the `when` body against `HEAD`
- [x] `:sharedLogic:check` green on both platforms — **85 tests, 10 classes, 0 skipped, 0 failures**,
      read from the result XML; the same count as before, since no test was added or removed
- [x] No public API change, `explicitApi()` clean — everything involved is `internal`, and the build
      enforces it
- [x] Documentation sweep (DN-042) — enumerated, then read. `CLAUDE.md` §3 and
      `CODEBASE-ARCHITECTURE.md` §3 both remained true; §3 of the latter **gained** the rule that
      there is now one shared mapping, since preventing a fourth copy is this ticket's whole point
- [x] Diff reviewed by the owner — approved 2026-09-12
- [x] Committed — one commit in `DNLibrary`, one in the umbrella
- [x] PR opened — [DNLibrary#23](https://github.com/Fostahh/DNLibrary/pull/23). **The umbrella takes
      no PR**; its branch is merged locally
- [x] PR merged — the owner confirmed, 2026-09-12.
      [DNLibrary#23](https://github.com/Fostahh/DNLibrary/pull/23) at `3846a86`. The umbrella branch
      is merged locally by the owner and takes no PR

## Notes

**Filed from inside DN-047 rather than noticed later**, which is the part worth keeping: the rule for
when to lift it was written into the code by the ticket that made the second copy, so the third
copy's author did not have to decide anything. That is a comment doing the job a comment is actually
good at — recording a condition that fires later.
