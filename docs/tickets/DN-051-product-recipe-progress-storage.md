---
id: DN-051
type: product
title: Remember which ingredients are ticked, and which page the cook was on, across app restarts
status: in-review
source: docs/requirements/2026-09-12-cooking-a-recipe.md
branch: ticket/DN-051-recipe-progress-storage
layer: data
---

## Rationale

From the requirement, *What is remembered between visits*. A cook ticks ingredients on page 1/3 of
the cooking flow; those ticks, and the page they reached, must survive the app being closed and
reopened.

**This reintroduces local storage, which DN-031 deleted.** `DNLibrary/CLAUDE.md` says it must not be
brought back *speculatively* — a stated requirement is not speculation, so the rule is satisfied, but
this is a real subsystem returning and is ticketed on its own rather than riding inside the UI work.

**It is deliberately not the deferred completion tracker.** Owner's instruction, translated,
2026-09-12:

> "Ticking all the ingredients is progress, and the backend does not need to know. It is just a
> local, on-device thing. If one user has two devices and the progress happens on device one, device
> two does not know about it."

**Two devices disagreeing is the accepted behaviour, not a gap.** The completion tracker the owner
described separately — *"some sort of tracker on the backend side"* — is blocked on auth and a
backend and is **out of scope here**.

## Context

Read before starting:

- `docs/requirements/2026-09-12-cooking-a-recipe.md` — *What is remembered between visits*, and
  *Page 1/3* for how a tick is keyed
- `DNLibrary/CLAUDE.md` — the local-layer section (DN-031) that this ticket reverses part of
- `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` §1 (nothing in `commonMain` constructs a
  platform-dependent type), §5 (Android parity is compiler-enforced), §9 (storage rules)
- `DNDataLayer.kt` — the composition root this will have to reach

## Technical approach

**What is stored, per recipe:**

- the set of ticked ingredients
- the page the cook was last on

**How a tick is keyed: the ingredient's name, scoped to its component.** Owner's decision — no id is
added to the contract. Verified against the fixture: no ingredient name repeats within a single
component, and *Gula halus*, which appears in both, is told apart by the component scope.

> **The component half of the key is its position, not its name.** `RecipeComponent.name` is
> `String?` and a null name cannot key anything. The ingredient half stays a name, as the owner
> asked. Recorded as an `[ASSUMPTION]` in the requirement.

**Nothing about this is `public` except what the app must call.** A use case to read progress and one
to record it; the storage itself stays `internal`, like every data source.

### The part that needs designing before a line is written

**`commonMain` cannot construct this.** Android's storage needs a `Context`; iOS's does not.
`CODEBASE-ARCHITECTURE.md` §1 is explicit that such a type *"must arrive as a constructor parameter
from the platform edge"*, and §4 says to **design for that from the first line, not after the
compiler says no.**

**So `DNDataLayer`'s constructor changes, and that is a public API movement** — the iOS app's
composition root changes with it. This is the ticket's main cost and the reason it is reviewed alone.

**`expect`/`actual` returns to the library.** DN-031 removed the only two that existed. §5 warns that
parity is compiler-enforced: an `expect` without an `androidMain` actual **will not compile**, so the
Android implementation is written now even though no Android app exists. It is testable — the suite
runs on the Android host — so it will not be untested, but it is work with no consumer today.

**The storage mechanism is chosen and justified in this ticket**, per §8 (*a new dependency must be
justified in the ticket that introduces it*). DataStore 1.1.7 is already in the version catalog and
unused; the alternative is `expect`/`actual` over each platform's native preferences. Whichever is
chosen, the argument is written down here.

## Public API contract

- `DNDataLayer` gains whatever the platform edge must inject for storage.
- Two use cases: read a recipe's progress, and record it.
- **Version bump implied: MINOR** — the entry point's constructor changes.

## Out of scope

- **The backend completion tracker.** Blocked on auth and a backend; the requirement says so.
- **Any UI.** The cooking flow is DN-052.
- **Syncing between devices.** Explicitly not wanted.
- **Storing anything else** — no tokens, no credentials. §9's rule stands: encrypted storage is for
  privileged data, plaintext for flags, and the two are never substitutable. Ticked ingredients are
  flags.

## Test plan

Data layer, so unit tests are required:

- Progress round-trips: record ticks and a page, read them back
- Ticks are scoped per recipe — recording one recipe's progress does not affect another
- The same ingredient name in two components is tracked independently, which is the
  *Gula halus* case the keying exists for
- An unrecognised name — as if an ingredient were renamed — is **forgotten rather than matched to the
  wrong row**, which is the failure mode this design accepts
- Reading progress for a recipe that has none returns an empty result, not a failure
- `./gradlew :sharedLogic:check` green on **both** platforms, since parity is compiler-enforced

## Done when

- [x] Progress and page persist across a process restart
- [x] Keyed by component position plus ingredient name, per recipe — verified against the fixture
      that no name repeats within a component
- [x] `expect`/`actual` implemented for both platforms; **the Android actual is real**, using
      `SharedPreferences`, not a stub. `androidMain` and `iosMain` had no Kotlin before this
- [x] The storage choice is justified — **no dependency added**; §9 says plaintext preference storage
      is what flags belong in, and `SharedPreferences` / `NSUserDefaults` are exactly that
- [x] `DNDataLayer`'s change is declared, and the **MINOR** bump stated
- [x] `./gradlew :sharedLogic:check` green on both platforms — **97 tests, 12 classes, 0 skipped,
      0 failures**, read from the result XML. 85 before, +12 new
- [x] Documentation sweep (DN-042) — enumerated, then read. **Eight corrections across five
      documents and the build script.** The one worth naming: `CLAUDE.md` listed **DataStore 1.1.7**
      as a dependency, which has not been in the version catalog since DN-031
- [x] Diff reviewed by the owner — approved 2026-09-12
- [x] Committed — one commit in `DNLibrary`, one in the umbrella
- [x] PR opened — [DNLibrary#24](https://github.com/Fostahh/DNLibrary/pull/24). The umbrella takes no
      PR; its branch is merged locally
- [ ] PR merged

## What §3 settled, and why it is worth recording

The three use cases first returned plain values — `RecipeProgress` and `Unit` — on the agent's
argument that local storage cannot fail. **Put to the owner rather than decided quietly**, since §3
says every use case returns a sealed result and the *Known violations* table is empty by design.

**Owner's decision: follow §3, and their reason was better than the agent's.** *"Sometimes the local
data source can also return an error."* That is correct, and the agent had already written
`runCatching` for undecodable stored content while arguing there were no failures. A full disk, a
`commit()` that returns false, data protection on a locked device and corrupted content are all real.

Three tests now drive the failure path, which is what makes the sealed result worth having rather
than a one-branch switch at every Swift call site.
