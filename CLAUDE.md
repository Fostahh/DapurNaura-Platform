# CLAUDE.md

Guidance for Claude Code working in the Dapur Naura platform workspace.

Full rationale, ticket lifecycle and release flow: [`docs/ARCHITECTURE-AND-WORKFLOW.md`](docs/ARCHITECTURE-AND-WORKFLOW.md).
Onboarding: [`docs/GETTING-STARTED.md`](docs/GETTING-STARTED.md).

## What this app is

A cooking app for **Dapur Naura**, built to help the owner's wife and mother-in-law digitalise the
paid cooking classes they teach. Audience is people learning to cook. Content is Bahasa Indonesia;
there is no English localisation and none is planned yet.

Browse **cooking classes** (*kelas* — e.g. "Makanan Kekinian") → open one to see its **recipes** →
open a recipe for its ingredients (*bahan-bahan*), the step-by-step method, and a how-to video.

`CookingClass` is the top-level entity; a class contains recipes. A `Recipe` carries id, name,
images, ingredients, steps (**structured objects, not one long string**), portions and loyang —
portions and loyang are separate concepts and must not be merged. `difficulty` and
`prepTimeMinutes` are deferred until the owner supplies them.

Classes are **paid**. A payment gateway (likely Midtrans) is planned but explicitly deferred —
"really really later". Because a cooking class is a real-world service rather than digital content
consumed in-app, App Store Guideline 3.1.1 does not force In-App Purchase.

> **Nothing of this domain is built yet.** The data layer has no domain model, and the iOS app is a
> SwiftUI shell with build variants and no data layer at all. Do not assume any of it exists.

## What this folder is

An umbrella workspace. **It is not a monorepo.** The projects below are independent git
repositories with their own histories, remotes and release cadence. The umbrella itself is a git
repo that tracks `docs/` and workspace config **only** — everything else is git-ignored here.

```
DapurNaura-Platform/          umbrella repo — tracks docs/ + config ONLY
  docs/
    requirements/             human-authored. INPUT. Never edit these.
    tickets/                  agent-authored. OUTPUT. One file per ticket.
    contracts/                approved JSON wire shape (v1) — source of truth for DTOs + backend.
  bootstrap.sh                clones the project repos into place
DNLibrary/                    git repo → github.com/Fostahh/DNLibrary
                              KMP data layer. Ships as XCFramework (iOS) + AAR (Android).
ios/DapurNaura/               git repo (local only, no remote yet). SwiftUI app.
ios/SPMDNLibrary/             git repo → github.com/Fostahh/SPMDNLibrary
                              Manifest-only Swift package, semver tags. iOS distribution channel.
ios/DNLibraryLocal/           build artifact, NOT a repo. Never committed anywhere.
android/                      native Android app (Compose + MVVM). Not created yet.
```

`DNLibrary/CLAUDE.md` and `ios/DapurNaura/CLAUDE.md` carry per-project detail. Read the relevant
one before working in that directory.

**Commits do not span projects.** A change touching both the data layer and the app produces one
commit in `DNLibrary/` and one in `ios/DapurNaura/`, with nothing linking them. **Reference the
ticket id in every commit message** (`DN-004: …`) — that id is the only thread tying work
together across repos, and the reviewer depends on it.

**`SPMDNLibrary` must stay its own repo.** Swift Package Manager resolves a git-URL dependency by
cloning the repo and reading `Package.swift` at the repo root — there is no subdirectory support.
It also needs its own tag namespace.

## Autonomy — what to do without asking, what to stop for

**Do without asking** — read anything; create and edit ticket files; **file a technical ticket at
`status: todo`** when you notice a problem; create the ticket branch; write code and tests on that
branch; run Gradle tasks; run `publish-spm.sh` in `local` mode; move a ticket between `todo` →
`in-progress` → `in-review`.

**Stop and wait for the human** — **starting** a technical ticket you filed yourself (filing is
autonomous, scheduling is not); committing; pushing; opening a PR; merging anything; running
`publish-spm.sh` in `publish` mode; any tag or GitHub-release operation; marking a ticket `done`.

**Never** — edit a requirement document once it is `status: approved`; force-push; delete a tag or
release; commit the local package reference in `ios/DapurNaura` (see below); run `git add -A` or
`git commit -a` in `ios/DapurNaura`.

**Drafting requirements.** The human explains what they want; you draft it into
`docs/requirements/` at `status: draft` and ask whether it is correct, revising until they approve.
Drafts are mutable, approved documents are frozen. Every statement must trace to something the
human actually said — mark anything you added yourself `[ASSUMPTION]` inline, and put anything
undecided in `## Open questions` rather than guessing.

If you hit something that blocks implementation — the requirement is ambiguous, impossible, or
contradicts existing code — **stop**. Add a `## Blocked` section to the ticket stating the
problem and the options you see, then tell the human. Do not improvise around it.

## Workflow: Document Driven Development

Tickets come in two types, one number sequence (`DN-XXX`):

- **`product`** — from a requirement document. `source:` points at it; the document carries the why.
- **`technical`** — from a problem noticed in the code or tooling. No `source:`; a `## Rationale`
  section carries the why. Nobody writes a requirement asking for an injectable HTTP engine, so
  without this type such work cannot be ticketed at all.

The loop:

1. A requirement document lands in `docs/requirements/` — **or** a problem is noticed in the code.
2. Translate it into one or more tickets in `docs/tickets/`, one file per ticket.
3. **Data layer work needed?**
   - **Yes** → implement in `DNLibrary/`, write and **run** unit tests, fix until green.
     Then `publish-spm.sh local`, build the UI in `ios/DapurNaura/` against it, and **run it** on
     every platform that exists (iOS now, Android later).
   - **No (UI only)** → straight to `ios/DapurNaura/`. No tests, no publish, no version bump.
4. Stop. The human **verifies the running app** and reviews the diff — still on the local package,
   **nothing committed yet**.
5. On approval the human triggers commit in every repo, then push → PR. On rejection, feedback is
   verbal — fix and return to step 3. *If the same feedback comes up twice, write it into the
   ticket or the relevant `CLAUDE.md` so it survives the next session.*
6. After the PR merges the human says so; only then does the release step happen.
7. Once published, bump the app from the local package to the new version and commit that.

**Steps 1–4 are one loop with a single approval gate.** Do not wait for a DNLibrary merge before
building the app against it — that is what `publish-spm.sh local` is for. The library change and
the app change are proven together, locally, before anything is committed.

Requirement documents are immutable. Never edit one to match what was built — corrections belong
in the ticket.

Work on `ticket/DN-XXX-slug`, branched from `development`. Do not merge.

**Tests are required for the data layer only.** UI is verified manually by the human for now.

## Build & test

Gradle commands run from `DNLibrary/` — that is the Gradle root, `gradlew` lives there:

```sh
cd DNLibrary
./gradlew :sharedLogic:check                # all checks + tests, both platforms — the gate
./gradlew :sharedLogic:testDebugUnitTest    # Android host tests
./gradlew :sharedLogic:iosSimulatorArm64Test
./gradlew :sharedLogic:assemble             # Android library + iOS XCFramework
```

The iOS app must be built/run from `ios/DapurNaura/` in Xcode — Gradle alone cannot build it.

## The local package rule (iOS)

During development the app builds against `ios/DNLibraryLocal`, a build artifact in no repo.
**That wiring is never committed.** The committed `project.pbxproj` and `Package.resolved` always
name a remote SPMDNLibrary version.

Consequence: while a ticket is in flight the committed app state does not compile — the Swift code
calls APIs that only exist in the not-yet-published library version. It becomes valid again in a
final commit that bumps to the new version after publishing. This is expected.

Both `project.pbxproj` and `Package.resolved` go dirty when you switch to local. Revert both
before committing, and stage files explicitly — never `git add -A` in this repo.

## Publishing the iOS binary

`DNLibrary/scripts/publish-spm.sh`, interactive. Keep it at that path — it derives the Gradle root
as `dirname(scripts/)`.

- **`local`** — assembles the XCFramework into `ios/DNLibraryLocal/` for development. Run freely.
- **`publish`** — release build, zip, checksum, rewrites SPMDNLibrary's `Package.swift`, then
  tags, pushes, creates the GitHub release. **Human-triggered only, after the PR is merged.**

Versioning is plain semver on the library tag, independent of the app's version. `0.x` while the
API is unstable; what changed in a version goes in the release notes, not the number.

`gh` is not installed, so the agent cannot open PRs or create releases — the human does both.

## Current known blockers

- **The data layer cannot be unit-tested yet.** `DNNetworkManager` builds its `HttpClient` inline
  with no engine seam, and `initialize()` returns the existing singleton. Fixing this is a
  prerequisite for any test-bearing ticket — ticketed as DN-006.
- **DTOs are the public API.** A wire DTO with every field nullable is what Swift sees, which is
  why consuming code needs `?? "…"` everywhere. Domain models + mappers are the target.
- **Leftover scaffolding is still in the data layer.** An earlier throwaway DTO and its endpoint
  remain in `DNLibrary` and must be deleted before the domain is modelled — see DN-004.
- **`ios/DapurNaura` has no data layer.** No package dependency, no networking. It is a SwiftUI
  shell with four build variants. Do not add DNLibrary wiring until a ticket asks for it.
