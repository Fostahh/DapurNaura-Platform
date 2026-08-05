# Getting started

Everything a newcomer needs to go from zero to a building workspace. Read this first.

---

## 1. What this project is

**Dapur Naura** is a cooking app — browse recipe categories (Pastry, Jajanan, …), open a
category to see its recipes, open a recipe to get the ingredients, the step-by-step method, and
a how-to video. The audience is people learning to cook.

The data layer is shared between iOS and Android via **Kotlin Multiplatform**. The UI is native
on each platform — SwiftUI on iOS, Jetpack Compose on Android.

> **Note:** the data layer currently talks to the RAWG *video games* API. That is proof-of-concept
> scaffolding to prove the KMP pipeline works end to end, not the real domain. It will be replaced.

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
./gradlew :sharedLogic:testDebugUnitTest    # Android host tests
./gradlew :sharedLogic:iosSimulatorArm64Test
./gradlew :sharedLogic:assemble             # Android library + iOS XCFramework
```

### iOS app (DapurNaura)

Opened and run from `ios/DapurNaura` in Xcode. **Gradle alone cannot build it.**

During development the app builds against a locally assembled framework in `ios/DNLibraryLocal`,
which is a build artifact committed nowhere. Generate it before building the app:

```sh
cd DNLibrary
./scripts/publish-spm.sh          # interactive; choose `local` mode
```

---

## 5. How work happens: Document Driven Development

There is no Jira. Requirements and tickets are markdown in this repo.

```
docs/requirements/   ← you write these.   INPUT.  Immutable.
docs/tickets/        ← the agent writes these.  OUTPUT.
```

The loop:

1. A requirement document lands in [`requirements/`](requirements/).
2. An agent translates it into one or more tickets in [`tickets/`](tickets/), one file per ticket,
   each with a `source:` field pointing back at the requirement.
3. The agent implements it — data layer in `DNLibrary/`, UI in `ios/DapurNaura/`.
4. The agent writes **and runs** unit tests. Tests are required for the **data layer**; UI is
   verified manually for now.
5. The agent stops. A human reviews the diff in a Git UI (Fork / SourceTree).

**Requirement documents are never edited to match what was built.** Corrections belong in the
ticket. See [ARCHITECTURE-AND-WORKFLOW.md](ARCHITECTURE-AND-WORKFLOW.md) for the full rationale,
the ticket template, and the release flow.

---

## 6. Where to look next

| I want to… | Read |
|---|---|
| Understand the architecture and the full workflow | [ARCHITECTURE-AND-WORKFLOW.md](ARCHITECTURE-AND-WORKFLOW.md) |
| See what work is open | [tickets/README.md](tickets/README.md) |
| Write a new requirement | [requirements/README.md](requirements/README.md) |
| Work on the data layer | `DNLibrary/CLAUDE.md` |
| Work on the iOS app | `ios/DapurNaura/CLAUDE.md` |
