# Dapur Naura — Architecture & Workflow

**Status:** discussion summary, 2026-08-05. Nothing here has been implemented yet.

This captures the target architecture and the Document Driven Development workflow for the
Dapur Naura platform (KMP data layer + iOS app + future Android app). Items are tagged
**[DECIDED]**, **[PROPOSED]** (recommendation, not yet accepted), or **[OPEN]** (needs a call).

---

## 1. Goal

Build **DNLibrary** as a Kotlin Multiplatform library that ships the entire data layer to both
platforms:

- **iOS** — XCFramework, wrapped in a Swift package (`SPMDNLibrary`) with semver tags.
- **Android** — AAR, consumed by a native Android app built later.

The iOS app (**DapurNaura**) is currently a proof-of-concept with no real UI design. Focus for
now is the **data layer in DNLibrary**, not the UI.

---

## 2. The four moving pieces (verified current state)

| Piece | Location | Git | Role |
|---|---|---|---|
| **DNLibrary** | `~/Desktop/AndroidStudioProjects/DNLibrary` | repo, `master` | KMP source. One `sharedLogic` module → XCFramework + Android library |
| **SPMDNLibrary** | `~/Desktop/AndroidStudioProjects/SPMDNLibrary` | repo, tags `1.0.0`–`1.4.0` | Manifest-only Swift package. `Package.swift` points at a GitHub release zip + checksum |
| **DapurNaura** | `~/Desktop/XcodeProjects/DapurNaura` | repo | SwiftUI POC app, consumes `import DNLibrary` |
| **DNLibraryLocal** | `~/Desktop/XcodeProjects/DNLibraryLocal` | **not a repo** | Generated build artifact — a local SPM package for pre-release testing |

### DNLibrary today

Package `id.dn.fostah.dnlibrary.datasource.*`:

- `remote/network/NetworkManager.kt` — `DNNetworkManager`, a singleton (`initialize` / `getInstance`)
  wrapping a Ktor `HttpClient` with `ContentNegotiation` + kotlinx JSON.
- `remote/RemoteDataSource.kt` — `IRemoteDataSource` / `RemoteDataSource`, suspend functions
  against the RAWG API.
- `remote/network/responses/VideoGameResponse.kt` — `@Serializable` DTOs, all fields nullable.
- `local/PreferenceStorage.kt` — `expect class`, DataStore on Android / `NSUserDefaults` on iOS.
- `local/SecureStorage.kt` — `expect class`, DataStore on Android / Keychain on iOS.

Build: static XCFramework (`iosArm64`, `iosSimulatorArm64`) + Android library, with **SKIE** for
better generated Swift APIs. `commonTest` is wired up but **empty — there are zero tests**.

### The release pipeline (`scripts/publish-spm.sh`)

Gradle only assembles the XCFramework; the script does everything else. Two modes:

- **`local`** — assemble → copy `.xcframework` to `DNLibraryLocal` → write a path-based
  `Package.swift`. Xcode rewiring is manual and must be undone afterward.
- **`publish`** — release build → `ditto` zip → `swift package compute-checksum` → rewrite
  SPMDNLibrary's `Package.swift` with the release-asset URL → commit, tag, push,
  `gh release create`. Dry-run is the default; preflight checks the tree is clean, the tag is
  free, and origin really is SPMDNLibrary.

---

## 3. Workflow: Document Driven Development

**[DECIDED]** No Jira. Requirements and tickets live in the repo as markdown.

```
docs/requirements/   ← human writes. Input. IMMUTABLE.
docs/tickets/        ← agent writes. Output. Mutable.
```

### The loop

1. Human drops a user-requirement document into `docs/requirements/`.
2. Agent consumes it and writes one or more tickets into `docs/tickets/`, with technical detail.
3. Agent implements: KMP data layer changes for new API calls / data features, plus UI changes
   where the requirement calls for them.
4. Agent writes **and runs** unit tests.
5. Human reviews the diff manually in a Git UI (Fork / SourceTree).

**Requirements are never edited to match what was built.** That would destroy the audit trail.
Corrections go into the ticket, not the requirement.

### Ticket format — **[DECIDED]** one file per ticket

Chosen over a single `TODO.md` because: status churn stays out of code diffs during Fork review;
the agent reads only the ticket it needs instead of an ever-growing list; and concurrent ticket
updates can't clobber each other.

```markdown
---
id: DN-004
title: Menu catalogue repository
status: todo | in-progress | in-review | done
source: docs/requirements/2026-08-menu-catalogue.md
branch: ticket/DN-004-menu-catalogue
---
## Requirement (traced)
> quoted lines from the source doc

## Technical approach
## Public API contract     ← what Swift / Kotlin callers actually see
## Test plan
## Done when
```

`source:` is the traceability link — "why does this code exist" is always one hop away.
`docs/tickets/README.md` holds a regenerated at-a-glance index (derived, harmless if stale).

### Definition of Done

**[DECIDED]** A requirement is COMPLETE when the agent has implemented the code — data layer
included — and has created and run unit tests. Human review in a Git UI follows.

**[PROPOSED]** additions, so the bar isn't ambiguous:

- **Which test task counts.** `./gradlew :sharedLogic:check`, or name both
  `testDebugUnitTest` and `iosSimulatorArm64Test` explicitly.
- **Branch, commit, stop.** Agent works on `ticket/DN-XXX-slug`, commits, and never merges.
  The human merges after review.
- **The failure path.** A rejected review appends a `## Review feedback` section to the ticket
  and flips status back to `in-progress`. Otherwise rejections exist only in the reviewer's head.

---

## 4. Repository layout — **[PROPOSED]**

### Hard constraint

**SPMDNLibrary cannot become a subdirectory of a larger repo.** SPM resolves a git-URL dependency
by cloning the repo and reading `Package.swift` **at the repo root** — there is no subdirectory
support for remote package dependencies. It also needs its own tag namespace so `1.4.0` doesn't
collide with app tags. It stays a standalone repo.

`DNLibraryLocal` is a build artifact, not a project, and shouldn't sit beside source projects.

### Proposed shape: true monorepo

Putting `docs/requirements` at the top of an umbrella folder only works if that folder is a git
repo — otherwise requirements and tickets aren't versioned alongside the code they produced, and
the ticket→commit link disappears from Fork.

```
DapurNaura-Platform/                 ← one git repo
├── docs/
│   ├── requirements/
│   └── tickets/
├── DNLibrary/                       ← KMP data layer
├── ios/DapurNaura/                  ← Xcode app
├── android/                         ← later
└── scripts/publish-spm.sh

SPMDNLibrary/                        ← separate repo, next door
```

**Why:**

- One ticket = one branch = one diff, spanning library and app. The DoD already spans both;
  separate repos give two unlinked commits with nothing tying them together.
- **The local SPM path becomes permanent.** Today `publish-spm.sh local` forces you to rip out
  the remote dependency in Xcode, add a local one, then remember to switch back. With a fixed
  relative path this stops being a manual dance, and SPMDNLibrary becomes purely a distribution
  channel cut at release time rather than something the app fights with daily.
- Requirements, tickets, and code share one history.

**Cost:** use `git subtree add` rather than moving folders, or existing histories are lost. Paths
in `settings.gradle.kts` change, and two things in the script follow the layout — `publish_local`
hardcodes `$ios_project_dir/../DNLibraryLocal`, and `detect_spm_repo` scans `dirname(REPO_ROOT)`
for a sibling repo.

---

## 5. Architecture recommendations — **[PROPOSED]**

### 5.1 Testability is a blocker, not a nice-to-have

No meaningful unit test can be written against the current network layer:

- `DNNetworkManager` constructs `HttpClient { }` in the class body with no engine parameter, so
  it always picks the platform default. **There is no seam for Ktor's `MockEngine`.**
- The constructor is private and `initialize()` silently returns the *existing* instance if one
  is set — so tests can't get a fresh instance, and test #2 inherits test #1's config.
- `RemoteDataSource` depends on the concrete `DNNetworkManager`, not an abstraction.

Since the DoD requires unit tests, **the first ticket must make this injectable** or every
test-bearing ticket after it is blocked.

### 5.2 Don't publish DTOs as the public API

`VideoGameResponse` — a wire DTO with every field nullable — is currently the public API of the
XCFramework. `ContentView` imports it directly, which is why the app is full of `?? "NIL"`.

For a binary-distributed library this is the wrong contract: an upstream JSON field rename breaks
Swift compilation, and consumers null-check fields the server always sends.

**Target:** DTOs internal, domain models public, mappers between them.

### 5.3 Typed errors

`RemoteDataSource` rethrows a generic `Exception`, so Swift receives an untyped `KotlinException`
carrying a string. A sealed error type would give exhaustive `switch` in Swift with no default
case — this is the single highest-leverage thing SKIE offers, and it's unused today.

### 5.4 Smaller shape issues

- `baseUrl` is actually a *full endpoint* (`.../api/games`) concatenated with `?key=`. The second
  endpoint added will break that shape.
- `expect class PreferenceStorage` has different constructors per platform (Android needs
  `Context`, iOS doesn't), so **commonMain can never construct one**. Any repository in commonMain
  must take it as a constructor parameter injected from the platform edge. This decides the DI
  shape whether or not it's planned.

---

## 6. Known drift (observed, intentionally NOT fixed)

Recorded so it isn't rediscovered later. The human explicitly deferred all of this.

1. **DapurNaura is wired to the local package, not the remote.** `project.pbxproj` contains only
   `XCLocalSwiftPackageReference "../DNLibraryLocal"`; there is no `Package.resolved`. The remote
   reference was removed for local testing and never restored.
2. **Three `DNLibrary` product dependencies on the app target** (`6297C70E`, `62415D6E`,
   `6215B9EB`) and three matching Frameworks entries — two are orphans whose package references
   no longer exist. This is the likely cause of past "Missing package product" errors; restarting
   Xcode masked it rather than fixed it.
3. **DapurNaura's `CLAUDE.md` claims the package tracks `master`.** It doesn't — SPMDNLibrary is
   tag-versioned.
4. **DNLibrary's `CLAUDE.md` predates the local data layer** — no mention of `PreferenceStorage`
   or `SecureStorage`.
5. **The RAWG API key is hardcoded and committed** in `DapurNauraApp.swift`.
6. **Zero tests.** `commonTest` is declared in `sharedLogic/build.gradle.kts` but empty.
7. **No link between a DNLibrary commit and an SPM tag.** Two repos, two histories; given the
   `1.4.0` zip there's no recorded path back to the source commit.

---

## 7. Open questions — **[OPEN]**

1. **Monorepo accepted?** It requires `git subtree` to preserve the three existing histories.
2. **Is DapurNaura the only intended consumer of SPMDNLibrary?** If so, the versioned package repo
   is ceremony — it earns its keep with a second consumer or a need for reproducible pinned
   releases. A native Android app consuming the AAR is a separate distribution story.
3. **Android timing.** The KMP module already builds an Android library target. Must tickets land
   `androidMain` actuals at the same time, or is iOS-first with Android deliberately deferred
   acceptable?
4. **Does DoD extend to release?** Ticket ends at "merged into DNLibrary", or at "SPM tag cut and
   DapurNaura building against it"?

---

## 8. Recommended first moves

1. Commit to the repository layout (§4) — everything else depends on where `docs/` lives.
2. Make ticket #1 **"testability + public API shape"**: injectable HTTP engine, domain models
   instead of DTOs, typed errors. Every feature ticket after it gets cheaper, and it avoids
   publishing a binary API that has to be broken later.
