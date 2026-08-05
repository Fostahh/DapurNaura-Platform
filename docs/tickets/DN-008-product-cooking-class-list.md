---
id: DN-008
type: product
title: Data layer — fetch the list of cooking classes
status: in-review
source: — (verbal instruction from the owner, 2026-08-06 — see below)
branch: ticket/DN-008-cooking-class-list
layer: data
---

## Requirement (traced)

> "You need to create a network manager and implement 1 API call for get list of cooking classes."
> — the owner, verbally, 2026-08-06, mid-session.

**Process deviation, flagged:** a product ticket normally traces to a document in
`docs/requirements/`, but the owner has explicitly deferred writing requirement documents. This
quote is the requirement until one is backfilled. The network-manager half already exists and was
hardened/made testable under DN-002/DN-006; this ticket delivers the API call.

The JSON shape is **not** open: `GET /classes` is defined by the approved contract —
[`docs/contracts/classes.json`](../contracts/classes.json) and the conventions in
[`docs/contracts/README.md`](../contracts/README.md).

## Context

Read before starting:

- `docs/contracts/classes.json` — the exact payload; fixtures quote it verbatim
- `docs/contracts/README.md` — ids are strings, prices integer rupiah, `purchaseStatus` is an enum
  and a UI hint only
- `CODEBASE-STANDARD.md` §1–§3 — layering (UseCase → IRepository → IRemoteDataSource), public API
  rules (DTOs internal, domain models public), sealed results (never throw across the boundary)
- `sharedLogic/.../remote/network/NetworkManager.kt` — the DN-006 shape this builds on

## Technical approach

The first vertical slice of the domain, per the standard:

- **DTOs (`internal`)** — `ClassesResponse` / `CookingClassResponse`, `@SerialName` on every
  field, nullability matching the contract (the server always sends every field → non-null).
- **Domain model (`public`)** — `CookingClass` + `PurchaseStatus` enum.
- **Sealed results (`public`)** — `CookingClassesResult.Success/Failure` and `DNError`
  (`Network` / `Http(status)` / `Contract` / `Unknown`). Concrete rather than generic: §2 avoids
  generics in the public API.
- **`RemoteDataSource` (`internal`)** — `GET {baseUrl}/classes`, API key in an `X-Api-Key` header.
  `[ASSUMPTION]` the header name — no backend exists to dictate one; revisit when it does.
- **Repository (`internal`)** — maps DTO → domain and exceptions → `DNError`. Nothing throws past
  it.
- **Use case (`public`)** — `GetCookingClassesUseCase`, the one entry the UI calls.
- **Factory (`public`)** — `DNDataLayer(config)`: hand-wires the graph (§1); also carries the
  internal engine seam so tests drive the whole stack through MockEngine.
- `DNNetworkManager` and `RemoteDataSource` become `internal` — consumers now enter through the
  factory, completing §2's intended public surface.
- `expectSuccess = true` on the client so non-2xx surfaces as a typed HTTP error.

## Public API contract

New public surface: `DNDataLayer`, `GetCookingClassesUseCase`, `CookingClassesResult`, `DNError`,
`CookingClass`, `PurchaseStatus`. Removed from public: `DNNetworkManager` (now `internal`),
`IRemoteDataSource` / `RemoteDataSource` (now `internal`).

**Version bump implied:** major under `0.x` — the public surface is reshaped. Zero consumers.

## Out of scope

- Class detail, recipes, `GET /classes/{id}`, `GET /recipes/{id}` — next slices, same pattern
- Any UI in `ios/DapurNaura` — the app has no DNLibrary dependency; wiring it is its own ticket
- Payment, entitlement enforcement (server-side by contract design)
- Typed errors for the storage classes

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`. Fixtures are JSON strings quoting
`docs/contracts/classes.json` verbatim (§6), driven through the factory + MockEngine:

1. The contract payload decodes: 3 classes, ids as strings, `price` 150000, all three
   `purchaseStatus` values mapped
2. The request hits `/classes` and carries the API key header
3. HTTP 500 → `Failure(Http(500))`; HTTP 403 → `Failure(Http(403))`
4. Malformed JSON → `Failure(Contract)`; a missing required field → `Failure(Contract)`
5. A connection failure → `Failure(Network)`

## Implementation notes (2026-08-06)

- Implemented exactly as approached; seven tests, all green on both platforms, fixtures quoting
  the contract verbatim.
- `DNDataLayer` carries the engine seam forward: the tests drive use case → repository → data
  source → serialization through the factory with only the engine substituted.
- The `currency` field is carried as-is from the contract into the domain model. The owner still
  needs to decide whether it is meaningful or dead weight (flagged at contract review) — if it is
  dropped from the contract, DTO + model + fixture change together.
- Swift consumption note for the eventual UI ticket: `getCookingClasses` is a `suspend operator
  invoke` — SKIE exposes it as an async callable; the sealed result gives an exhaustive `switch`.

## Done when

- [x] Slice implemented as above; `explicitApi()` clean
- [x] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [x] `CODEBASE-STANDARD.md` known-violations table updated (`baseUrl` row resolved here)
- [x] Committed on `ticket/DN-008-cooking-class-list` (`b34a756`), not merged
- [ ] PR merged, ticket marked `done` by the human
