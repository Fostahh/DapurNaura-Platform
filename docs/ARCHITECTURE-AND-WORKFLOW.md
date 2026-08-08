# Dapur Naura — Architecture & Workflow

**Status:** revised 2026-08-06. Reflects decisions taken in design discussion; the workflow has
not yet been run end to end on a real ticket.

The reference document for how this platform is built. Items are tagged **[DECIDED]** or
**[OPEN]** (still needs a call). For onboarding, read
the [repository README](../README.md) first — this document is the deep reference.

---

## 1. Goal and scope

**Dapur Naura** is a cooking app, built to help the owner's family digitalise their cooking
products. The audience is people learning to cook.

The shape of the domain, as confirmed against real content:

```
CookingClass  ──sections[]──>  Recipe  ──components[]──>  ingredients[] + steps[]
"Makanan Kekinian"             "Brownies Red Velvet"      "Brownis"
"Jajanan 1"                     images[], video           "Toping creamcheese"
                                description, difficulty
                                prepTime, portions, loyang
```

**A *kelas* is a cooking class, not a category.** It bundles recipes taught together — the source
documents are titled "COOKING CLASS". A class has ordered **sections** (the main curriculum, plus
"Bonus Resep"), and each recipe has ordered **components**, each with its own ingredients and
method. Both levels needed sections because a real recipe is not one ingredient list and one
method — the brownies recipe has two of each.

**These classes are sold.** Payment (Midtrans) is planned but **deliberately deferred** — adding an
entitlement field later is an additive change, so nothing needs preparing now.

Content is **Bahasa Indonesia only**. The audience is home cooks, many learning to produce food for
income — the ingredient notes say things like *"sesuaikan dengan harga jual"*.

### What actually exists

Accurate as of 2026-08-06. **Nothing is merged** — all of this lives on stacked ticket branches, and
each repository's `main` is still at its pre-DN-001 state.

**The data layer covers the first two levels of the domain.** `CookingClass`, `CookingClassDetail`,
`RecipeSummary`, `PurchaseStatus` and `DNError` are modelled against the approved contract, reached
through `GetCookingClassesUseCase` and `GetCookingClassDetailUseCase`. `DNFormat` and
`DNError.userMessage` render prices and failures for every platform. **89 tests**, green on both.

**The iOS app has two working screens** — the class list and the class detail — built on
`@Observable` MVVM over an owned navigation path, with SwiftLint reporting zero violations.

**What is missing is the level that matters most.** The recipe screen — *bahan-bahan*, the
step-by-step method, the video — is a placeholder. Its requirement is approved and still unticketed,
and no `Recipe` model, use case or endpoint exists.

**Three things the domain assumes and nothing provides:**

- **No backend.** Everything runs on `DNDataLayer.stub()`, which replays the approved contract
  fixtures through the real decoding path. The wire shape has never met a server.
- **No signed-in user**, although `purchaseStatus` is per-user data by definition. No login, no
  session, no user model. Deferred by the owner on 2026-08-06, to be ticketed later.
- **No purchase path at all** — not Midtrans, and not the manual transfer-and-verify flow that
  `PENDING_VERIFICATION` describes and that is the *current* business process. Also deferred.

Android has not been created.

**[DECIDED] Naming.** `Recipe` and `CookingClass`. Never a type called `Class` — it collides with
Objective-C's `Class` in the generated header. Indonesian domain terms are kept where translation
loses meaning (`loyang`).

**[DECIDED] The JSON contract is written and approved** (v1, 2026-08-06) — see
[contracts/](contracts/). Approved is not frozen: contracts may still be revised deliberately while
the UI takes shape, which is why they live in `docs/contracts/` rather than the immutable
`docs/requirements/`. DTOs and domain models are built against those files.

---

## 2. The workspace

**[DECIDED] Umbrella workspace, not a monorepo.**

| Piece | Path | Git | Role |
|---|---|---|---|
| **Umbrella** | `DapurNaura-Platform/` | repo, `main` | Tracks `docs/` + config only |
| **DNLibrary** | `DNLibrary/` | repo → `Fostahh/DNLibrary`, `main` + `development` | KMP source. One `sharedLogic` module → XCFramework + Android library |
| **DapurNaura** | `ios/DapurNaura/` | repo → `Fostahh/DapurNaura-iOS`, `main` + `development` | SwiftUI app |
| **SPMDNLibrary** | `ios/SPMDNLibrary/` | repo → `Fostahh/SPMDNLibrary`, `main` + `development` | Manifest-only Swift package. `Package.swift` → GitHub release zip + checksum |
| **DNLibraryLocal** | `ios/DNLibraryLocal/` | **not a repo** | Build artifact — local SPM package for development |
| **Android** | `android/` | — | Not created yet |

### Why separate repos

DNLibrary is a library consumed by two independent apps, so it needs its own release cadence.
Folding it into a monorepo fights that.

`SPMDNLibrary` **cannot** be a subdirectory of anything: SPM resolves a git-URL dependency by
cloning the repo and reading `Package.swift` **at the repo root** — no subdirectory support for
remote dependencies. It also needs its own tag namespace so library versions don't collide with
app versions.

The umbrella `.gitignore` makes git blind to every project folder — no submodules, no gitlinks,
no double-tracking. `bootstrap.sh` clones them into place.

### The cost, and the mitigation

A ticket lives in the umbrella; the commits satisfying it live in the project repos. **Nothing
links them except the `DN-XXX` id in the commit message.** That convention is therefore
load-bearing, not cosmetic.

**[OPEN]** Enforcement is now ticketed as **DN-007** — a `commit-msg` hook installed by
`bootstrap.sh`. Until it lands, the convention is unenforced and can be silently forgotten.

---

> **Source of truth.** For *what was asked for*, `requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

## 3. Document Driven Development

**[DECIDED]** No Jira. Requirements and tickets are markdown in the umbrella repo.

```
docs/requirements/   ← human writes. INPUT.  IMMUTABLE.
docs/tickets/        ← agent writes. OUTPUT. Mutable.
docs/contracts/      ← agreed wire shape. Approved ≠ frozen — revisions are deliberate and noted.
```

### Two entry points **[DECIDED]**

Work reaches a ticket two ways, and tickets are typed accordingly:

| | **Product ticket** | **Technical ticket** |
|---|---|---|
| Starts from | A requirement document | A problem observed in the code or tooling |
| `source:` | Required | None — no document exists |
| Carries its "why" in | The requirement document it quotes | Its own `## Rationale` section |

Nobody writes a requirement saying "make the HTTP engine injectable" — so without the technical
type, testability, architecture and tooling work cannot be ticketed at all. Both types share one
`DN-XXX` number sequence; see [tickets/README.md](tickets/README.md) for the templates.

### The loop

```
Human explains what they want     Problem noticed in code/tooling
        ↓                         (by the human or the agent)
Agent restates it — human confirms            │
   (no assumptions, either language)          │
        ↓                                     │
Agent drafts the requirement                  │
   (status: draft)                            │
        ↓                                     │
"Is this correct?" ──no──→ human corrects     │
        │ yes          ↑         │            │
        │              └─────────┘            │
   status: approved — FROZEN                  │
        │                                     │
        └───────────────┬─────────────────────┘
                        ↓
Agent writes ticket(s) into docs/tickets/
  · from a requirement → type: product
  · from an observation → type: technical (agent may create, not start)
        ↓
   Data layer work needed?
        │
        ├── YES ──→ implement in DNLibrary
        │              ↓
        │           write / update unit tests
        │              ↓
        │           run tests ──failing──→ fix ──┐
        │              ↓ passing                 │
        │              ←──────────────────────────┘
        │              ↓
        │           publish-spm.sh local
        │              ↓
        │           implement UI against DNLibraryLocal, and RUN IT
        │           on each platform that exists (iOS now, Android later)
        │              ↓
        └── NO ─────→ implement UI only
                       ↓
                  Human verifies the running app + reviews the diff
                  (still on the local package — nothing committed yet)
                       ↓
                  ├── rejected → verbal feedback → back to implementation
                       ↓ approved
                  Human triggers commit — every repo, each on ticket/DN-XXX-slug
                       ↓
                  Push + PR (human opens the PR; no gh)
                       ↓
                  PR merged into `development`; human tells the agent
                       ↓
                  Release step (see §7) — human-triggered
                       ↓
                  Human marks the ticket done
```

**An approved requirement is never edited to match what was built.** That destroys the audit
trail, which is the whole point. Corrections go in the ticket.

### Language, and the confirm gate **[DECIDED]** — DN-010

**The owner prompts in Bahasa Indonesia or English. The repository is always English.** Requirement
documents, tickets, `docs/`, code, comments, branch names and commit messages, without exception.

An Indonesian instruction is recorded as the agent's **English translation**, attributed as
translated and dated; the original is not stored. This narrows the "quote the human verbatim" rule
in [AGENT-PLAYBOOK.md](AGENT-PLAYBOOK.md) §1, and the owner decided it that way on 2026-08-06. What
replaces `verbatim` is a stricter obligation on the agent: the translation is transcription, never
interpretation, and any wording whose meaning the translation could plausibly change goes to the
ticket's `## Open questions` rather than being resolved silently.

**App content is never translated.** `kelas`, `bahan-bahan`, `loyang`, class and recipe names and
every user-facing string stay Bahasa Indonesia — §1 says there is no English localisation and none
is planned. The rule governs what the owner says *to the agent*, not what the app says *to its
users*. Agent replies in chat match the owner's language; that changes nothing in the repository.

**Before acting on a request, the agent restates it and waits for confirmation.** Every request,
either language. Assumptions are named, or their absence is stated — and "no assumptions" is a
claim that must be true. Ambiguity is asked about, never chosen. Confirmation is per-request, like
commit authority is per-batch.

The gate is additive. It sits *before* work starts and replaces nothing downstream: the human still
verifies the running app at step 4 of §7, and still triggers every commit. It does not apply to
problems the agent notices on its own — filing a technical ticket at `todo` stays autonomous,
because there is no instruction there to misread.

Why it exists: every other gate in this workflow sits *after* work exists, so a misread request was
previously only caught once it had been built — by which point the ticket describing it has also
become the permanent record of why the code exists. Translation raises that risk rather than
lowering it, since a misread instruction and a confident English ticket are indistinguishable to
the next agent that reads the ticket.

### Who writes the requirement **[DECIDED]**

The content is always the human's decision; the typing is not. The human explains what they want —
as a product owner or as a mobile developer describing behaviour — and the agent drafts it into
`docs/requirements/` at `status: draft`, then asks whether it is correct. That loop repeats until
the human approves, at which point `status: approved` freezes the document.

**Drafts are mutable; approved documents are frozen.** The `status:` field marks exactly when.

The agent's obligation while drafting: every statement must be traceable to something the human
actually said. Anything the agent adds on its own initiative is marked `[ASSUMPTION]` inline, and
anything undecided goes to `## Open questions` rather than being guessed. An unmarked invention
that gets approved becomes a requirement nobody asked for — the single failure mode of drafting on
the human's behalf.

### Why one file per ticket **[DECIDED]**

Chosen over a single `TODO.md`: status churn stays out of code diffs during review; the agent
reads only the ticket it needs rather than an ever-growing list; and concurrent ticket updates
can't clobber each other.

`docs/tickets/README.md` holds the template and a regenerated at-a-glance index (derived —
if it drifts from the files, the files win).

---

## 4. Ticket lifecycle

**[DECIDED]** Four states. The `status:` field in the ticket front-matter is the source of truth.

| State | Meaning | Who sets it |
|---|---|---|
| `todo` | Written from a requirement, not started | Agent, at creation |
| `in-progress` | Being implemented | Agent |
| `in-review` | Implemented, data-layer tests green, awaiting human review | Agent |
| `done` | PR merged | **Human, manually** |

### Rejection

**[DECIDED]** Handled **verbally**. The agent flips the ticket back to `in-progress` and fixes.

Known limitation, worth managing deliberately: an agent starts every session cold, so verbal
feedback does not survive the session boundary. **If the same feedback is given twice, write it
down** — into the ticket if it is ticket-specific, into the relevant `CLAUDE.md` if it is a
standing preference. Once is fine to leave verbal.

### Blocked

If the agent cannot implement — the requirement is ambiguous, impossible, or contradicts existing
code — it **stops**, appends a `## Blocked` section to the ticket describing the problem and the
options it sees, and tells the human. Status stays `in-progress`. Improvising around a blocker is
never correct.

---

## 5. Agent autonomy

**[DECIDED]** The boundary, so it doesn't get renegotiated every session.

### Without asking

- Read anything in the workspace
- Create and edit ticket files in `docs/tickets/`
- **Create a technical ticket at `status: todo`** when it notices a problem — untestable code,
  drift, a tooling defect. This is how an incidental finding becomes tracked work instead of
  scope creep or a lost observation. It may **not start** one until the human schedules it.
- Create the ticket branch `ticket/DN-XXX-slug`
- Write and modify code on that branch, in any project repo
- Write and run unit tests; run any Gradle task
- Run `publish-spm.sh` in **`local`** mode
- Move a ticket between `todo` → `in-progress` → `in-review`

### Stop and wait for the human

- **Acting on a request before the human has confirmed the agent's restatement of it** — §3, DN-010
- **Starting** work on a technical ticket it created itself — filing is autonomous, scheduling is not
- Committing; pushing anything other than a `ticket/*` branch; merging
- Merging anything
- Running `publish-spm.sh` in **`publish`** mode
- Any tag or GitHub-release operation
- Marking a ticket `done`

### Never

- Edit a file in `docs/requirements/` — they are immutable
- Force-push; delete a tag or a release
- Commit the local package reference in `ios/DapurNaura` (§7)
- `git add -A` or `git commit -a` in `ios/DapurNaura` — Xcode rewrites `project.pbxproj`
  constantly, so a blanket add sweeps the local wiring into history

**[DECIDED — DN-022, 2026-08-07]** The agent may push `ticket/*` branches and open pull
requests. It may not merge, tag, or create a release, and it may not push to `main` or
`development`. The fine-grained token it authenticates with carries no permission for any of
those, so a mistaken command cannot land code — the credential enforces what the rule says.

---

## 6. Definition of Done

**[DECIDED]** Per layer, because the two have different verification stories.

### Data layer (DNLibrary)

- Code implemented on `ticket/DN-XXX-slug`
- Unit tests written **and run**; `./gradlew :sharedLogic:check` green (covers both platforms)
- Committed, not merged

### UI (DapurNaura)

- Code implemented on `ticket/DN-XXX-slug`
- **Verified manually by the human.** No automated gate — tests are data-layer only.

**[OPEN]** UI testing on both platforms is wanted eventually; no date set.

### Tooling (scripts, build config, CI)

Neither layer applies — the `publish-spm.sh` preflight fix is the worked example. Done when:

- The change is implemented
- **Its behaviour is demonstrated**, including the failure paths it is supposed to catch
- Committed, not merged

### The ticket

Done when the **PR is merged**, marked manually by the human.

### Why tests are not optional in the data layer

An agent cannot run the app and look at it. Unit tests are the only way it can tell whether what
it wrote works — they are its feedback loop, not merely a quality gate. Until the testability
blocker in §8 is fixed, data-layer work is unverifiable by the agent doing it, and verification
falls entirely on the human review.

---

## 7. Release flow

### Branches **[DECIDED]**

| Branch | Role |
|---|---|
| `ticket/DN-XXX-slug` | One per ticket. Branched from `development`. Never merged by the agent. |
| `development` | PR base. Integration. QA / CISO testing. Alpha / Beta / UAT variants. |
| `main` | Protected. Receives release-ready code from `development`. No direct changes. |

**[DECIDED] `main` is the standard name** across every repository — DNLibrary and SPMDNLibrary
were renamed from `master`. `development` now exists in all three project repos.

**[OPEN]** The renames and the new branches are **local only**. Until they are pushed, GitHub still
shows `master` as the default branch for DNLibrary and SPMDNLibrary.

### Versioning **[DECIDED]**

Three independent numbers. **They are not related and must not be made to match.**

| Number | Where | Read by |
|---|---|---|
| **Library version** | SPMDNLibrary git tags | The SPM resolver — a machine with semver semantics built in |
| **App version** | `MARKETING_VERSION` | Humans, in the App Store |
| **Build number** | `CURRENT_PROJECT_VERSION` | App Store Connect; must strictly increase |

The library uses **plain semver, driven by the change** — additive API is a minor, a
changed/removed public symbol is a major, a fix is a patch. `0.x` while the API is unstable, which
it is; `1.0.0` is reserved for the deliberate moment the API is committed to.

**What changed in a version belongs in the release notes, not in the number.**

The agent proposes the bump from the ticket's *Public API contract* section; the human confirms
at publish time.

**[OPEN]** The existing tags `1.0.0`–`1.4.0` predate this workflow and mean nothing. Resetting to
`0.x` requires deleting those 5 tags and their 5 GitHub releases. Safe — nothing consumes them,
and `ios/DapurNaura` has no dependency at all — but the human will do it manually.

### The iOS dependency **[DECIDED]**

The app depends on SPMDNLibrary by **version range** (`.upToNextMajor`), **not** an exact pin.

**Therefore `Package.resolved` must be committed.** With a range, it is the only thing that makes
a build reproducible — without it, two people building the same commit can get different library
versions, and a "frozen, ready to release" `main` is not actually frozen. It is currently deleted
from the working tree (§9) and must be restored.

### The local package rule **[DECIDED]**

During development the app builds against `ios/DNLibraryLocal`. **That wiring is never committed.**
The committed `project.pbxproj` and `Package.resolved` always name a remote version.

Consequence, which is expected and not a bug: while a ticket is in flight, the committed app state
**does not compile** — the Swift code calls APIs that only exist in the not-yet-published library
version. It becomes valid again in a final commit that bumps to the new version after publishing.

Both files go dirty when switching to local. Revert both before committing; stage explicitly.

### Sequence **[DECIDED]**

**Verify the whole slice locally before anything is committed.** The library change and the app
change are proven together, against the local package, in one approval gate — rather than
approving a diff, merging, publishing, and only then finding out the app doesn't work.

| # | Step | Who |
|---|---|---|
| 1 | Implement in DNLibrary; `:sharedLogic:check` green | agent |
| 2 | `publish-spm.sh local` → `ios/DNLibraryLocal` | agent |
| 3 | Implement the UI against the local package and **run it** on every platform that exists | agent |
| 4 | **Verify the running app**, review the diff — nothing is committed yet | **human** |
| 5 | Rejected? verbal feedback, back to step 1 | human |
| 6 | Approved → trigger commit in every repo, each on `ticket/DN-XXX-slug` | **human** |
| 7 | Push; open the PR (no `gh`, so the human does this) | human |
| 8 | PR merged into `development`; tell the agent | **human** |
| 9 | Release cut: `development` → `main`, then `publish-spm.sh publish` from a clean `main` | human-triggered |
| 10 | App switches from the local package to the published version; commit `Package.resolved` | agent |
| 11 | Mark the ticket `done` | **human** |

**Steps 1–4 are one loop with one gate.** Nothing merges, publishes, or waits in the middle. That
is the point of the change — the human is asked to approve once, on something that demonstrably
runs, not twice on partial state.

**Step 10 cannot move earlier.** The tag does not exist until step 9, and the app cannot reference
a version that has not been published. So the final version bump is always a separate, tiny commit
after the release. It is two lines in `Package.resolved` and needs no second review.

Until then the app's committed state names the *previous* version and does not compile — expected,
and covered by the local package rule above.

**[OPEN] Publish cadence.** Step 5 as written cuts tags from `main` only, which means library
versions increment **per release, not per ticket** — several tickets batch into one version.
That keeps version numbers meaningful and stops them burning through `0.9.0` in a fortnight. It
also means a ticket can be `done` before its code is ever published. Needs explicit confirmation.

### Publish preflight — fixed by DN-005 **[RESOLVED]**

`publish-spm.sh` used to validate only **SPMDNLibrary's** working tree — a release binary could be
built from uncommitted DNLibrary code on any branch, tagged and published, with nothing recording
where it came from.

**DN-005** (in-review) fixed it: publishing now refuses a dirty, non-release-branch or unpushed
DNLibrary tree, stamps the source commit SHA into the release notes, and adds a `preflight`
subcommand. See the ticket for the six verified cases.

---

## 8. Architecture constraints

### 8.1 Testability — resolved (DN-006, in-review)

`DNNetworkManager` takes an `HttpClientEngine` through an `internal` constructor (tests use Ktor's
`MockEngine`), and the singleton is gone — instances are constructed at the platform edge and are
fully independent. The suite (89 tests, both platforms) runs via `./gradlew :sharedLogic:check`.
The constraint going forward: **do not reintroduce a singleton** — CODEBASE-ARCHITECTURE §6.

### 8.2 Don't publish DTOs as the public API — pattern established (DN-004/DN-008)

The nullable-everything scaffolding DTO was deleted (DN-004), and the first real slice (DN-008)
set the pattern to repeat: DTOs `internal` with nullability matching the contract, domain models
public, mappers between them, `explicitApi()` enforcing it all. Every next endpoint follows it.

### 8.3 Typed errors — done on the network path (DN-008)

The repository maps every exception into sealed `DNError` cases; nothing throws past it, and Swift
gets an exhaustive `switch` — SKIE's highest-leverage feature, now in use. Still pending: the
storage classes rethrow bare `Exception`; align them when they gain real consumers.

### 8.4 DI shape is already decided by the code

`expect class PreferenceStorage` has different constructors per platform — Android's actual takes
a `Context`, iOS's takes nothing. **commonMain can therefore never construct one.** Any repository
in commonMain must take it as a constructor parameter injected from the platform edge. Same for
`SecureStorage`.

This is not a choice to be made later; it is already true.

### 8.5 Smaller shape issues

- ~~`baseUrl` actually holds a *full endpoint path*~~ **Resolved (DN-008).** It is now a genuine
  base URL; each endpoint appends its own path.
- Android target parity is compiler-enforced: `androidLibrary` is a declared target, so an
  `expect` without an `androidMain` actual will not compile. Library-level Android parity is not
  optional — only the Android *app* is deferred.

---

## 9. Known drift

Observed and verified. Recorded so it isn't rediscovered.

**These are candidate technical tickets.** As a list in a document, nothing acts on them; as
tickets they become schedulable work with a `## Rationale` each. Items 1–5 and 8 are resolved;
6 is ticketed (DN-006), 7 is addressed going forward by DN-005, and 9 waits on a remote being
created for the app repo.

1. ~~**DapurNaura is wired to the local package.**~~ **Resolved (DN-003).** The app now has **no
   package dependency at all** — `packageReferences` and every `packageProductDependencies` list
   are empty, and the orphan product dependencies are gone. It builds standalone. Re-adding
   DNLibrary is the first step of the next data-layer ticket, under the rule in §7.
2. ~~**`Package.resolved` is deleted.**~~ **Moot.** There is no dependency to resolve. The file
   returns with the remote dependency and must be committed then.
3. ~~**Three `DNLibrary` product dependencies.**~~ **Resolved (DN-003).** All removed. If
   `Missing package product 'DNLibrary'` reappears, the cause is a product dependency without a
   matching package reference — Xcode adds a *new* one rather than reusing an existing one.
4. ~~**`DapurNaura` has uncommitted changes.**~~ **Resolved.** Committed as `DN-003` on
   `ticket/DN-003-ios-build-variants`.
5. ~~**The API key is hardcoded and committed.**~~ **Resolved (DN-003).** The key was scrubbed from
   history, and configuration now comes from gitignored `Config/Secrets.xcconfig` via Info.plist
   substitution. ⚠️ Anything in Info.plist still ships readable inside the `.ipa` — gitignoring
   keeps keys out of git, it does not make them secret.
6. ~~**Zero tests.**~~ **Resolved (DN-001/002/006/008).** **89 tests** across `commonTest`,
   `androidHostTest` and `iosTest` — 45 Android host, 44 iOS simulator, 0 failures;
   `./gradlew :sharedLogic:check` green on both platforms. The Keychain cases are `@Ignore`d — the
   hostless iOS test process has no keychain.
7. **No link between a DNLibrary commit and an SPM tag** — for the *existing* tags. **DN-005**
   (in-review) fixes this going forward: every new release stamps its source commit SHA into the
   release notes. The historical tags `1.0.0`–`1.4.0` stay unlinked and are already slated for
   deletion (§7).
8. ~~**SPMDNLibrary tracks a `.DS_Store`**~~ **Resolved (DN-005).** Untracked in `e6c6dec`, so the
   publish preflight's clean-tree check can now pass.
9. ~~**`DapurNaura` has no git remote.**~~ **Resolved.** It is
   `github.com/Fostahh/DapurNaura-iOS`, and its ticket branches are pushed.
10. **`SPMDNLibrary` cannot resolve as a package.** Verified 2026-08-06: the repository has **no
    tags** and **no releases**, and the binary-target URL in its `Package.swift` returns 404. SPM
    resolves a version requirement by git tag, so there is nothing to match. Harmless today — the app
    has only ever built against `ios/DNLibraryLocal` and has never pinned a remote version — and the
    first `publish-spm.sh publish` rewrites the manifest, creates the tag and creates the release,
    fixing all three at once. No separate ticket; recorded in that repository's README.

---

## 10. Recommended next moves

1. ~~**Settle the JSON contract for `CookingClass` and `Recipe`.**~~ **Done.** Approved v1 lives
   in [contracts/](contracts/) as of 2026-08-06.
2. ~~**DN-004 — delete the scaffolding DTO and endpoint.**~~ **Done.**
3. ~~**DN-006 — the engine seam.**~~ **Done**, along with DN-002 and the domain modelling that was
   blocked behind them.
4. **Run the release half of the loop, which has still never executed.** Requirement → branch →
   test → app → review → commit has now run many times. **Publish → tag → release → bump never
   has**, and DN-016 is the first ticket that cannot reach `done` without it. Until it runs, the
   whole distribution channel is unproven — see known issue 10.
5. **Merge something.** 27 commits sit across three stacks with nothing on any `main`, and stack
   depth is now the largest single risk in the workspace: every additional ticket makes the eventual
   merge harder, and a conflict found at depth 8 is far more expensive than one found at depth 2.
6. **Ticket the recipe screen.** Its requirement has been approved and unticketed since 2026-08-06.
   It is the level of the domain the product actually sells, and it is the only approved requirement
   with no ticket behind it.
5. ~~**Write the first requirement document.**~~ **Done (2026-08-06).**
   [`requirements/2026-08-06-cooking-class-detail.md`](requirements/2026-08-06-cooking-class-detail.md)
   was drafted from the owner's verbal description, revised across four rounds of questions, and
   approved — the first document to exercise the `product` path end to end. **DN-011** (data) and
   **DN-012** (iOS) are the first tickets whose `source:` is a real link rather than a flagged
   deviation. The still-open piece is backfilling documents for DN-008 and DN-009.
