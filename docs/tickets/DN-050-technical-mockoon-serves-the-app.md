---
id: DN-050
type: technical
title: The app runs on a local Mockoon server instead of the in-library stub
status: done
source: —
branch: ticket/DN-050-mockoon-serves-the-app
layer: data + ui
---

## Rationale

**Owner's instruction, 2026-09-12, translated:** *"Let's remove all of our hardcoded stub and etc
inside DNLibrary and transfer the stub into using Mockoon."*

The app has never had a backend. `DNDataLayer.stub()` replays the approved contract fixtures through
the real decoding path, which is what let every screen be built — but it replays them from **559
lines of JSON embedded in Kotlin source**, hand-transcribed from `docs/contracts/`. That is the
third copy of the same payloads, and the only one nothing can verify:

| Copy | Where | Kept in step by |
|---|---|---|
| The contract | `docs/contracts/*.json` (umbrella) | it is the source of truth |
| The stub | `StubRemoteDataSource.kt` (DNLibrary) | **a person remembering** |
| Mockoon | `~/Desktop/DapurNaura.json` | **a person remembering** |

**A local Mockoon environment already exists**, built 2026-09-12 from the contract fixtures: five
routes, thirteen responses, port 3001. It encodes two behaviours the stub only imitates — the
server-side `?category=` filter, and the **403 on a recipe of an unpurchased class** that makes
payment tamper-proof.

## What the owner decided, 2026-09-12

Two questions were put before any code was touched, with their consequences:

1. **The app moves to Mockoon; the stub stays for the tests.** It has two consumers, not one —
   `DapurNauraApp` and **fifteen test call sites across two test files**, eight of them in
   `GetRecipeUseCaseTest`, which are use-case tests that merely happen to get their data from
   `stub()`. Pointing `./gradlew :sharedLogic:check` at a server that has to be running would make
   the data layer's own gate fail on any machine without Mockoon up. **Rejected for that reason.**
2. ~~**Plain HTTP is allowed for localhost only.**~~ **Reversed the same day** — see *Reversed: the
   library keeps its https-only guard* below. `DNNetworkManagerConfig` still requires `https://`
   for every host without exception, and Mockoon serves TLS instead.

## Technical approach

### The app

- `DapurNauraApp` stops calling `DNDataLayer.companion.stub()` and constructs
  `DNDataLayer(config:)` from `DapurNauraAppConfig` — **its first caller**, which closes known issue
  4 in `ios/DapurNaura/CLAUDE.md`.
- `Development.xcconfig` points `API_BASE_URL` at the Mockoon environment. **This is the one edit
  that needed the owner's word**, because of the standing rule below.
- **No ATS exception was added.** See *App Transport Security* below — it is not needed, and the
  project's own rule is not to declare what the app does not use.

> **The standing rule this crosses.** *"Never edit the stale `API_BASE_URL` while there is no
> backend"* — the owner's emphatic instruction, given while all four xcconfigs pointed at RAWG. The
> premise was *no backend exists*; a local one now does. **Owner's decision, 2026-09-12:** the
> Development URL moves. **Alpha, Beta and Release keep the RAWG placeholder** until a real backend
> exists — the rule still holds for every configuration that ships.

### The library

> **Superseded the same day.** The owner first reaffirmed widening the guard — *"For development
> purpose, just make it like that"* — and then reconsidered, which is what produced the reversal
> recorded below. **Nothing in this section shipped.**
>
> The concern that decided it was already visible here: **the exception would have been on the URL,
> not on the build type**, so a Release build was not prevented from carrying it, and no test would
> have caught that because every test asserted the exception *worked*. Rather than gate it on a
> build-config flag the library does not have, the exception was removed and Mockoon was moved to
> TLS.

- ~~`require(baseUrl.startsWith("https://"))` gains one narrow exception.~~ **Not done — reversed.**
  The guard is untouched; `DNNetworkManagerConfigTest.kt` is byte-identical to `0.9.0`. Mockoon was
  moved to HTTPS instead, so the library needed no change at all.
- `StubRemoteDataSource` **stays**, and stays `public` through `DNDataLayer.stub()`. It is the path
  that still works with nothing running, and removing it would be a public API removal on a range
  pin — which breaks the app on *Update to Latest Package Versions* rather than at a bump anyone
  chose (CLAUDE.md, *Versioning*).

## Open questions

**Where the stub's JSON should come from, now that a third copy exists.** This is the part of the
owner's instruction — *"remove all of our hardcoded stub"* — that the answer above does not settle,
and it needs a decision before implementation.

`docs/contracts/` is in the **umbrella repo**; DNLibrary is a separate repository that must build
from its own clone. That is *why* the fixtures were transcribed into Kotlin in the first place. KMP
makes the obvious alternatives expensive: there is no resource directory in this module, no file-IO
dependency, and **every test runs on both JVM and iOS**, so "read the file at test time" means
either a new multiplatform IO dependency plus per-target test bundling, or nothing.

| Option | What happens | Cost |
|---|---|---|
| **A — codegen (recommended)** | The fixtures are committed to DNLibrary as real `.json` files; a Gradle task generates the Kotlin constants into `build/generated` at build time | The copy still exists, but it is **JSON diffable against the contract** instead of hand-typed Kotlin, and a one-line CI check can prove the two match. No new dependency, works on every target |
| B — read `../../docs/contracts/` | One copy, no duplication at all | DNLibrary stops building from a standalone clone. **Commits do not span projects** is a workspace rule; this would make the build span them |
| C — leave the constants | Nothing changes | The hand-transcription stays, and so does the copy nothing verifies |

**Recommendation: A.** It is the only one that removes the hand-transcription without making one
repository depend on another being checked out beside it.

### Answered, 2026-09-12 — none of the three

**Owner's decision:** *"For now, the JSON stays local in my device and no one can get it from other
than me."*

So **no fixture JSON is committed anywhere by this ticket**, and the Mockoon environment stays on
the owner's Desktop, untracked by any of the four repositories. The practical effect is option C —
`StubRemoteDataSource` keeps its Kotlin constants — reached for a different reason than the one C
was offered for.

> **Half of the instruction that opened this ticket is therefore not done, deliberately.** The owner
> asked to *"remove all of our hardcoded stub"*; the hardcoded stub stays. What changes is which
> data source **the app** uses. Recorded here rather than quietly narrowed, because a later reader
> will otherwise find the stub still in place and assume the ticket failed.

**This strengthens the case for keeping `stub()` public.** If the served fixtures live on one
machine, it is the only path anyone else — a second developer, the owner on another Mac, a fresh
clone — can run the app from at all. It stops being a convenience and becomes the shareable one.

> **A fact the decision should be weighed against, not an objection to it:** today's fixture data is
> **already public**. `StubRemoteDataSource.kt` is committed to `DNLibrary` and
> `docs/contracts/*.json` to the umbrella, both on GitHub. Nothing in them is sensitive — the bank
> numbers are dummy by the owner's own instruction — so *keeping the Mockoon copy private changes
> what happens next, not what is already out*. If real account numbers are going into that file,
> keeping it off every repository is exactly right and this ticket must never commit it.

## App Transport Security — the key that was not added

The plan named `NSAllowsLocalNetworking` on Development. **It was not added, deliberately.**

ATS does not apply to a host that is not a fully qualified domain name, and `localhost` is not one —
which is why simulators reach `http://localhost:3000` every day without an exception. Adding the key
would declare something the app does not use, and `ios/DapurNaura/CLAUDE.md` is explicit that the app
declares exactly one permission and that *"declaring a permission the app does not use asks users for
something it never needs, and App Review notices."*

**If the owner's device check shows the connection blocked, the key goes in — and it is more
expensive than it looks.** `NSAppTransportSecurity` is a *dictionary*, and `INFOPLIST_KEY_…` build
settings cannot express one, so it cannot live beside DN-039's orientation keys or DN-046's camera
description. It would have to go in `DapurNaura/Info.plist`, which is shared by all four
configurations — so "Development only" would need a per-variant plist or a substituted value, and
neither exists today. **Worth knowing before anyone assumes it is a one-line addition.**

## Verifying this before the library is published

**The app compiles against the published `0.9.0`, but will not run against it.** The Swift change
uses only API that `0.9.0` already has — which is why `xcodebuild` reports success — but `0.9.0`'s
`require()` still rejects `http://`, so launching would fail at the composition root.

To see it working before release, wire the local package Xcode-side (the steps `publish-spm.sh local`
prints), with Mockoon running on port 3001. **That wiring is never committed** — revert
`project.pbxproj` and `Package.resolved` before staging anything.

## A defect fixed in the Mockoon environment, 2026-09-12

Found while probing the running server against this ticket's own test plan, and fixed on the owner's
instruction. **It is recorded here because it is recorded nowhere else** — the environment file is on
the owner's Desktop and committed to no repository, so this ticket is its only change log.

**The `unknown id` → 404 responses on `/classes/:id` and `/recipes/:id` were unreachable.** Mockoon
falls back to the response flagged `default: true` when no rule matches, and on both routes that flag
sat on a **200**:

| Request | Was | Now |
|---|---|---|
| `GET /classes/99` | **200**, serving Jajanan Pasar's body | 404 |
| `GET /recipes/99` | **200**, serving a purchased class's recipe | 404 |

A mistyped id therefore served another record's data under a success status, and the app's
not-found path could not be exercised against Mockoon at all. The fix moves `default: true` onto the
404 in each route; both 200s keep their own matching rules, so nothing else changed.

**Verified after the fix** — unknown ids answer 404, and every route the app calls still answers as
the test plan requires: the three classes, the server-side `?category=` filter (`MINUMAN`, `BAKING`,
`COOKING` each returning one class), `403` on recipes `21-24` and `31-38`, `200` on `11-16`,
`/offline-classes` and `/payment-destinations`.

> **Mockoon serves from memory, so the file edit alone does not take effect** — the environment has
> to be reopened. Worse, editing anything in the Mockoon UI first writes the in-memory copy back over
> the file and reverts the fix. Anyone repeating this should reload before touching the UI.

**Two things this probing also established**, neither a defect and neither in scope here: Mockoon
checks no API key on any route, and the five route paths match `RemoteDataSource`'s five exactly
(`classes`, `classes/:id`, `recipes/:id`, `offline-classes`, `payment-destinations`).

## Comment cleanup, folded into this ticket

**Owner's instruction, 2026-09-12, translated:** *"Remove all the comments inside DNLibrary classes
and test. For the tests, remove only the comments that aren't really useful — the test function name
alone already describes the scenario/case, right?"*

**Owner's decision: it lands on this branch**, not a separate ticket. Recorded because the ticket
title says Mockoon and a reader of the diff will find ~180 deleted comment lines that Mockoon does
not explain.

### What the owner learned mid-decision, and why the scope narrowed

The instruction started as *remove all comments from main*. Checking the shipped
`DNLibrary.xcframework` header showed that **KDoc is not uniformly invisible** — Kotlin/Native
exports it into the Objective-C header, so Xcode Quick Help renders it for Swift callers. Two
screenshots from the owner settled which half:

| KDoc on | Count | In the ObjC header | Xcode Quick Help |
|---|---|---|---|
| Classes, enums, methods, top-level functions | 67 | attached to the declaration | **renders** |
| `data class` constructor properties | 18 | orphaned before `@end` | **blank** |

**Why the split exists.** The exporter emits properties **alphabetically sorted**, which destroys
the source order the parameter doc comments were tied to. Unable to match them back up, it dumps
them as a trailing block before `@end`, attached to no declaration. A doc comment binds to whatever
declaration follows it, so those 18 bind to nothing. This is a Kotlin/Native exporter limitation,
not a project misconfiguration.

**Owner's decision: strip the 77 Xcode ignores, keep the 67 it renders.**

### What was removed

| Scope | Removed | Kept |
|---|---|---|
| `commonMain` | 55 inline `//` lines, 18 orphaned property KDoc | **67 KDoc, all rewritten** — see below |
| `commonTest` | 9 section-divider blocks, 1 comment restating its own test name | every comment carrying a reason, a date or a ticket id |

### The 67 survivors were then rewritten, 2026-09-12

**Owner's instruction:** the KDoc should *"just explain what this Interface/Class is for"* — several
blocks never said what the thing was at all. `Ingredient` opened with *"[merk] is commercial advice,
not decoration"*; `RecipeStep` with *"[videoTimestampSeconds] points into the recipe's video"*; five
result interfaces carried one identical sentence about generics and none named the result it
represented; `PaymentRepository.toDNError` opened *"The third copy of this `when`"*.

All 67 are now a single line stating purpose. `commonMain` went from 2,140 lines to 1,616.

> **What left the code, and where it still lives.** The rewrite dropped design rationale that was
> load-bearing in a handful of places — **flagged, not lost**, because every one of these is recorded
> in `CLAUDE.md`, a merged ticket, or both:
>
> | Rule that left a KDoc | Still recorded in |
> |---|---|
> | `portions` and `loyang` must never be merged | platform `CLAUDE.md`, DN-020 |
> | A null `portions` means *no value*, never *locked* | DN-020, DN-021 |
> | `NEARLY_FULL` still takes bookings (owner's emphasis) | DN-035 |
> | `PaymentDestination` is per business, not per class or buyer | DN-047 |
> | `toWireValue` is exhaustive so a new category breaks the build | DN-024 |
> | The clock is a constructor parameter so the schedule is testable | DN-035 |
>
> If any of these should return to the source, the place to put them is a short second line — the
> owner's instruction was that the first line say what the type is for, which none of them did.

**Two `[ASSUMPTION]` runs in `commonMain` were kept deliberately** — `RemoteDataSource.kt` (the auth
header name) and `DNFormat.kt` (whether a user should read the word *"Cooking"*). These are not
explanations; they mark decisions the owner has not settled, and the platform rule is that an
`[ASSUMPTION]` is never quietly removed. That makes the main total 73 removed rather than 77.

**The test rule applied, in the owner's own terms:** a comment goes when the test name already says
it. The dividers — `Grouping`, `Failure`, `Helpers`, `Failure paths` — are navigation furniture the
names below already provide. What stayed explains *why* a specific value was chosen (`11 and 10 are
the pair that catches a > written as >=`), cites an owner decision with its date, or names the
real-world cost of the bug the test prevents. None of that is recoverable from a function name.

### Verified

- `./gradlew :sharedLogic:check` — **BUILD SUCCESSFUL**, tests executed on both platforms
- No functional comments were touched: no `ktlint-disable`, `@Suppress`, `TODO` or `FIXME` exists in
  `commonMain`, and every comment in the module is whole-line rather than trailing

### The same cleanup on the iOS flow components, 2026-09-12

**Owner's instruction:** remove the comments inside `Presentation/<Flow>/Components`, **not**
`Presentation/Components`. The boundary is the owner's and is the reason the shared components were
left alone — those are used by every flow, the eight in scope belong to one screen each.

| Scope | Files | Removed |
|---|---|---|
| `Auth/Login/Components`, and the seven under `Cookings/*/Components` | 17 | **186 explanatory comment lines** (`//` and `///`) |
| `Presentation/Components` and `Presentation/Components/Toast` | — | untouched, as instructed |

**The Xcode file headers were kept** — owner's decision when asked. All 72 Swift files in the app
carry one; stripping it from these 17 alone would have made them the only files in the app without
it. That is 102 of the 288 comment lines in scope, left in place.

**Verified:** `swiftlint lint --strict` reports 0 violations, and `xcodebuild … build` reports
`** BUILD SUCCEEDED **` on iPhone 16 Pro — the DN-034 rule that every iOS change is built before it
is offered for review.

### Domain types then gained their members, 2026-09-12

**Owner's observation**, looking at `CookingClassDetail` in Quick Help: the KDoc said what the type
was for and nothing about what was inside it. **Their instruction:** *"For enum and data class, just
inform the case or properties inside of it. Nothing more."*

**This is the only channel that can carry it.** Property-level KDoc is orphaned by the exporter and
never reaches Xcode — established earlier in this ticket. Putting the member list in the *type's* own
KDoc is therefore the one way property information can appear in Quick Help at all.

Sixteen public domain types in `domain/model/` gained one line, generated from the source rather than
typed, so the list cannot disagree with the declaration:

```
/**
 * A bank account a class can be paid into.
 *
 * Properties: bank, accountNumber, accountHolderName.
 */
```

**The `Success` / `Failure` result wrappers were left alone** — one obviously-named property each and
no KDoc today; a list there would be noise. Flagged to the owner rather than decided silently.

> **The owner was shown the staleness risk before choosing.** A member list is a second copy of the
> declaration, and a field added later leaves it silently wrong — the duplication this repository
> warns about everywhere else. It is accepted because Quick Help has no other route to the
> information. **Anyone adding a property to a `domain/model/` type updates the KDoc line with it.**

> **Two files were corrupted mid-change and repaired.** The first script's doc-body pattern spanned
> past a closing `*/`, swallowing declarations into comments wherever a KDoc was followed by
> something other than a `data class` or `enum class` — `OfflineClass.kt` (a `const val`) and
> `DNError.kt` (a `sealed interface` and two `data object`s). The compiler caught the first; the
> second was found by reading the files rather than trusting that one error meant one broken file.
> Both repaired by hand, and all twenty public declarations verified present afterwards.

### The rule was written into the context, not just applied once

**Owner's instruction, 2026-09-12:** *"This rule must be applied to the context."* — the comment
standard is to govern code written from now on, not only the files this ticket passed through. It
therefore lives in the three `CLAUDE.md` files that load into every session:

| File | What it carries |
|---|---|
| `CLAUDE.md` (umbrella) | The principle: a doc comment says what the thing is for in one line; reasoning lives in the ticket; the two narrow exceptions |
| `DNLibrary/CLAUDE.md` §7 | The Kotlin rule, plus **why KDoc is worth writing at all** — it renders in Xcode Quick Help for types, enums, methods and top-level functions, and is silently dropped on `data class` constructor properties |
| `ios/DapurNaura/CLAUDE.md` | The Swift rule, the kept Xcode headers, and why `Presentation/Components/` was left alone |

**The Quick Help behaviour is recorded deliberately.** It is the fact that decided which comments
were worth keeping, it is not discoverable from the Kotlin source, and without it the next person to
read §7 would take "one line" as a style preference rather than a consequence.

### The documentation sweep, second pass (DN-042 method)

The first sweep reported nine falsified documents. **It had missed two**, both found on this pass by
enumerating and then *reading* rather than grepping — which is precisely the failure DN-042 exists to
prevent, repeated by the ticket that cites it.

| Document | What was false | Now |
|---|---|---|
| `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` §9 | *"HTTPS only. Reject an `http://` base URL at config time."* — the rule this ticket's central change broke | **Restored unchanged.** The change that falsified it was reverted, so the rule is true again exactly as written |
| `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §3 | Granted the comment exception to *"a feature's own `Components/` folder"* — the exact folders the owner had stripped | Narrowed to `Presentation/Components/` alone, with DN-044's original wording struck rather than deleted |

`docs/AGENT-PLAYBOOK.md` was also corrected: *"match the surrounding comment density"* now points at
the new rule, since the surrounding density is close to zero in both codebases and the old phrasing
would license writing prose back in.

**The first sweep's miss is worth naming.** `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` had never been
opened in this ticket — it was counted in the enumeration and then skipped, because `git status`
showed it unmodified and that was mistaken for "unaffected". A document is affected by what the
ticket *changed*, not by whether something already edited it.

**One document was read and deliberately not fixed here.** `ios/SPMDNLibrary/README.md` is badly
stale — it claims the package has no tags and does not resolve, while five tags and five releases
exist, and its install snippet names `1.0.0`, the version reserved for the App Store release.

> **It was filed as DN-051, then the ticket was deleted on the owner's decision, 2026-09-12.** The
> reasoning is worth keeping: the ticket ran to 63 lines to describe a README correction, and the
> real cost was never the edit but the branch, commit and pull request it would need in a fourth
> repository. The failure mode is also loud rather than silent — a copied `from: "1.0.0"` fails at
> resolve time and ships nothing broken — and the repository, though public, has no stars and no
> forks.
>
> **The fix has a natural home instead:** a publish already commits to that repository to rewrite
> `Package.swift`, so the README is corrected in that same commit. Recorded in the platform
> `CLAUDE.md` under *Publishing the iOS binary*, which is where whoever runs the next release is
> already reading.

### The rules were finalised as standing instructions, 2026-09-12

The owner restated the comment rules as guidance for **every future agent**, not just this ticket,
and corrected one thing in the process.

**KDoc has no place in test code.** Owner's words: *"Why would you add KDoc into TestCase? TestCase
shouldn't be imported, it should stay within the project, not exported into the library."* This is
right, and it is the same fact the whole rule rests on — KDoc is worth writing in `commonMain`
*because* it is exported into the ObjC header and rendered in Xcode. `commonTest` is exported into
nothing, so a KDoc there reaches nobody a `//` comment would not. **The six that existed were
converted to `//`; the text was kept, only the marker changed.** `commonTest` now has zero KDoc.

**`// MARK:` stays in the iOS app.** Owner's decision when asked: it drives Xcode's jump bar, so it
is navigation rather than prose. It is the only thing left outside the header and
`Presentation/Components/` — seven lines across four files, which is what made the question worth
asking rather than assuming.

The final rules live in the three `CLAUDE.md` files, rewritten rather than appended to so there is
one statement of them and not a history to reconcile.

### Reversed: the library keeps its https-only guard, and Mockoon moved to TLS

**Owner's doubt, 2026-09-12, translated:** *"Honestly I'm still unsure about the decision to add
loopback code to NetworkManager. Mockoon is really for development purposes only. Later, when the
backend is ready, it will have several environments too — Dev, Alpha, Production endpoints. So
Mockoon is really only for internal developer testing before a ticket is PR'd, to create evidence."*

**The doubt was right and the change was reverted.** `DNNetworkManagerConfig` is back to
`require(baseUrl.startsWith("https://"))`, `isLoopback` is gone, and
`DNNetworkManagerConfigTest.kt` is **byte-identical to what shipped in `0.9.0`**. The test suite went
from 92 back to 85.

**The argument that settled it was lifetime, not security.** A loopback request genuinely never
reaches a network interface, and a release build misconfigured to `http://localhost` would simply
fail to connect — the reasoning written into the guard was sound. The problem was that a **permanent
widening of a published binary's contract** was serving a **temporary need that lives on one
laptop**, and by the owner's own roadmap that need ends the moment a real backend exists with https
Dev/Alpha/Production endpoints. The exception would then have zero consumers and still ship.

**What it had already cost before being reverted:** a widened public contract, seven tests asserting
the hole works, a §9 rewrite in `DNLibrary/docs/CODEBASE-ARCHITECTURE.md`, a ticket (DN-052) whose
only purpose was to undo it, and a release gate in the platform `CLAUDE.md`. All five are gone.

> **The asymmetry that made reverting obvious, and it only existed at that moment.** Nothing had been
> committed, so no published version ever carried the exception — `0.9.0` has no loopback code and
> neither will its successor. Reverting later would have meant publishing a version with the hole and
> then publishing another to remove it: **two public API movements to end up exactly where we
> started.**

**DN-052 was deleted, not closed.** It existed solely to undo this, and the thing it was to undo no
longer exists. The release gate it was named in came out of `CLAUDE.md` with it.

### Mockoon now serves HTTPS, and the cost sits on the developer's machine

Mockoon supports TLS natively — `tlsOptions` in the environment file, previously `enabled: false`.
The setup keeps every reason Mockoon exists (the server-side `?category=` filter and the 403 on an
unpurchased recipe, neither of which `stub()` truly exercises) **without the library changing at
all**:

| Step | What was done |
|---|---|
| Local CA + server cert | `openssl`, in `~/Desktop/DapurNaura-devcerts/` — **committed nowhere**, like the environment file itself |
| Certificate shape | `CN=localhost`, SAN `DNS:localhost, IP:127.0.0.1`, EKU `serverAuth`, **397 days** — inside Apple's limit for a trusted server certificate |
| Mockoon | `tlsOptions.enabled = true`, pointed at the cert, key and CA |
| Simulator trust | `xcrun simctl keychain <udid> add-root-cert` on **iPhone 17, 17 Pro and 17 Pro Max (iOS 26.3.1)** |
| App | `Development.xcconfig` → `https://localhost:3001`; the built `Info.plist` resolves it, verified |

**The certificate was proved before Mockoon was asked to use it** — chain verified against the CA,
cert and key modulus matched, and a live TLS handshake through a throwaway `openssl s_server`
succeeded with the CA and was rejected without it.

> **Mockoon serves from memory and must be reloaded** for the TLS switch to take effect, exactly as
> for the 404 fix above. Editing anything in its UI before reloading writes the in-memory copy back
> over the file and reverts both changes.

> **What did not change, and is worth stating.** `stub()` is still the path that needs nothing
> running, and is still the only one a second machine can use — the certificates are as local as the
> environment file. Alpha, Beta and Release still carry the RAWG placeholder.

## Public API contract

- **`DNNetworkManagerConfig` is unchanged** — the widening was reverted before anything was committed.
- `DNDataLayer.stub()` **stays**. Nothing is removed.
- **Version bump implied: PATCH** — no public symbol and no public behaviour changed. The library's
  only diff is comments: the KDoc rewrite and the member lists. *(Was MINOR while the loopback
  exception existed; it no longer does.)*

## Out of scope

- **Deleting `DNDataLayer.stub()`.** It is the no-server path and the tests' data source.
- **Pointing the tests at Mockoon.** Decided against above, with the reason.
- **Alpha, Beta and Release configurations.** They keep the RAWG placeholder and full ATS.
- **A physical device.** `localhost` is the simulator's host; a device needs the Mac's LAN address,
  which is a different setup and a different ticket if it is ever wanted.
- **Committing the Mockoon environment.** It lives on the owner's Desktop today; whether it moves
  into the umbrella beside the contracts it mirrors is a separate decision.
- **Android.**

## Test plan

Data layer, so unit tests are required (platform Definition of Done):

- ~~`DNNetworkManagerConfigTest` gains loopback cases.~~ **Not done — reversed.** The file is
  byte-identical to `0.9.0`, and the suite is back to 85 tests from 92.
- Every existing test keeps passing **with nothing running** — that is the point of keeping the stub.

What the owner checks on the running app, with **Mockoon reloaded so TLS is live** on port 3001:

| Check | Expected |
|---|---|
| Launch the Dev build with Mockoon **running** | The class list loads three classes from the server |
| The category chips | Each returns only its own class — served by Mockoon's rule, not filtered locally |
| Open *Makanan Kekinian* (id 1), then a recipe | Recipe opens; ingredients and steps are present |
| Open *Jajanan Pasar* (id 3), then a recipe row | Locked — the recipe endpoint answers **403** and the app shows its error state |
| The payment screen | Both accounts, from `/payment-destinations` |
| Launch with Mockoon **stopped** | Every screen shows its failure state with a retry — **not a crash** |
| Launch a Beta build | Still points at the RAWG placeholder; nothing about it changed |

## Done when

- [x] The open question above is answered by the owner — 2026-09-12, see *Answered*
- [x] The app constructs `DNDataLayer(config:)` and `DapurNauraAppConfig` has its first caller — known issue 4 in the iOS `CLAUDE.md` is resolved
- [x] **The https-only guard is untouched** — the loopback exception was reverted, and Mockoon serves TLS instead
- [x] **No ATS key was added** — see *App Transport Security*; it is not needed, and would not be a one-line change if it were
- [x] `./gradlew :sharedLogic:check` passes **with nothing running** — 85 tests on both platforms, the count `0.9.0` shipped
- [x] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034) on iPhone 17 Pro, iOS 26.3.1 — and the built `Info.plist` resolves `BaseURL` to `https://localhost:3001`, proven rather than assumed
- [x] `swiftlint lint --strict` reports 0 violations
- [x] The Mockoon environment's unreachable 404s fixed, and every route re-probed against the test plan
- [x] Comments stripped and the 67 surviving KDoc rewritten; the rule written into all three `CLAUDE.md` files
- [x] 186 explanatory comments removed from the seventeen `Presentation/<Flow>/Components/` files; `Presentation/Components/` untouched
- [x] Documentation sweep (DN-042), **two passes**. The first found nine documents falsified by one
      sentence — *the app runs on the stub*. The second found **two the first had missed**, both
      contradicting this ticket's own changes: `DNLibrary/docs/CODEBASE-ARCHITECTURE.md` §9
      (*"HTTPS only"*) and `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §3 (comments allowed in a
      feature's `Components/`). `docs/AGENT-PLAYBOOK.md` corrected too; **DN-051 filed** for a third
      that is stale but not this ticket's doing
- [x] Final gates green after every change: `:sharedLogic:check` — **85 tests, 10 classes, 0 skipped,
      0 failures** on both platforms, read from the result XML rather than trusted from the exit code
      — plus `swiftlint --strict` clean and `** BUILD SUCCEEDED **`. *(Was 92 while the loopback
      exception and its seven tests existed; the revert returned the suite to the count `0.9.0`
      shipped.)*
- [x] Diff reviewed by the owner, and **the app run on iPhone 17, iOS 26.3.1** against Mockoon over
      TLS — the owner confirmed it working, 2026-09-12
- [x] Committed — three commits, one per repository, staged explicitly; the local package
      wiring was reverted first and is absent from all three
- [x] PR opened — [DNLibrary#22](https://github.com/Fostahh/DNLibrary/pull/22) and
      [DapurNaura-iOS#27](https://github.com/Fostahh/DapurNaura-iOS/pull/27). **The umbrella takes
      no PR** — its last six merges are local `Merge branch … into development`, unlike the other two
- [x] PR merged — the owner confirmed both, 2026-09-12.
      [DNLibrary#22](https://github.com/Fostahh/DNLibrary/pull/22) at `8bd06d6`,
      [DapurNaura-iOS#27](https://github.com/Fostahh/DapurNaura-iOS/pull/27) at `a3a62df`.
      **The umbrella branch is merged locally by the owner** and takes no PR
- [ ] ~~Published and the app repinned~~ — **no longer required for this ticket.** The revert left the
      library with a comments-only diff, so nothing here depends on a release. The KDoc rewrite is
      still worth publishing eventually, because it is what makes Xcode Quick Help useful, but it is
      a **PATCH** on the owner's timing rather than a step of this ticket
