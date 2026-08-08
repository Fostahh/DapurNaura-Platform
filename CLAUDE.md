# CLAUDE.md

Guidance for Claude Code working in the Dapur Naura platform workspace.

Full rationale, ticket lifecycle and release flow: [`docs/ARCHITECTURE-AND-WORKFLOW.md`](docs/ARCHITECTURE-AND-WORKFLOW.md).
Onboarding, and what this workspace is: [`README.md`](README.md).
> **Source of truth.** For *what was asked for*, `docs/requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

**How to execute — the working standard every agent follows, literally:
[`docs/AGENT-PLAYBOOK.md`](docs/AGENT-PLAYBOOK.md).** This file defines what is allowed; the
playbook defines how to do it well. Read both before starting any ticket.

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

> **What exists, as of 2026-08-06 — all of it on unmerged ticket branches.** The data layer models
> classes and class detail (`CookingClass`, `CookingClassDetail`, `RecipeSummary`, `PurchaseStatus`,
> `DNError`) behind two use cases, with shared formatting and 89 passing tests. iOS has two working
> screens on `@Observable` MVVM. **The recipe screen — the level the product actually sells — is a
> placeholder**, its requirement approved and unticketed. There is no backend (everything runs on
> `DNDataLayer.stub()`), no signed-in user, and no purchase path. Android does not exist.

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
ios/DapurNaura/               git repo → github.com/Fostahh/DapurNaura-iOS. SwiftUI app.
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

## Language, and confirming before you start

Added by DN-010 (2026-08-06). Two rules that apply to every session.

**The owner prompts in Bahasa Indonesia or English. The repository is always English.** Requirement
documents, tickets, `docs/`, code, comments, branch names and commit messages are English without
exception. An Indonesian instruction is recorded as **your English translation** — attributed as
translated and dated, not stored in the original. This deliberately narrows the playbook's *quote
verbatim* rule; what replaces it is that the translation must be a faithful transcription and never
an interpretation. Mark anything you added `[ASSUMPTION]`, and send any wording whose meaning your
translation could plausibly change to `## Open questions` rather than resolving it quietly.

**Never translate app content.** `kelas`, `bahan-bahan`, `loyang`, class and recipe names, every
user-facing string — all stay Bahasa Indonesia. There is no English localisation and none is
planned. The rule covers what the owner says *to you*, never what the app says *to its users*.

Reply to the owner in whichever language they used. That changes nothing about the repository.

**Confirm what was asked before you act on it.** Restate your understanding, name your assumptions
or state that there are none, and wait. Every request, either language. Ambiguity is asked about,
not chosen. Confirmation is per-request — like commit authority, it does not carry to the next one.
The gate is additive: the owner still verifies the running app and still triggers every commit.

It does not apply to problems you notice yourself — filing a technical ticket at `status: todo`
stays autonomous, because there is no instruction there to misread.

## Autonomy — what to do without asking, what to stop for

**Do without asking** — read anything; create and edit ticket files; **file a technical ticket at
`status: todo`** when you notice a problem; create the ticket branch; write code and tests on that
branch; run Gradle tasks; run `publish-spm.sh` in `local` mode; move a ticket between `todo` →
`in-progress` → `in-review`; **push a `ticket/*` branch**; **open a pull request** (DN-022);
**mark a ticket `done` once the owner has said its PR is approved and merged** (DN-022).

**Stop and wait for the human** — **acting on a request before the owner has confirmed your
restatement of it** (see Language above); **starting** a technical ticket you filed yourself (filing
is autonomous, scheduling is not); committing; **pushing anything other than a `ticket/*` branch**; merging anything; running
**initiating** `publish-spm.sh` in `publish` mode, a tag, or a GitHub release — the agent never
decides that a release should happen. **When the owner instructs it, the agent runs the publish end
to end and chooses the version number itself** (see Versioning below); **declaring a ticket `done`
on your own judgement** — the owner saying the PR is approved and merged is what authorises it, and
the agent never infers it from a green PR page;
**any destructive or irreversible act you were not explicitly asked for** — deleting, overwriting
or rewriting something you did not create, whether or not it appears on the `Never` list.

**Never** — edit a requirement document once it is `status: approved`; force-push; delete a tag or
release; commit the local package reference in `ios/DapurNaura` (see below); run `git add -A` or
`git commit -a` in `ios/DapurNaura`.

**Drafting requirements.** The human explains what they want; you draft it into
`docs/requirements/` at `status: draft` and ask whether it is correct, revising until they approve.
Drafts are mutable, approved documents are frozen. Every statement must trace to something the
human actually said — mark anything you added yourself `[ASSUMPTION]` inline, and put anything
undecided in `## Open questions` rather than guessing. If they said it in Bahasa Indonesia, what you
draft is your English translation of it — see Language above.

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
./gradlew :sharedLogic:testAndroidHostTest  # Android host tests (Robolectric)
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
  tags, pushes, creates the GitHub release. **Human-triggered, after the PR is merged** — the owner
  decides that a release happens; the agent then runs it and derives the version. Irreversible:
  deleting a tag or release is on the `Never` list, so a wrong number cannot be cleanly undone.

> **Before every publish, fetch and pull both repositories.** Owner's rule, 2026-08-08. `DNLibrary`
> *and* `ios/SPMDNLibrary` — check out the release branch and confirm it is level with its remote
> before running anything:
>
> ```sh
> git -C DNLibrary        checkout development && git -C DNLibrary        pull --ff-only
> git -C ios/SPMDNLibrary checkout development && git -C ios/SPMDNLibrary pull --ff-only
> ```
>
> **This exists because skipping it broke `0.5.0` on 2026-08-08.** The script was run against an
> `SPMDNLibrary` checkout four commits behind — DN-018 and DN-019 had merged on GitHub in the
> meantime. Its preflight passed (clean tree, allowed branch, HEAD on a remote branch — none of which
> notices staleness), so it rewrote the manifest, committed and tagged **on the stale base**.
>
> `git push origin HEAD --tags` then **partly succeeded**: git pushes refs independently, the branch
> was rejected as a non-fast-forward, and **the tag went through anyway** — leaving a published tag
> on a commit that existed on no branch, with no release behind it. The script blamed
> authentication; git had said `Note about fast-forwards`.
>
> Repairing it needed a tag and release deletion, which the `Never` list forbids and the owner
> authorised once. It also tripped SPM's tamper detection — it records tag-to-commit fingerprints and
> refuses to resolve when one moves — so every machine that had already resolved `0.5.0` had to have
> its fingerprint cache cleared by hand, with Xcode holding a second copy in DerivedData that
> `Package.resolved` alone does not fix.
>
> **Two seconds of `git pull` prevents all of it.**

Versioning is plain semver on the library tag, independent of the app's version. `0.x` while the
API is unstable; what changed in a version goes in the release notes, not the number.

**The scheme, settled with the owner on 2026-08-07.** First release is **`0.1.0`** — not `0.0.1`,
which reads as "nothing works yet" and wastes the only patch slot on a release already containing
two tickets. Then `0.MINOR.PATCH`: **MINOR** for any public API change, **PATCH** for a behaviour fix
with no API movement. **`1.0.0` is reserved for the App Store release** and must not be used before
it — owner's rule.

**The agent picks the number, the owner picks the moment.** Every ticket already declares its bump in
`## Public API contract` → *"Version bump implied"*, so the next version is **derived from the
tickets merged since the last tag**, never invented at publish time. If those declarations disagree
with the diff, the diff wins and the ticket is corrected.

**The app pins the library exactly (`.exact("0.1.0")`) for the whole of `0.x`, never a range.** A
range is a compatibility promise, and `0.x` makes none — DN-004, DN-006 and DN-008 each remove public
symbols and would silently break an app pinned to a range. Switch to a range at `1.0.0`.

Since DN-022 the agent may push `ticket/*` branches and open pull requests, using a
fine-grained token scoped to these four repositories. **Merging, tagging and releases stay the
human's** — the token has no permission for them either, so policy and credentials agree.
A pull request is a request; the decision is not delegated.

## Current known blockers

- **Merging started on 2026-08-07 and has barely begun — DN-001 is the only ticket `done`.**
  Everything else is `in-review` across four stacks. Each repo's branches are stacked on the previous
  rather than on the base, so **merge each repo's PRs in the order given in
  [`docs/tickets/README.md`](docs/tickets/README.md)**, one at a time — and **with a merge commit,
  never a squash**, or every branch above needs rebasing. On `main`, `ios/DapurNaura` is still a
  SwiftUI shell with four build variants and no data layer.
- **There is no notion of a signed-in user, and the domain needs one.** `purchaseStatus` is per-user
  data by definition, but nothing anywhere carries identity: no login, no session, no user model,
  `NetworkManager` holds a static `apiKey` only, and `SecureStorage` — built by DN-001 to hold
  exactly this — is referenced by nothing outside its own tests. Two screens already render state
  that cannot yet exist. **Owner's decision, 2026-08-06: deferred, to be ticketed later.** Do not
  design around it in the meantime.
- **Paid classes have no purchase path, manual or automated.** Midtrans is deliberately deferred,
  but `PENDING_VERIFICATION` describes a transfer-and-verify flow that is the *current* business
  process, and nothing implements that either — the buy button says *"Pembelian lewat aplikasi belum
  tersedia."* **Owner's decision, 2026-08-06: deferred, to be ticketed later.**
- **`docs/requirements/2026-08-06-recipe-detail.md` is approved and unticketed.** The recipe screen
  is the product — *bahan-bahan*, method, video — and `docs/contracts/recipe.json` is approved, but
  there is no `Recipe` domain model, no use case and no endpoint; iOS shows a placeholder. Owner's
  decision, 2026-08-06: ticket it once the iOS architecture work settles.

Previous blockers — no engine seam, singleton, DTOs-as-public-API, leftover scaffolding, zero
tests — were resolved on 2026-08-06 by DN-001/002/004/006/008 (all `in-review`).
