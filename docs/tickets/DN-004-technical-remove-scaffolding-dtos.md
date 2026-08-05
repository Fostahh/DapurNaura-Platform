---
id: DN-004
type: technical
title: Delete the leftover scaffolding DTO and endpoint from DNLibrary
status: in-review
source: —
branch: ticket/DN-004-remove-scaffolding-dtos
layer: data
---

## Rationale

`DNLibrary` still contains a throwaway DTO and the single endpoint that fed it, left over from
early pipeline scaffolding. It is unrelated to the cooking-class domain and models nothing the app
will ever show.

It is not harmless:

- **It is the library's public API.** Every field is nullable, which is why consuming Swift needed
  `?? "…"` everywhere. It sets the wrong precedent for the domain models that replace it.
- **It anchors the wrong request shape.** `baseUrl` is currently a *full endpoint* concatenated
  with `?key=`. That only works because there is exactly one endpoint. The first real endpoint
  breaks it, and keeping the scaffolding hides the problem.
- **It contradicts the documentation.** The platform docs now describe a cooking app with no
  legacy domain. While these types exist, the docs are inaccurate — the failure mode this
  workspace explicitly tries to avoid.

The iOS app no longer references any of it: `ios/DapurNaura` has no package dependency at all, so
deleting these types breaks no consumer today. **This is the cheapest it will ever be.**

## Context

Read before starting:

- `sharedLogic/src/commonMain/.../remote/network/responses/` — the DTO to delete
- `sharedLogic/src/commonMain/.../remote/RemoteDataSource.kt` — its only consumer
- `sharedLogic/src/commonMain/.../remote/network/NetworkManager.kt` — holds `baseUrl`
- `CODEBASE-STANDARD.md` §2 (public API) and its known-violations table

## Technical approach

- Delete the scaffolding DTO file and every reference to it.
- Delete the fetch method that returned it from `IRemoteDataSource` / `RemoteDataSource`.
- Leave the data layer with **no endpoints**. That is the correct intermediate state — the first
  real endpoint arrives with the domain model, not before.
- Update `CODEBASE-STANDARD.md`'s known-violations table: the "DTOs are the public API" row is
  resolved by deletion rather than by fixing it.

**Do not model the domain in this ticket.** `CookingClass` and `Recipe` need a settled JSON
contract, which does not exist yet. Deleting and modelling in one ticket would mix a mechanical,
reviewable removal with a design decision.

## Public API contract

**Breaking** — the entire current public surface is removed. Acceptable, and the reason to do it
now: no consumer exists. `ios/DapurNaura` has no dependency on the library.

**Version bump implied:** major under `0.x`, i.e. cheap. Nothing to coordinate.

## Out of scope

- Modelling `CookingClass` / `Recipe` — needs the JSON contract first
- The `baseUrl`-is-a-full-endpoint defect — surfaces properly with the first real endpoint
- `DNNetworkManager` testability and hardening — DN-002
- `SecureStorage` — DN-001

## Test plan

`./gradlew :sharedLogic:check` from `DNLibrary/`.

There is nothing to unit-test in a deletion. The check that matters is that the module still
compiles for both targets with no endpoints and no DTOs, and that `explicitApi()` still passes.

## Implementation notes (2026-08-06)

- Landed stacked on `ticket/DN-002-…` (ascending execution order, same files).
- The "empty data layer" intermediate state was brief by instruction: the owner requested the
  first real endpoint mid-session, ticketed as DN-008 on top of DN-006.
- The bare-`Exception` known-violations row was re-pointed at the storage actuals — deleting the
  scaffolding removed the RemoteDataSource rethrow, but the same pattern still exists in
  `SecureStorage.*.kt` / `PreferenceStorage.*.kt` until typed errors land.

## Done when

- [x] Scaffolding DTO and its fetch method deleted; no references remain
- [x] `./gradlew :sharedLogic:check` green
- [x] `CODEBASE-STANDARD.md` known-violations table updated
- [x] No markdown in the workspace names the deleted types (verified by grep)
- [x] Committed on `ticket/DN-004-remove-scaffolding-dtos` (`81c0df5`), not merged
- [ ] PR merged, ticket marked `done` by the human
