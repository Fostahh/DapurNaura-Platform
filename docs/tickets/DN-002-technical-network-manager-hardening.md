---
id: DN-002
type: technical
title: Harden DNNetworkManager — timeouts, strict JSON, hide internals
status: todo
source: —
branch: ticket/DN-002-network-manager-hardening
layer: data
---

## Rationale

`sharedLogic/src/commonMain/.../remote/network/NetworkManager.kt` has four defects, separate from
the well-known testability problem:

```kotlin
class DNNetworkManager private constructor(val config: DNNetworkManagerConfig) {
//                                          ↑ (3) public — Swift can read config.apiKey

    val httpClient = HttpClient {          // ↑ (4) public — the raw Ktor client escapes the library
        install(ContentNegotiation) {
            json(Json {
                prettyPrint = true         //   (2) pointless for a decoding client
                isLenient = true           //   (2) accepts malformed JSON
                ignoreUnknownKeys = true   //       correct — keep
            })
        }
    }                                      //   (1) no HttpTimeout — a hung request hangs forever
}
```

1. **No timeouts.** A stalled connection never returns. On a phone with poor signal — which is the
   normal case for this app's audience — a recipe screen can hang indefinitely with no error path.
2. **`isLenient = true`** accepts malformed JSON, which hides exactly the contract violations
   development should surface. `prettyPrint` only affects encoding and this client decodes.
3. **`config` is public**, so `DNNetworkManager.getInstance().config.apiKey` is reachable from
   Swift. A key should not be readable back out of the library that was handed it.
4. **`httpClient` is public**, so the raw Ktor client is part of the binary API. Any consumer can
   bypass the data layer entirely, and Ktor's own types leak into the public surface — meaning a
   Ktor upgrade can become a breaking change for the apps.

Points 3 and 4 violate `CODEBASE-STANDARD.md` §2 (only domain models, use cases, the factory and
result types are public). Point 1 violates §9. Point 2 violates §9.

## Context

Read before starting:

- `sharedLogic/src/commonMain/.../remote/network/NetworkManager.kt` — the file being changed
- `sharedLogic/src/commonMain/.../remote/RemoteDataSource.kt` — the only consumer of `httpClient`
- `ios/DapurNaura/DapurNaura/DapurNauraApp.swift` — calls `initialize(config:)` at startup
- `CODEBASE-STANDARD.md` §2 and §9

**Overlaps with planned work.** A future ticket makes the HTTP engine injectable and removes the
singleton, and it touches this same file. Landing this ticket first means that one rebases onto it;
landing them together is also reasonable. **Decide before starting** — do not implement both
independently and resolve conflicts afterwards.

Note also that `enableNetworkLogging` has been agreed as a config flag for development. It is not
part of this ticket unless the human folds it in.

## Technical approach

- Install Ktor's `HttpTimeout` plugin with explicit request, connect and socket timeouts.
- Remove `isLenient` and `prettyPrint`; keep `ignoreUnknownKeys = true`.
- Make `config` non-public. If a caller genuinely needs the base URL, expose that single value —
  never the key.
- Make `httpClient` `internal` so only the data layer can reach it.
- Reject a non-HTTPS `baseUrl` at config time rather than trusting the caller (§9).

## Public API contract

**Breaking**, though nothing is known to depend on the removed surface:

| Symbol | Before | After |
|---|---|---|
| `DNNetworkManager.config` | public | internal |
| `DNNetworkManager.httpClient` | public | internal |

The app consumes `RemoteDataSource`, not these, so no consumer change is expected — but this must
be confirmed against `ios/DapurNaura` before landing.

Adding HTTPS validation means an `http://` base URL that previously worked now fails at
initialisation. That is intended.

**Version bump implied:** major — public symbols are being removed. Under `0.x` this is expected
and cheap, which is a reason to do it now rather than after `1.0.0`.

## Out of scope

- Making the HTTP engine injectable, and removing the singleton — separate planned ticket
- The `enableNetworkLogging` flag
- `baseUrl` being a full endpoint concatenated with `?key=` — a real defect, but it changes the
  request-building shape and belongs with the endpoint work
- Certificate pinning
- `SecureStorage` — see DN-001

## Test plan

`./gradlew :sharedLogic:check`.

1. A `baseUrl` beginning `http://` is rejected at config time with a clear error
2. An `https://` base URL is accepted
3. Malformed JSON now fails to decode rather than being silently accepted — the case that passes
   today because of `isLenient` and must fail after
4. Unknown JSON fields are still ignored (confirms `ignoreUnknownKeys` survived)
5. A request that exceeds the configured timeout produces a timeout failure rather than hanging

Tests 3–5 need a controllable client. If the engine seam does not exist yet, note in the ticket
which cases had to be deferred rather than silently skipping them.

## Done when

- [ ] Timeouts configured; `isLenient` and `prettyPrint` removed; `config` and `httpClient` internal
- [ ] Non-HTTPS base URL rejected at config time
- [ ] Confirmed `ios/DapurNaura` does not reference `config` or `httpClient`
- [ ] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [ ] `CODEBASE-STANDARD.md` known-violations table updated
- [ ] Committed on `ticket/DN-002-network-manager-hardening`, not merged
- [ ] PR merged, ticket marked `done` by the human
