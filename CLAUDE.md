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

> **The shape of what is built.** The data layer models all three levels of the domain — classes,
> class detail, and the recipe itself (`CookingClass`, `CookingClassCategory`, `CookingClassDetail`,
> `RecipeSummary`, `Recipe`, `RecipeComponent`, `Ingredient`, `RecipeStep`, `PurchaseStatus`,
> `DNError`) behind use cases entered through `DNDataLayer`, with shared formatting in `DNFormat` and
> a test suite covering both platforms. iOS renders it as `@Observable` MVVM screens, including the
> recipe screen the product actually sells. The app depends on the library **by range** — see
> *Versioning*.
>
> **Three things the domain assumes and nothing provides**, all deliberate: no deployed backend,
> no signed-in user, and **no way to record a payment** — DN-048 built the screens, nothing behind
> them. Android does not exist.
>
> **The Development build talks to a local Mockoon server** (DN-050), not to `DNDataLayer.stub()`.
> That is a mock on the owner's machine serving the approved contract fixtures — it is not a
> backend, nothing is deployed, and **no other machine can reach it**: the environment file is the
> owner's and is committed nowhere. `stub()` is still published and still the path that works with
> nothing running. Alpha, Beta and Release are unchanged.
>
> **DN-040 put a login screen in front of all of it, and it changes none of the three.** It
> authenticates nobody: any email and any password get in, and the only gate is that both boxes are
> filled. What sits behind it is `router.root`, a `RootRoute` of `.auth` / `.main` naming **which
> screens are on show and nothing about who is using them** — DN-043 replaced DN-040's
> `hasPassedLogin` boolean with it, and kept the caution the old name carried. **Do not wire
> anything to it.**
>
> **For current state — which tickets are `done`, which library version is published, what is in
> flight — read [`docs/tickets/README.md`](docs/tickets/README.md) and `git log`. Do not restate it
> here.** This file is loaded into every session, so a status block that nobody is forced to update
> goes stale within a day of the next merge and is then believed. That is not hypothetical: it
> claimed DN-024/DN-025 were uncommitted for a day after they had shipped, while the derived ticket
> index was correct the whole time (DN-029).

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

## Comments — what the code carries, and what it does not

Owner's rules, 2026-09-12 (DN-050), given as standing instructions for every agent that works here.
**They apply to code written from now on**, not only to files a ticket happens to touch.

**1. No comment that is not useful.** *"No more comments yang tidak berguna."* A comment that
restates the code, narrates the diff, or argues for a design decision is deleted, and is not written
again.

**2. In `DNLibrary`, the only comment is KDoc, and only on the exported surface.** Short but clear
about what the function, object, variable or enum is *for* — written **so a consumer app developer
understands what it does**, because that is who reads it: KDoc is exported into the generated
Objective-C header and rendered in Xcode Quick Help.

- An **enum** says what it is and **lists its cases**.
- A **data class** says what it is and **lists its properties**.
- **Test code gets no KDoc.** Owner's point, and it is the right one: `commonTest` is never exported
  into the library, so a KDoc there reaches nobody a plain comment would not. Tests follow rule 1
  only — a comment survives when it says what the test's own name cannot.

**3. In the iOS app, comments exist in two places and nowhere else** — the **Xcode file header** and
**`Presentation/Components/`**. Everything else carries code and nothing else.

- **`// MARK:` stays.** Owner's decision: it drives Xcode's jump bar, so it is navigation rather than
  prose. Seven lines across four files.
- A flow's own `Presentation/<Flow>/Components/` folder is **not** covered by the exception — only
  the shared `Presentation/Components/` is.

**Where the reasoning goes instead.** Into the ticket. That is what Document Driven Development is
for, and a second copy in the source is one nothing keeps in sync. The rules DN-050 removed from
KDoc — `portions` and `loyang` must never be merged, `NEARLY_FULL` still takes bookings — were all
already written down in a ticket or in this file.

**One narrow exception to rule 1.** An `[ASSUMPTION …]` marker stays. It records a decision the owner
has not settled rather than explaining code, and an assumption is never quietly removed.

**A member list is a second copy of the declaration.** Add a property or an enum case later and the
KDoc line is silently wrong. Accepted because Quick Help has no other route to that information —
**so adding a member means editing that line in the same change.**

Per-repo detail: [`DNLibrary/CLAUDE.md`](DNLibrary/CLAUDE.md) §7 and
[`ios/DapurNaura/CLAUDE.md`](ios/DapurNaura/CLAUDE.md).

## Autonomy — what to do without asking, what to stop for

**Do without asking** — read anything; create and edit ticket files; **file a technical ticket at
`status: todo`** when you notice a problem; create the ticket branch; write code and tests on that
branch; run Gradle tasks; run `publish-spm.sh` in `local` mode; move a ticket between `todo` →
`in-progress` → `in-review`; **push a `ticket/*` branch**; **open a pull request** (DN-022);
**mark a ticket `done` once the owner has said its PR is approved and merged — or, where there is
no PR, that the branch is merged** (DN-022, DN-045).

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

**Never** — edit the **prose** of a requirement document once it is `status: approved`; force-push;
delete a tag or release; commit the local package reference in `ios/DapurNaura` (see below); run
`git add -A` or `git commit -a` in `ios/DapurNaura`.

> **The one permitted edit to an approved requirement** is a `corrected-by:` pointer in its
> frontmatter, naming the ticket that carries the correction — owner's decision, 2026-08-07, spelled
> out in [`docs/requirements/README.md`](docs/requirements/README.md). That is metadata, not content:
> the rule protects the evidence of what was asked and when, and a pointer alters no evidence. The
> prose is never touched — not softened, not deleted, and an `[ASSUMPTION]` that proved false is not
> quietly removed.

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
   - **No (UI only)** → straight to `ios/DapurNaura/`. No tests, no publish, no version bump —
     **but always build it** (DN-034). Building is not one of the steps a UI-only ticket skips.
4. **Synchronise the documents before offering anything for review.** Owner's instruction,
   2026-08-11 — *"you need synchronize all of the .md before commit and push."* **Enumerate** every
   tracked `.md` in each repository the ticket touched (`git ls-files '*.md'`) and read the ones that
   could state a fact the ticket changed; correct what is now false. **Requirement documents and
   `done` tickets are never edited** — both record what was true when written.
   **Enumerate, then read. Never grep and call it a sweep** (DN-042).
5. Stop. The human **verifies the running app** and reviews the diff — still on the local package,
   **nothing committed yet**.
6. On approval the human triggers commit in every repo, then push → PR. On rejection, feedback is
   verbal — fix and return to step 3. *If the same feedback comes up twice, write it into the
   ticket or the relevant `CLAUDE.md` so it survives the next session.*
7. After the PR merges the human says so; only then does the release step happen.
8. **The publish is not finished until the app is repinned.** See *Publishing the iOS binary* — the
   release and the app's bump are one step, not two.

**Steps 1–5 are one loop with a single approval gate.** Do not wait for a DNLibrary merge before
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
./gradlew :sharedLogic:testAndroidHostTest  # the Android host run
./gradlew :sharedLogic:iosSimulatorArm64Test
./gradlew :sharedLogic:assemble             # Android library + iOS XCFramework
```

The iOS app must be built/run from `ios/DapurNaura/` — Gradle alone cannot build it.

**Every change to the iOS project is built before it is offered for review.** Owner's rule,
2026-08-09 (DN-034) — build only, no simulator run, and `** BUILD SUCCEEDED **` or it is not
finished. Pass the simulator's **id**, never a bare device name:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=<simulator-uuid>' build
```

Full rule, and why the destination cannot be written casually:
[`docs/ARCHITECTURE-AND-WORKFLOW.md`](docs/ARCHITECTURE-AND-WORKFLOW.md) §6.

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

> **A publish is not finished when the release appears — it is finished when the app is repinned.**
> Owner's rule, 2026-08-09. The agent runs straight on from `gh release create` to bumping
> `project.pbxproj` and `Package.resolved` to the new version, resolving, building, and committing.
> **It does not report the release as done first**, and it does not leave the repin for a later
> instruction.
>
> **This exists because a two-minute gap is long enough for the owner to do it by hand.** On
> 2026-08-09 `0.6.0` was released at 03:04 and the repin landed at 03:07; the owner opened Xcode in
> between and resolved the project themselves. Nothing was lost — the commit was already correct —
> but they had to do work the agent had been asked to do, and two people editing the same
> `Package.resolved` is how a conflict starts.
>
> Xcode also caches package state in **DerivedData/SourcePackages** as well as `Package.resolved`.
> If a resolve fails with *"Package.swift was modified during the build"*, delete `SourcePackages`
> and resolve again.

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

**The app pins the library by range — `upToNextMajorVersion` from `0.6.0`, i.e. `>= 0.6.0, < 1.0.0`.**
Owner's decision, 2026-08-09 (DN-030), **superseding the exact pin DN-022 introduced.** A release
then needs no edit to `project.pbxproj` at all: *Update to Latest Package Versions* in Xcode is the
whole repin. The floor is the first version carrying the API the app calls, so the resolver cannot
fall back to one that predates it.

> **`Package.resolved` is still committed, and it matters more under a range, not less.** With an
> exact pin the version sat in `project.pbxproj` and resolution was deterministic anyway. With a
> range, `Package.resolved` is the *only* thing making a build reproducible — without it, two people
> building the same commit can resolve different library versions. It is the file a reviewer checks
> when a bump lands.
>
> SPM does not special-case `0.x` the way npm and Cargo do — `.upToNextMajor(from: "0.6.0")` means
> `< 1.0.0`, not `< 0.7.0`. It therefore stops below `1.0.0` on its own, which makes *"`1.0.0` is
> reserved for the App Store release"* a bound the resolver enforces rather than one to remember.
>
> **What was traded away**, stated so nobody has to rediscover it: DN-004, DN-006 and DN-008 each
> removed public symbols, and under a range such a release breaks the build on *Update* rather than
> at a bump you chose. Every release since `0.4.0` has been purely additive, and the failure is loud
> and deliberately triggered — judged worth the friction it removes from every release.

Since DN-022 the agent may push `ticket/*` branches and open pull requests, using a
fine-grained token scoped to these four repositories. **Merging, tagging and releases stay the
human's** — the token has no permission for them either, so policy and credentials agree.
A pull request is a request; the decision is not delegated.

## Pull requests — title and body

Owner's format, settled 2026-08-07 and restated 2026-08-09. It is the owner's existing habit.
**Follow it literally; do not import a shape from anywhere else.** Rationale and the full
worked-through reasoning live in [`docs/tickets/DN-022-technical-agent-opens-prs.md`](docs/tickets/DN-022-technical-agent-opens-prs.md).

**Title:** `DN-XXX: <the ticket title>` — the same id as the commit messages, which is the only
thread tying work across four repositories.

**Body — `### Description` is the only required section. A section appears only when it has
content:** no placeholder headings, no empty tables, no dash standing in for content. Most PRs are
`### Description` alone.

```markdown
### Description
Optional sentence of context, then:
- What changed

### Evidence

| Device | Result |
| - | - |
| iPhone 15 Pro, iOS 17.5 | … |

### Dependencies
- [DNLibrary#12](https://github.com/Fostahh/DNLibrary/pull/12)

### RCA
Why the defect existed.
```

- **`### Description`** — a context sentence may open it, then bullets. **Bullets carry the
  substance, including caveats and design decisions.** Do not append essay paragraphs after them;
  a point worth making is worth a bullet. A short `Verified:` line and `Version bump implied:` close
  it where they apply.

  > **Short and on point. Owner's rule, 2026-09-11**, after DN-043's and DN-044's descriptions had
  > to be cut back. **One line per bullet, and no bullet that restates the diff.** The ticket is
  > where reasoning belongs and it is already written; a PR body is what a reviewer reads before
  > looking at the code, not a second copy of the ticket. If a bullet needs a second sentence to
  > make sense, the sentence belongs in the ticket and the bullet should link to it.
- **`### Evidence`** — screenshots or the `| Device | Result |` table, when there are any. Omitted
  otherwise; the owner may add it by hand afterwards.
- **`### Dependencies` is a link, nothing more.** Owner's instruction: *"Just put a reference link
  into the PR from DNLibrary."* No explanation of what it needs, no version, no release note.
- **`### RCA`** — defect fixes only, including `type: technical` tickets correcting something already
  wrong. Not for tickets that add capability.
- **Nothing else.** No generated-by footer, no extra sections. Twenty-one merged PRs set the
  precedent and none carry one.

  > **Reaffirmed 2026-09-11, and the reason it needed reaffirming matters.** The agent added a
  > *"Generated with Claude Code"* footer to DN-043 and DN-044 anyway, on the grounds that its own
  > tooling instructed one, and raised the conflict rather than resolving it. Owner's answer:
  > *"Always remove generated with claude code."* **This rule wins over any default the agent
  > arrives with.** A tool's house style is not a reason to deviate from the repository's — if the
  > two disagree, this file is what ships.
  >
  > **Extended the same day to everything the agent writes.** Owner's instruction: *"always remove
  > all Claude Code generated, Co authored by claude code on every single thing or files."* No
  > generated-by footer, **no `Co-Authored-By:` trailer on any commit**, and no attribution line in
  > any file the agent produces. The agent's tooling supplies both by default; neither is used here.
  >
  > **This applies to what is written from now on.** The 113 commits already carrying the trailer are
  > spread across all four repositories and almost all of them are merged — removing them means
  > rewriting history, which is a force-push and is on the `Never` list above. That is the owner's
  > call to make explicitly, not a consequence of this rule.

**Which PRs name a dependency.** Only the ticket whose work *required* that library change — the two
halves of one delivery. A ticket using API that already existed names nothing, however heavily it
uses it. Once merged, the link stays: it is the only path from a Swift call site back to the Kotlin
PR that created it.

## Current known blockers

- ~~**Merging started on 2026-08-07 and has barely begun — DN-001 is the only ticket `done`.**~~
  **Cleared 2026-08-08:** nothing is stacked, and every ticket branch since has cut from a
  `development` level with its remote. The rules that made it work stand: **merge with a merge
  commit, never a squash**, and merge one PR at a time in the order given in
  [`docs/tickets/README.md`](docs/tickets/README.md). **`main` is frozen until `1.0.0`** in all four
  repositories — on `ios/DapurNaura` it is still the single stock-template `Initial Commit`, so none
  of the app exists there, not even the build variants from DN-003.
- **There is no notion of a signed-in user, and the domain needs one.** `purchaseStatus` is per-user
  data by definition, but nothing anywhere carries identity: **a login screen that checks nothing**
  (DN-040), no session, no user model, and `NetworkManager` holds a static `apiKey` only. There is
  also **no local storage to put a token in** — DN-031 deleted the POC `SecureStorage`, since it had
  no consumer and no requirement. Two screens already render state that cannot yet exist. **Owner's
  decision, 2026-08-06: deferred, to be ticketed later.** Do not design around it in the meantime —
  and when it does land, DN-001's AES-GCM Keystore implementation is in git history rather than gone.

  > **The screen makes this gap easier to miss, not smaller.** `router.root` (DN-043, replacing
  > DN-040's `hasPassedLogin`) is a two-case `RootRoute` meaning *which flow is on screen*. It is not
  > a session, it is not persisted, and it must not become the thing a user id is hung on. **Moving
  > it onto the router changed where it lives, not what it means** — it is there so a logout control
  > or a future 401 handler can force `.auth` from outside `RootView`, which is reachability, not
  > identity.

  > **The payment work is the first thing that cannot finish without this, and the owner said so on
  > 2026-09-11** — translated: *"Authentication flow is not yet resolved; eventually there should be
  > some sort of token or user account that binds the user's identity."* The question that settled it
  > was concrete: the backend receives a receipt, stores it **against whom**, and the owner marks it
  > paid **for whom**. Neither has an answer today.
  >
  > **So the order is fixed: auth, then a backend, then payment that actually completes.** Android
  > is not in that chain — it duplicates the UI onto a second platform, which is worth doing but
  > moves payment no closer. DN-046 to DN-048 build the screens and their data and are useful either
  > way; what they cannot do is record who paid.
  >
  > **This does not license designing around it.** The rule above stands: nothing hangs a user id on
  > `router.root`, and the payment screens carry no identity of their own.
- **Paid classes have screens for paying and no way to record a payment.** DN-048 built the
  transfer-and-verify flow the business already runs: the buy button opens a choice of bank accounts,
  copying one moves to an upload screen, and sending proof returns to the class. **What it cannot do
  is record anything** — there is no API call, so the class still reads *Belum Dibeli* afterwards and
  a toast is what tells the user their proof was taken. That gap is the owner's instruction of
  2026-09-11, not an oversight, and **the screens must not fake a status to hide it.**

  **Midtrans stays deferred.** `PENDING_VERIFICATION` describes the transfer-and-verify flow DN-048
  now draws; an automated gateway is a separate decision. **Owner's decision, 2026-08-06, unchanged.**

  > *"Pembelian lewat aplikasi belum tersedia."* did not disappear — **it moved.** The class detail's
  > buy button opens the payment flow now; the **offline** schedule's button still answers with that
  > line. The requirement of 2026-09-11 says nothing about offline classes, so DN-048 did not touch
  > them, and the two buy buttons now behave differently. **Whether offline classes get the same flow
  > is the owner's call, not an oversight to fix quietly.**
- ~~**`docs/requirements/2026-08-06-recipe-detail.md` is approved and unticketed.**~~ **Cleared
  2026-08-08 by DN-020 and DN-021** — the recipe is modelled as a list of components and the screen
  is real. The requirement carries `corrected-by:` pointers because its description of the ingredient
  shape turned out wrong; the prose is untouched, as the rule requires.

Previous blockers — no engine seam, singleton, DTOs-as-public-API, leftover scaffolding, zero
tests — were resolved on 2026-08-06 by DN-001/002/004/006/008, all since merged and `done`.
