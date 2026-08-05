# CLAUDE.md

Guidance for Claude Code working in the Dapur Naura platform workspace.

## What this folder is

An umbrella workspace holding the Dapur Naura platform. **It is not a monorepo.** The three
projects below are independent git repositories with their own histories and remotes. The
umbrella itself is a small git repo that tracks `docs/` only.

```
docs/                Platform docs. Tracked by the umbrella repo.
  requirements/      Human-authored requirement documents. INPUT. Never edit these.
  tickets/           Agent-authored tickets, one file per ticket. OUTPUT.
DNLibrary/           git repo → github.com/Fostahh/DNLibrary
                     KMP library, the data layer. Ships as XCFramework (iOS) + AAR (Android).
DapurNaura/          git repo (local only, no remote). SwiftUI app, consumes DNLibrary.
SPMDNLibrary/        git repo → github.com/Fostahh/SPMDNLibrary
                     Manifest-only Swift package, semver tags. Distribution channel for iOS.
DNLibraryLocal/      Generated build artifact, not a repo. Local SPM package for testing.
android/             Native Android app. Not created yet.
```

`DNLibrary/CLAUDE.md` and `DapurNaura/CLAUDE.md` carry the details for each project. Read the
relevant one before working in that directory.

**Commits do not span projects.** A change touching both the data layer and the app produces one
commit in `DNLibrary/` and one in `DapurNaura/`, with nothing linking them. Reference the ticket
id in every commit message (`DN-004: …`) — that id is the only thread tying the work together
across repos, and the reviewer relies on it.

**`SPMDNLibrary` must stay its own repo.** Swift Package Manager resolves a git-URL dependency by
cloning the repo and reading `Package.swift` at the repo root — there is no subdirectory support.
It also needs its own tag namespace.

## Workflow: Document Driven Development

1. A requirement document lands in `docs/requirements/`.
2. Translate it into one or more tickets in `docs/tickets/`, one file per ticket.
3. Implement — data layer in `DNLibrary/`, UI in `DapurNaura/` where the requirement calls for it.
4. Write and **run** unit tests.
5. Stop. The human reviews the diff in a Git UI (Fork / SourceTree) and merges.

Requirement documents are immutable. Never edit one to match what was built — corrections belong
in the ticket. See `docs/ARCHITECTURE-AND-WORKFLOW.md` for the full rationale, the ticket
template, and the current architectural decisions.

Work on a branch per ticket (`ticket/DN-XXX-slug`), commit, and do not merge.

## Build & test

Gradle commands run from `DNLibrary/` — that is the Gradle root, `gradlew` lives there:

```sh
cd DNLibrary
./gradlew :sharedLogic:check                # all checks + tests, both platforms
./gradlew :sharedLogic:testDebugUnitTest    # Android host tests
./gradlew :sharedLogic:iosSimulatorArm64Test
./gradlew :sharedLogic:assemble             # Android library + iOS XCFramework
```

The iOS app must be built/run from `DapurNaura/` in Xcode — Gradle alone cannot build it.

## Publishing the iOS binary

`DNLibrary/scripts/publish-spm.sh`, interactive. Keep it at that path — it derives the Gradle root
as `dirname(scripts/)`. The flat layout of this workspace is what the script expects, so it works
unmodified: `local` mode writes to `DNLibraryLocal/` beside the app, and `publish` mode
auto-detects `SPMDNLibrary/` as a sibling of `DNLibrary/`.

- **`local`** — assembles the XCFramework into `DNLibraryLocal/` for pre-release testing.
- **`publish`** — release build, zip, checksum, rewrites SPMDNLibrary's `Package.swift`, then
  tags, pushes, creates the GitHub release. Dry-run by default.
