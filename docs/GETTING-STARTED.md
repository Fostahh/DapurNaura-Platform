# Getting started

Everything a newcomer needs to go from zero to a building workspace. Read this first.

---

## 1. What this project is

**Dapur Naura** is a cooking app, built to digitalise the paid cooking classes the owner's wife and
mother-in-law teach. Browse **cooking classes** (*kelas*), open one to see its **recipes**, open a
recipe for the ingredients (*bahan-bahan*), the step-by-step method, and a how-to video. Content is
Bahasa Indonesia. The audience is people learning to cook.

Classes are paid; a payment gateway (likely Midtrans) is planned but deliberately deferred.

The data layer is shared between iOS and Android via **Kotlin Multiplatform**. The UI is native
on each platform — SwiftUI on iOS, Jetpack Compose on Android.

> **Almost none of this exists yet.** The data layer has no domain model and still carries
> scaffolding awaiting deletion (DN-004). The iOS app is a SwiftUI shell with four build variants
> and **no data layer at all**. Android has not been created. Expect to build, not to read.

---

## 2. Set up the workspace

```sh
git clone https://github.com/Fostahh/DapurNaura-Platform.git
cd DapurNaura-Platform
./bootstrap.sh
```

`bootstrap.sh` clones the project repositories into place. It is safe to re-run.

---

## 3. How the workspace is arranged

**This is not a monorepo.** It is an umbrella folder. The umbrella repo tracks `docs/` and
workspace config only; each project below is an independent git repository with its own history,
its own remote, and its own release cadence.

```
DapurNaura-Platform/          ← umbrella repo — tracks docs/ ONLY
├── docs/                     ← requirements, tickets, architecture. Tracked here.
├── bootstrap.sh
│
├── DNLibrary/                ← repo: github.com/Fostahh/DNLibrary
│                                KMP data layer. Ships as XCFramework (iOS) + AAR (Android).
├── ios/
│   ├── DapurNaura/           ← repo (local only, no remote yet). SwiftUI app.
│   ├── SPMDNLibrary/         ← repo: github.com/Fostahh/SPMDNLibrary
│   │                            Manifest-only Swift package, semver tags. iOS distribution.
│   └── DNLibraryLocal/       ← build artifact, NOT a repo. Never committed.
└── android/                  ← native Android app. Not created yet.
```

### Why the projects are separate repos

DNLibrary is a library consumed by two independent apps, so it needs its own release cadence.

`SPMDNLibrary` in particular **cannot** be folded into another repo: Swift Package Manager
resolves a git-URL dependency by cloning the repo and reading `Package.swift` **at the repo
root** — there is no subdirectory support. It also needs its own tag namespace so library
versions don't collide with app versions.

### The cost you should know about

A ticket lives in this umbrella repo; the commits that satisfy it live in the project repos.
Nothing links them except the ticket id in the commit message. **So every commit must reference
its ticket** (`DN-004: …`). That id is the only thread tying work together across repos, and the
reviewer depends on it.

---

## 4. Build and test

### Data layer (DNLibrary)

Gradle commands run from `DNLibrary/` — that is the Gradle root, where `gradlew` lives:

```sh
cd DNLibrary
./gradlew :sharedLogic:check                # all checks + tests, both platforms
./gradlew :sharedLogic:testAndroidHostTest  # Android host tests (Robolectric)
./gradlew :sharedLogic:iosSimulatorArm64Test
./gradlew :sharedLogic:assemble             # Android library + iOS XCFramework
```

### iOS app (DapurNaura)

Opened and run from `ios/DapurNaura` in Xcode. **Gradle alone cannot build it.**

Schemes are **per build variant** — there is no scheme called plain `DapurNaura`:

```sh
cd ios/DapurNaura
xcodebuild -list -project DapurNaura.xcodeproj      # "DapurNaura Dev" | Alpha | Beta | Release
```

> **The app currently has no DNLibrary dependency.** It was removed, and the app builds standalone.
> Everything in the rest of this section describes how the dependency works **once a ticket
> reinstates it** — it is inert today. Do not add it speculatively.

The app gets DNLibrary as a **binary**, one of two ways:

| | Source | Committed? |
|---|---|---|
| **Remote** | an `SPMDNLibrary` semver tag | ✅ always this |
| **Local** | `ios/DNLibraryLocal` — a build artifact in no repo | ❌ **never** |

On a released branch the remote version resolves and the app builds. During development you point
Xcode at the local package instead, generating it with:

```sh
cd DNLibrary
./scripts/publish-spm.sh          # interactive; choose `local` mode
```

**That local wiring is never committed.** Switching to it dirties both `project.pbxproj` and
`Package.resolved` — revert both before committing, and never `git add -A` in that repo.

One consequence that looks like a bug but isn't: while a ticket is in flight, the *committed* app
state does not compile, because the Swift code calls library APIs that aren't published yet. It
becomes valid again once the library is released and a final commit bumps the version.

---

## 5. How work happens: Document Driven Development

There is no Jira. Requirements and tickets are markdown in this repo.

```
docs/requirements/   ← you write these.   INPUT.  Immutable.
docs/tickets/        ← the agent writes these.  OUTPUT.
docs/contracts/      ← the agreed JSON wire shape. Approved, but not frozen like a requirement.
```

The loop:

1. A requirement document lands in [`requirements/`](requirements/) — **or** a problem is noticed
   in the code or tooling. Those are the two ways work starts.
2. An agent translates it into one or more tickets in [`tickets/`](tickets/), one file per ticket:
   - **product** — from a requirement, with a `source:` field pointing back at it
   - **technical** — from an observation, with a `## Rationale` section instead, because no
     requirement document exists for work like "make the HTTP engine testable"
3. The agent implements it — data layer in `DNLibrary/`, UI in `ios/DapurNaura/`.
4. The agent writes **and runs** unit tests. Tests are required for the **data layer**; UI is
   verified manually for now.
5. The agent builds the library into the local package and **runs the app against it**, so the
   library change and the app change are proven together before anything is committed.
6. The agent stops. A human verifies the running app and reviews the diff in a Git UI
   (Fork / SourceTree) — **nothing is committed at this point**.
7. On approval the human triggers commit → push → PR. Once merged, the human triggers the release,
   and the app is then bumped from the local package to the published version.

**Requirement documents are never edited to match what was built.** Corrections belong in the
ticket.

### What the agent decides for itself

Briefly, because it matters when you hand work to one: it may read anything, write tickets, create
the ticket branch, write code and tests, and run the local build freely. It **stops and asks**
before committing, pushing, opening a PR, merging, publishing a release, or marking a ticket done.
It never edits a requirement document. Full boundary in
[ARCHITECTURE-AND-WORKFLOW.md §5](ARCHITECTURE-AND-WORKFLOW.md).

---

## 6. Versioning, briefly

Three numbers, deliberately unrelated:

- **Library** (`SPMDNLibrary` tags) — plain semver, driven by API change. `0.x` while unstable.
- **App** (`MARKETING_VERSION`) — the product number users see. Independent of the library.
- **Build** (`CURRENT_PROJECT_VERSION`) — just has to increase.

What changed in a version goes in the **release notes**, not in the number.

---

## 7. Where to look next

| I want to… | Read |
|---|---|
| Work (or point an agent at work) to the house standard | [AGENT-PLAYBOOK.md](AGENT-PLAYBOOK.md) |
| Understand the architecture and the full workflow | [ARCHITECTURE-AND-WORKFLOW.md](ARCHITECTURE-AND-WORKFLOW.md) |
| See what work is open, or write a ticket | [tickets/README.md](tickets/README.md) |
| See the agreed JSON wire shape | [contracts/README.md](contracts/README.md) |
| Write a new requirement | [requirements/README.md](requirements/README.md) |
| Work on the data layer | `DNLibrary/CLAUDE.md` |
| Work on the iOS app | `ios/DapurNaura/CLAUDE.md` |
