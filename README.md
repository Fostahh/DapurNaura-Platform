# Dapur Naura — platform workspace

**Dapur Naura** is a cooking app, built to digitalise the paid cooking classes the owner's wife and
mother-in-law teach. Browse **cooking classes** (*kelas*), open one to see its **recipes**, open a
recipe for the ingredients (*bahan-bahan*), the step-by-step method and a how-to video.

Content is Bahasa Indonesia; the audience is people learning to cook. There is no English
localisation and none is planned.

The data layer is shared between iOS and Android via **Kotlin Multiplatform**. The UI is native on
each platform — SwiftUI on iOS, Jetpack Compose on Android.

Classes are paid. A payment gateway (likely Midtrans) is planned but deliberately deferred; because
a cooking class is a real-world service rather than digital content consumed in-app, App Store
Guideline 3.1.1 does not force In-App Purchase.

> **Source of truth.** For *what was asked for*, `docs/requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

## Where the project actually is

The app runs against **stub data** and covers the domain end to end: login (DN-040), the Kelas
Online / Kelas Offline choice it opens onto (DN-033), the class list with its category filter
(DN-009, DN-025), the class detail (DN-012), the recipe screen the product actually sells (DN-021)
and the offline class schedule (DN-036).

**What is missing is everything behind them.** There is no backend, no payment path of any kind, and
**no signed-in user — the login screen checks nothing.** Any email and any password get in; no
credential is verified, no session is kept, and nothing survives a relaunch. Android has not been
created.

*The list above names tickets rather than a count, deliberately — a number here goes stale on the
next merge and nothing forces anyone to notice. For current state, read
[`docs/tickets/README.md`](docs/tickets/README.md).*

Expect to build, not to read.

## Getting started

```sh
git clone https://github.com/Fostahh/DapurNaura-Platform.git
cd DapurNaura-Platform
./bootstrap.sh
```

`bootstrap.sh` clones the project repositories into place. It is safe to re-run.

Then, to build the data layer and run its tests:

```sh
cd DNLibrary
./gradlew :sharedLogic:check
```

To run the app, open `ios/DapurNaura` in Xcode. Two things are needed first, and both are documented
in [`ios/DapurNaura/README.md`](ios/DapurNaura/README.md): a hand-created
`DapurNaura/Config/Secrets.xcconfig`, and a local build of DNLibrary produced by
`DNLibrary/scripts/publish-spm.sh local`.

## How the workspace is arranged

**This is not a monorepo.** It is an umbrella folder. The umbrella repository tracks `docs/` and
workspace config **only**; everything else is git-ignored here. Each project below is an independent
repository with its own history, remote and release cadence.

```
DapurNaura-Platform/          umbrella repo — tracks docs/ + config ONLY
├── docs/                     requirements, tickets, contracts, workflow
├── bootstrap.sh
│
├── DNLibrary/                repo: github.com/Fostahh/DNLibrary
│                             KMP data layer. Ships as XCFramework (iOS) + AAR (Android).
├── ios/
│   ├── DapurNaura/           repo: github.com/Fostahh/DapurNaura-iOS — the SwiftUI app
│   ├── SPMDNLibrary/         repo: github.com/Fostahh/SPMDNLibrary
│   │                         Manifest-only Swift package, semver tags. iOS distribution channel.
│   └── DNLibraryLocal/       build artifact, NOT a repo. Never committed anywhere.
└── android/                  native Android app. Not created yet.
```

**Why they are separate repositories.** DNLibrary is consumed by two independent apps, so it needs
its own release cadence. `SPMDNLibrary` in particular *cannot* be folded in: Swift Package Manager
resolves a git-URL dependency by cloning the repository and reading `Package.swift` at its **root** —
there is no subdirectory support — and it needs its own tag namespace so library versions do not
collide with app versions.

**The cost you should know about.** A ticket lives in this umbrella repo; the commits satisfying it
live in the project repos, and **nothing links them except the ticket id in the commit message**.
Every commit must therefore reference its ticket (`DN-004: …`). That id is the only thread tying
work together across repositories, and review depends on it.

## How work happens

There is no Jira. Requirements and tickets are markdown in this repository.

```
docs/requirements/   you write these.        INPUT.  Immutable once approved.
docs/tickets/        the agent writes these. OUTPUT. One file per ticket.
docs/contracts/      the agreed JSON wire shape (v1).
```

The loop:

0. **Before anything else**, the agent restates what it understood and waits for you to confirm —
   naming its assumptions, or saying there are none. Ask in Bahasa Indonesia or English; it replies
   in the language you used and writes the repository in English either way. It never translates the
   app's own content, which stays Indonesian.
1. A requirement document lands in `docs/requirements/` — **or** a problem is noticed in the code.
   Those are the two ways work starts.
2. It becomes one or more tickets in `docs/tickets/`:
   - **product** — from a requirement, with a `source:` pointing back at it
   - **technical** — from an observation, with a `## Rationale` instead. Nobody writes a requirement
     asking for a testable HTTP engine, so without this type such work cannot be ticketed at all.
3. Implementation: data layer in `DNLibrary/`, UI in `ios/DapurNaura/`.
4. Tests are written **and run**. Required for the data layer; UI is verified manually for now.
5. The library is built into the local package and the app runs against it, so both halves are
   proven together before anything is committed.
6. The agent stops. **You verify the running app and review the diff — nothing is committed yet.**
7. On approval you trigger commit → push → PR. After the merge you trigger the release, and the app
   is then bumped from the local package to the published version.

**Requirement documents are never edited to match what was built.** Corrections belong in the ticket.

**What the agent decides for itself:** it may read anything, write tickets, create the ticket branch,
write code and tests, and run local builds freely. It **stops** before acting on a request you have
not confirmed, and before committing, pushing, opening a PR, merging, publishing a release, or
marking a ticket done. It never edits an approved requirement. The full boundary is in
[`docs/ARCHITECTURE-AND-WORKFLOW.md`](docs/ARCHITECTURE-AND-WORKFLOW.md) §5.

## Versioning

Three numbers, deliberately unrelated:

- **Library** — `SPMDNLibrary` tags, plain semver driven by API change
- **App** — `MARKETING_VERSION`, the product number users see
- **Build** — `CURRENT_PROJECT_VERSION`, which only has to increase

What changed in a version goes in the **release notes**, not in the number.

## Where to look next

| I want to… | Read |
| --- | --- |
| Work to the house standard, or point an agent at it | [`docs/AGENT-PLAYBOOK.md`](docs/AGENT-PLAYBOOK.md) |
| Understand the architecture and the full workflow | [`docs/ARCHITECTURE-AND-WORKFLOW.md`](docs/ARCHITECTURE-AND-WORKFLOW.md) |
| See what work is open, or write a ticket | [`docs/tickets/README.md`](docs/tickets/README.md) |
| See the agreed JSON wire shape | [`docs/contracts/README.md`](docs/contracts/README.md) |
| Write a new requirement | [`docs/requirements/README.md`](docs/requirements/README.md) |
| Work on the data layer | [`DNLibrary/README.md`](DNLibrary/README.md) → its `CLAUDE.md` |
| Work on the iOS app | [`ios/DapurNaura/README.md`](ios/DapurNaura/README.md) → its `CLAUDE.md` |
