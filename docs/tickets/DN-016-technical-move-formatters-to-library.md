---
id: DN-016
type: technical
title: Move rupiah formatting and the Indonesian error vocabulary into DNLibrary
status: in-progress
source: —
branch: ticket/DN-016-move-formatters-to-library
layer: both
---

## In plain language

Two pieces of text the user sees are currently produced by the iPhone half of the app: prices
(`Rp150.000`) and error messages (*"Tidak dapat terhubung…"*).

An Android app is planned. If these stay where they are, Android has to write them a second time —
and sooner or later the same error will be worded two different ways on the two phones, or a price
will be punctuated differently. Neither version is tested today.

This moves both into the shared half, which both phones use and which has tests. Write once, test
once, both platforms agree.

The trade, accepted knowingly: changing the wording of an error is no longer a one-line edit. It
becomes a library release.

## Rationale

DN-014 decided that display formatting derived from data belongs in DNLibrary, not in Swift. This is
the ticket that moves the two cases that already exist.

> **A ViewModel consumes. It does not compute, and it does not format.**
> — `CODEBASE-ARCHITECTURE.md` §10

Two files violate it:

| File | What it does | Why it must move |
|---|---|---|
| `DapurNaura/Shared/Rupiah.swift` | `150000` → `"Rp150.000"` | Android would reimplement it; the punctuation would drift |
| `DapurNaura/Shared/DNError+Message.swift` | `DNError` → Indonesian message | Android would reword the same failure differently |

The error vocabulary is the stronger case of the two. `DNError` is *already* a DNLibrary type — its
Swift extension is the only reason its wording lives on this side of the boundary. Every consumer of
that error type wants the same sentence.

There is a second benefit that is not the point but is real: `Rupiah.swift` allocates a
`NumberFormatter` on **every call**, from inside `body`, for every row on screen. Moving it deletes
that problem rather than fixing it.

## Context

Read before starting:

- **`ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md`** §10 — the rule, its boundary, and the accepted
  cost.
- **`DNLibrary/docs/CODEBASE-STANDARD.md`** §2 — the public API is a binary contract. Whatever is
  added here is a promise to two apps.
- **`docs/tickets/DN-014-technical-ios-codebase-architecture.md`** — the decision and the owner's
  reasoning.

Already true, and constraining:

- **Formatters are shared functions, not fields on domain models.** `CookingClass.price` stays a
  `Long`. Adding `priceLabel` to the domain model would turn it into a view model and break
  `CODEBASE-STANDARD.md` §2. This was decided explicitly in DN-014 — do not revisit it.
- **This ticket spans two repos and needs a published library version.** It is the first ticket to
  exercise the full release path: DNLibrary change → tests → `publish-spm.sh publish` → tag → GitHub
  release → app bumps off the local package. Expect it to take longer than its diff suggests.
- The library is unreleased, so this is additive on an unstable API.

## Technical approach

**DNLibrary**

- Add a public `DNFormat` (or equivalent) carrying `rupiah(value: Long): String`.
- Move the Indonesian error wording onto `DNError` itself, so the type that defines the failure also
  defines how it reads.
- Locale must be pinned explicitly, not taken from the device. `id_ID` grouping is what produces
  `150.000`, and a device set to another locale must not repunctuate a price.

**Tests** — required, this is the data layer. At minimum: the boundary values, a value under 1000
with no separator, and one case per `DNError` branch so a new error case cannot ship unworded.

**ios/DapurNaura**

- Delete `Rupiah.swift` and `DNError+Message.swift`.
- Call the library functions at the call sites.
- Strike the §10 row from `## Known violations`.

## Public API contract

Additive: one formatting entry point plus error wording on an existing public type. Nothing is
removed and nothing changes shape.

**Version bump implied:** **minor** — new public surface on an unreleased 0.x API.

## Out of scope

- **Date formatting.** No date is displayed yet. When one appears, decide then — `"2 hari lalu"` is
  data-derived and belongs in the library, but Swift's `Date.formatted()` is materially better than
  reimplementing it in Kotlin, and that trade should be made against a real screen.
- **View-context formatting** — truncation, choosing a short label because a card is narrow. §10
  keeps those in Swift; only the view knows.
- **Every other known violation.** That is DN-015.

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`, both platforms green. Report counts read from the
test-result XML, not inferred from `BUILD SUCCESSFUL`.

Then, on the app: prices and error messages must read **exactly** as they do today. This is a
refactor — if any user-visible string changes, it is a defect in this ticket, not an improvement.

The owner verifies the running app after `publish-spm.sh local`, per the platform's UI gate.

## Done when

Data-layer work:

- [ ] Implemented on `ticket/DN-016-move-formatters-to-library`
- [ ] Unit tests written and passing — `./gradlew :sharedLogic:check`
- [ ] Committed, not merged

UI work:

- [ ] Swift helpers deleted, call sites updated, §10 row struck from the known-violations table
- [ ] Verified manually by the human on the running app
- [ ] Committed, not merged

Always:

- [ ] PR merged, ticket marked `done` by the human
- [ ] Library published and the app bumped off the local package to the new version
