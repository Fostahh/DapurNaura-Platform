---
id: DN-006
type: technical
title: Make DNNetworkManager testable — engine seam, resettable instance
status: todo
source: —
branch: ticket/DN-006-network-engine-seam
layer: data
---

## Rationale

No meaningful unit test can be written against the network layer, and the platform Definition of
Done requires unit tests for every data-layer ticket. Three defects cause this, all long documented
in `ARCHITECTURE-AND-WORKFLOW.md` §8.1 but never ticketed — so the prerequisite for every
test-bearing ticket was a note, not schedulable work. This ticket fixes that.

1. **No engine seam.** `DNNetworkManager` constructs `HttpClient { }` in the class body with no
   engine parameter, so it always picks the platform-default engine. Ktor's `MockEngine` cannot be
   injected, so no request/response path can be exercised in a test.
2. **The singleton cannot be reset.** The constructor is private and `initialize()` returns the
   *existing* instance if one is set — tests cannot get a fresh instance, so test #2 silently
   inherits test #1's configuration.
3. **`RemoteDataSource` depends on the concrete `DNNetworkManager`**, not an abstraction, so it
   cannot be constructed against a test double.

Tests are also the only feedback loop an agent has in this repository — it cannot run the app and
look. Until this lands, data-layer work is unverifiable by the agent doing it.

## Context

Read before starting:

- `sharedLogic/src/commonMain/.../remote/network/NetworkManager.kt` — the file being changed
- `sharedLogic/src/commonMain/.../remote/RemoteDataSource.kt` — the dependent consumer
- `CODEBASE-STANDARD.md` §6 — "Constructor injection everywhere. No singleton may appear in a
  tested path." — and the known-violations table
- `docs/tickets/DN-002-technical-network-manager-hardening.md` — overlapping work, see below
- `docs/tickets/DN-004-technical-remove-scaffolding-dtos.md` — ordering, see below

Ordering constraints:

- **After DN-004.** The scaffolding DTO and endpoint are scheduled for deletion; there is no reason
  to build a seam under code that is about to be removed. Land the deletion first, then this on the
  smaller surface.
- **With or before DN-002.** Both tickets rewrite `NetworkManager.kt`, and DN-002's test plan
  (cases 3–5) explicitly needs this seam. DN-002 already says: decide with the human whether to
  fold the two together or sequence them — do not implement both independently.

## Technical approach

The shape, with the final choice made at implementation:

- `DNNetworkManager` accepts an `HttpClientEngine` and passes it to `HttpClient(engine) { … }`;
  when none is supplied, the platform default is used as today.
- Prefer removing the singleton in favour of constructor injection from the platform edge — that is
  what `CODEBASE-STANDARD.md` §6 requires, and the DI shape (§8.4 of the architecture doc) already
  forces platform-edge injection for storage. If `initialize()`/`getInstance()` is kept for Swift
  ergonomics, add an `internal` reset so tests can obtain a fresh instance — and document that it
  exists for tests only.
- `RemoteDataSource` takes an abstraction (or the `HttpClient` directly) rather than the concrete
  manager.
- Do not let Ktor types leak into the *public* surface: the engine parameter should be reachable
  from tests (same module, `internal` is enough) without becoming part of the binary API Swift sees.

**Hardening stays out.** Timeouts, JSON strictness, `config`/`httpClient` visibility and HTTPS
validation are DN-002's scope, even though the same file is touched.

## Public API contract

Intended: **no new public surface.** Consumers keep initialising the library the same way; the seam
is internal. If keeping that true proves impossible (e.g. the initialisation shape must change),
record the actual before/after here before review.

**Version bump implied:** patch if the public surface is untouched; major if `initialize` changes
shape. Settle at implementation and record it here.

## Out of scope

- Timeouts, strict JSON, symbol visibility, HTTPS validation — DN-002
- Typed/sealed errors across the boundary — separate planned work
- Domain modelling against `docs/contracts/` — needs DN-004 and this ticket first
- `SecureStorage` — DN-001

## Test plan

These are the **first tests in the repository** — creating the missing test source directories
(`sharedLogic/src/commonTest/`, plus host-test source sets as needed) is part of this ticket.

`./gradlew :sharedLogic:check` from `DNLibrary/`:

1. A manager built over `MockEngine` serves a canned 200 response through its client — proves the
   seam exists and the JSON pipeline is exercised end to end.
2. Two consecutive test setups observe independent configuration — proves the fresh-instance /
   no-singleton behaviour. This is the case that fails today.
3. `RemoteDataSource` (or its post-DN-004 successor) can be constructed against the mock-backed
   manager with no global state.

## Done when

- [ ] Engine injectable; a test can obtain a fresh, independently configured instance
- [ ] No singleton in any tested path (`CODEBASE-STANDARD.md` §6)
- [ ] First unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [ ] `CODEBASE-STANDARD.md` known-violations table updated (engine-seam row, zero-tests row)
- [ ] Committed on `ticket/DN-006-network-engine-seam`, not merged
- [ ] PR merged, ticket marked `done` by the human
