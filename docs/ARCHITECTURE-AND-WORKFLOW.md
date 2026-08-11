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

**This section describes shape, not status.** For which tickets are `done`, which library version is
published and what is in flight, read [`tickets/README.md`](tickets/README.md) and `git log` — a
hand-maintained status paragraph is stale within a day of the next merge, which is what DN-029 was
filed to stop.

**The data layer covers all three levels of the domain.** `CookingClass`, `CookingClassCategory`,
`CookingClassDetail`, `RecipeSummary`, `Recipe`, `RecipeComponent`, `Ingredient`, `RecipeStep`,
`PurchaseStatus` and `DNError` are modelled against the approved contract, reached through
`GetCookingClassesUseCase`, `GetCookingClassDetailUseCase` and `GetRecipeUseCase`, all entered
through `DNDataLayer`. `DNFormat` and `DNError.userMessage` render prices, category labels and
failure wording for every platform. The suite runs on both platforms and
`./gradlew :sharedLogic:check` is the gate.

**A recipe is a list of components**, each carrying its own ingredients *and* its own method — the
owner's reason being that a student prepares each component in its own bowl. The approved requirement
describes a flatter shape and is wrong about it; it carries `corrected-by:` pointers and its prose is
deliberately untouched.

**The iOS app renders all three levels** — the class list with its category filter, the class detail,
and the recipe screen the product actually sells — on `@Observable` MVVM over an owned navigation
path, with SwiftLint reporting zero violations.

**Three things the domain assumes and nothing provides:**

- **No backend.** Everything runs on `DNDataLayer.stub()`, which replays the approved contract
  fixtures through the real decoding path. The wire shape has never met a server.
- **No signed-in user**, although `purchaseStatus` is per-user data by definition. There is a login
  screen (DN-040) and **it authenticates nobody** — any email and any password get in, and the only
  gate is that both boxes are filled. Behind it there is no session, no user model and nowhere to
  keep a token. Deferred by the owner on 2026-08-06, to be ticketed later.
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
                  Agent pushes ticket/* and opens the PR (DN-022)
                       ↓
                  Human merges into `development`, and tells the agent it merged
                       ↓
                  Agent marks the ticket done — on the human's word, never inferred
                       ↓
                  Release step (see §7) — human-triggered, agent runs it end to end
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
| `done` | PR merged | Agent — **only once the human says the PR is approved and merged** (DN-022) |

**`done` is the human's decision, set by the agent's hand.** The agent never infers it from a green
PR page or from the merge appearing on GitHub; the owner saying so is what authorises it.

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
- Committing; pushing anything other than a `ticket/*` branch; merging anything
- **Initiating** `publish-spm.sh` in **`publish`** mode, a tag, or a GitHub release — the agent never
  decides that a release should happen. Once the human instructs it, the agent runs the publish end
  to end, derives the version, and repins the app (§7)
- Declaring a ticket `done` on its own judgement — the human's word is what authorises it (§4)

### Never

- Edit the **prose** of a file in `docs/requirements/` once it is `status: approved`. The single
  permitted edit is a `corrected-by:` frontmatter pointer naming the ticket that carries the
  correction — owner's decision 2026-08-07, see [`requirements/README.md`](requirements/README.md).
  That is metadata; the prose is never touched, not even to remove an `[ASSUMPTION]` that proved false
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
- **It builds.** `xcodebuild … build` succeeds — see *The iOS build gate* below (DN-034)
- `swiftlint lint` reports no violations
- **Verified manually by the human**, on the running app

**[OPEN]** UI testing on both platforms is wanted eventually; no date set.

#### The iOS build gate **[DECIDED]** — DN-034

**Owner's rule, 2026-08-09: any change to the iOS project is built before it is offered for
review.** Build only — no simulator run, no install, no launch.

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=<simulator-uuid>' build
```

`** BUILD SUCCEEDED **` or the work is not finished. A failing build is fixed, not reported as a
caveat beside the diff.

**Pass the simulator's id**, from `xcrun simctl list devices available` — never a bare device name
and never the generic destination. The XCFramework has no x86_64 slice and several runtimes publish
one device name for two architectures; both traps are known issue 2 in `ios/DapurNaura/CLAUDE.md`.

**There is no automated *test* gate on the UI — that is not the same as no automated gate**, and the
distinction is the whole point of this rule. SwiftLint checks shape and compiles nothing, so before
DN-034 the strongest thing an agent could say about iOS work was *"0 violations"* — a sentence
equally true of code that does not build. **It does not replace the human's verification of the
running app.** The agent proves it compiles; the owner proves it behaves.

### The documentation gate **[DECIDED]** — DN-042

**Applies to every layer above, not to `docs` tickets alone.** Owner's instruction, 2026-08-11, given
twice in one day: *"you need synchronize all of the .md before commit and push."*

> **A ticket is not finished until the documents match what it did.** Before offering work for
> review, **enumerate** every tracked `.md` in every repository the ticket touched —
> `git ls-files '*.md'` — and read the ones that could state a fact the ticket changed. Correct what
> is now false.

**Requirement documents and `done` tickets are excluded and are never edited.** Both record what was
true when they were written; a correction goes in the *current* ticket. That rule is older than this
gate and this gate does not weaken it.

Three rules the sweep itself follows, all learned in DN-041:

- **Enumerate, then read. Never grep and call it a sweep.** A search finds the sentence you already
  knew was wrong. `ios/DapurNaura/README.md` was missed entirely because nobody had thought of it —
  it had been telling readers to build with a bare simulator name, the exact thing that repository's
  own known issue 2 says fails, since DN-034.
- **Leaving a correct sentence alone is part of the job.** `AGENT-PLAYBOOK.md` carries a screen count
  inside an explicitly labelled historical snapshot; rewriting it would destroy the evidence it
  exists to preserve. A document that is merely *old* is not wrong.
- **Do not write a count, a status or a version into prose.** Those are facts with no owner: nothing
  forces anyone to update them, so they go stale between one merge and the next. Name the ticket and
  let the derived index carry the state.

**Why a gate rather than a reminder.** This is DN-034's argument repeated. The agent could always
have run `xcodebuild`, and did not, until the Definition of Done said the work was unfinished without
it. Documentation was in that position: `README.md` claimed the recipe screen was a placeholder for
four merged product tickets, and `ios/DapurNaura/CLAUDE.md` miscounted the screens across three.
Every one shipped through a review, a PR and a merge — **nobody was careless; there was no step at
which anyone was asked.**

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
| `main` | **Frozen until `1.0.0`.** Receives `development` once, at the App Store release. No direct changes. |

**[DECIDED] `main` is the standard name** across every repository — DNLibrary and SPMDNLibrary
were renamed from `master`. `development` exists in all four repos.

**`main` is frozen, not merely protected.** Releases are cut from `development` (DN-023), and
`main` holds each repository's pre-workspace state until the app reaches `1.0.0`. On
`ios/DapurNaura` that is a single stock-template `Initial Commit` — none of the app is there.

~~**[OPEN]** The renames and the new branches are local only.~~ **Resolved.** All four repositories
have `origin/main` and `origin/development`; every ticket branch since DN-001 has been pushed and
merged through a PR.

### Versioning **[DECIDED]**

Three independent numbers. **They are not related and must not be made to match.**

| Number | Where | Read by |
|---|---|---|
| **Library version** | SPMDNLibrary git tags | The SPM resolver — a machine with semver semantics built in |
| **App version** | `MARKETING_VERSION` | Humans, in the App Store |
| **Build number** | `CURRENT_PROJECT_VERSION` | App Store Connect; must strictly increase |

**The scheme, settled with the owner on 2026-08-07.** The first release is **`0.1.0`** — not
`0.0.1`, which reads as "nothing works yet" and wastes the only patch slot on a release already
containing two tickets. Then `0.MINOR.PATCH`:

- **MINOR** — any public API change, additive or breaking
- **PATCH** — a behaviour fix with no API movement

**A removed public symbol is a minor, not a major, for the whole of `0.x`** — `0.x` makes no
compatibility promise, and DN-004, DN-006 and DN-008 each removed public symbols and each shipped as
a minor. **`1.0.0` is reserved for the App Store release** and must not be used before it.

**What changed in a version belongs in the release notes, not in the number.**

**The agent picks the number, the human picks the moment.** Every ticket declares its bump in
*Public API contract* → *"Version bump implied"*, so the next version is **derived from the tickets
merged since the last tag**, never invented at publish time. If those declarations disagree with the
diff, the diff wins and the ticket is corrected.

~~**[OPEN]** The existing tags `1.0.0`–`1.4.0` predate this workflow.~~ **Resolved.** No `1.x` tag
exists in `SPMDNLibrary`; its tags are `0.1.0`–`0.6.0` and nothing needs deleting. A legacy commit
on `main` still carries the subject *"Release 1.4.0"*, which is history, not a tag.

### The iOS dependency **[DECIDED]**

**[DECIDED — DN-030, 2026-08-09]** The app depends on SPMDNLibrary by **range**:

```
kind = upToNextMajorVersion;
minimumVersion = 0.6.0;        →  >= 0.6.0, < 1.0.0
```

**This supersedes the exact pin introduced by DN-022.** The reason is the release flow, not
semantics: an exact pin makes every release require a hand-edit of `project.pbxproj`, and that edit
is the step that nearly collided on 2026-08-09 when the owner resolved the project by hand in the
three minutes between the `0.6.0` release and its repin. Under a range, *Update to Latest Package
Versions* is the entire repin and the project file never changes.

It also restores the original design — this section read *"by version range (`.upToNextMajor`), not
an exact pin"* until DN-029 corrected it against the code, which by then had moved to an exact pin.

**Therefore `Package.resolved` must be committed** — and under a range it carries more weight than
it did before, not less. With an exact pin the version also sat in `project.pbxproj`, so resolution
was deterministic either way. With a range, `Package.resolved` is the **only** thing that makes a
build reproducible: without it, two people building the same commit can resolve different library
versions.

**Two properties of the choice worth knowing.** SPM does not special-case `0.x` as npm and Cargo do,
so `upToNextMajor` from a `0.x` floor means `< 1.0.0` rather than `< 0.7.0` — the range asked for.
And because it stops below `1.0.0`, the rule *"`1.0.0` is reserved for the App Store release"* is
enforced by the resolver instead of by memory.

**The cost, recorded rather than glossed.** DN-004, DN-006 and DN-008 each removed public symbols;
under a range such a release breaks the build when someone presses *Update*, instead of at a version
bump they chose. Every release since `0.4.0` has been additive, and the break would be loud and
deliberately triggered. Judged worth it against friction charged on every single release.

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
| 7 | Push `ticket/*`; open the PR (DN-022) | agent |
| 8 | PR merged into `development`; tell the agent it merged | **human** |
| 9 | Mark the ticket `done`, on that word | agent |
| 10 | Authorise the release | **human** |
| 11 | `publish-spm.sh publish` from `development` — tag + GitHub release (DN-023) | agent |
| 12 | Repin the app to the new version, resolve, build, commit — **part of step 11, not a later step** | agent |

**Steps 1–4 are one loop with one gate.** Nothing merges, publishes, or waits in the middle. That
is the point of the change — the human is asked to approve once, on something that demonstrably
runs, not twice on partial state.

**Step 12 cannot move earlier, and must not move later.** The tag does not exist until step 11, so
the app cannot reference the version before then — the bump is always a separate, tiny commit after
the release. But it is part of the same instruction: **a publish is finished when the app is
repinned, not when the release appears** (owner's rule, 2026-08-09). The agent runs straight on from
`gh release create` to the bump, and does not report the release as done first. On 2026-08-09 a
two-minute gap was long enough for the owner to open Xcode and resolve the project by hand; two
people editing one `Package.resolved` is how a conflict starts.

Until step 12 lands, the app's committed state names the *previous* version and does not compile —
expected, and covered by the local package rule above.

~~**[OPEN] Publish cadence.**~~ **Answered by practice.** Six releases, `0.1.0`–`0.6.0`, have each
carried one ticket or one paired ticket stack, cut from `development`. Versions have not run away —
the API changes at roughly the rate the domain does. A ticket can still reach `done` before its code
is published, which is correct: `done` tracks the PR, the tag tracks the binary.

### Publish preflight — fixed by DN-005 **[RESOLVED]**

`publish-spm.sh` used to validate only **SPMDNLibrary's** working tree — a release binary could be
built from uncommitted DNLibrary code on any branch, tagged and published, with nothing recording
where it came from.

**DN-005** fixed it: publishing refuses a dirty, non-release-branch or unpushed DNLibrary tree,
stamps the source commit SHA into the release notes, and adds a `preflight` subcommand. See the
ticket for the six verified cases.

**DN-027 closed what those checks could not see.** A clean tree, an allowed branch and a HEAD
contained in some remote branch are all still true of a checkout that is four commits behind — which
is how `0.5.0` was published onto a stale base on 2026-08-08, its branch push rejected as a
non-fast-forward while `--tags` pushed the tag anyway, leaving a published tag on a commit no branch
contained. Two changes:

- **Both repositories are checked for staleness** before a publish — `DNLibrary` and
  `ios/SPMDNLibrary`. The script refuses and names `git pull --ff-only`; it never pulls for you,
  because that would change what is being released after the plan has been read.
- **The release commit and its tag are pushed as two ordered steps.** A failed branch push aborts
  before the remote is tagged. **A tag can therefore only exist after its commit does** —
  unreachable by construction, not merely unlikely, and it holds even if the preflight is skipped.

---

## 8. Architecture constraints

### 8.1 Testability — resolved (DN-006)

`DNNetworkManager` takes an `HttpClientEngine` through an `internal` constructor (tests use Ktor's
`MockEngine`), and the singleton is gone — instances are constructed at the platform edge and are
fully independent. The suite runs on both platforms via `./gradlew :sharedLogic:check`.
The constraint going forward: **do not reintroduce a singleton** — CODEBASE-ARCHITECTURE §6.

### 8.2 Don't publish DTOs as the public API — pattern established (DN-004/DN-008)

The nullable-everything scaffolding DTO was deleted (DN-004), and the first real slice (DN-008)
set the pattern to repeat: DTOs `internal` with nullability matching the contract, domain models
public, mappers between them, `explicitApi()` enforcing it all. Every next endpoint follows it.

### 8.3 Typed errors — done on the network path (DN-008)

The repository maps every exception into sealed `DNError` cases; nothing throws past it, and Swift
gets an exhaustive `switch` — SKIE's highest-leverage feature, now in use. Still pending: the
storage classes rethrow bare `Exception`; align them when they gain real consumers.

### 8.4 DI shape — decided, and it binds the next `expect`/`actual`

When an `expect`/`actual` pair has different constructors per platform — say a `Context` on Android
and nothing on iOS — **commonMain can never construct one.** Any repository in commonMain must take
it as a constructor parameter injected from the platform edge.

**No such pair exists today**: the only two, `SecureStorage` and `PreferenceStorage`, were deleted by
DN-031. So this is not a description of current code — it is the constraint on whoever adds the next
one, and it must be designed for from the first line rather than discovered when the compiler
refuses.

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
tickets they become schedulable work with a `## Rationale` each. **Items 1–10 are all resolved** —
the list is kept so the findings are not rediscovered, and because the resolutions record why each
mattered. What remains open is tracked as tickets, not here.

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
6. ~~**Zero tests.**~~ **Resolved (DN-001/002/006/008, extended since).** Every test lives in
   `commonTest` and runs on both platforms — DN-031 removed the only platform-specific source sets
   along with the POC storage they tested. The suite grows with each data-layer ticket;
   `./gradlew :sharedLogic:check` is green on both platforms and is the gate. The Keychain cases are
   `@Ignore`d — the hostless iOS test process has no keychain. **The count lives in the test-result
   XML, not in this document** — read it from a run, since a number written here is stale on the
   next ticket.
7. ~~**No link between a DNLibrary commit and an SPM tag.**~~ **Resolved (DN-005).** Every release
   stamps its source commit SHA and branch into the release notes, and all six published releases
   carry it. The historical `1.x` tags this item worried about turned out not to exist.
8. ~~**SPMDNLibrary tracks a `.DS_Store`**~~ **Resolved (DN-005).** Untracked in `e6c6dec`, so the
   publish preflight's clean-tree check can now pass.
9. ~~**`DapurNaura` has no git remote.**~~ **Resolved.** It is
   `github.com/Fostahh/DapurNaura-iOS`, and its ticket branches are pushed.
10. ~~**`SPMDNLibrary` cannot resolve as a package** — no tags, no releases, manifest URL 404s.~~
    **Resolved 2026-08-08 by the first publish**, exactly as predicted: `publish-spm.sh publish`
    rewrote the manifest, created the tag and created the release in one run. The repository now
    carries tags `0.1.0`–`0.6.0` with a matching release and asset behind each, and the app resolves
    against it.
11. ~~**A published tag could be orphaned by a partial push.**~~ **Resolved (DN-027).** It happened
    to `0.5.0` on 2026-08-08 before it was understood; the repair needed a tag and release deletion,
    both on the `Never` list and authorised once. The push is now ordered and checked, and both
    repositories are checked for staleness first — see §7.

---

## 10. Recommended next moves

1. ~~**Settle the JSON contract for `CookingClass` and `Recipe`.**~~ **Done.** Approved v1 lives
   in [contracts/](contracts/) as of 2026-08-06.
2. ~~**DN-004 — delete the scaffolding DTO and endpoint.**~~ **Done.**
3. ~~**DN-006 — the engine seam.**~~ **Done**, along with DN-002 and the domain modelling that was
   blocked behind them.
4. ~~**Run the release half of the loop, which has never executed.**~~ **Done.** It has now run six
   times, `0.1.0` through `0.6.0`, and the distribution channel is proven end to end: publish → tag
   → release → repin. The two defects it exposed on the way are ticketed and fixed — DN-023 (the
   branch rule) and DN-027 (the stale base and the partial push).
5. ~~**Merge something.**~~ **Done 2026-08-08.** Twenty-seven PRs are merged across the three project
   repos, each with a merge commit, and nothing is stacked. Stack depth is no longer a risk in this
   workspace.
6. ~~**Ticket the recipe screen.**~~ **Done — DN-020 (data) and DN-021 (iOS), both merged.** It is
   also the first stack whose `source:` points at a requirement known to be partly wrong; the
   correction lives in the tickets and in `contracts/recipe.json`, and the requirement's prose is
   untouched.
7. ~~**Write the first requirement document.**~~ **Done (2026-08-06).**
   [`requirements/2026-08-06-cooking-class-detail.md`](requirements/2026-08-06-cooking-class-detail.md)
   was drafted from the owner's verbal description, revised across four rounds of questions, and
   approved — the first document to exercise the `product` path end to end. **DN-011** (data) and
   **DN-012** (iOS) are the first tickets whose `source:` is a real link rather than a flagged
   deviation.

**What is actually still open**, as tickets rather than prose:

- **No CI runs the data-layer gate** — `:sharedLogic:check` is run by the agent and attested by the
  agent in its own PR body. **Deferred by the owner on 2026-08-09** and deliberately left unticketed;
  the compensating control is that the owner reviews every diff. Recorded here so the gap is not
  rediscovered, **not as a standing proposal.**
- **DN-026** — status labels still live in Swift rather than the shared layer.
- **Backfill requirement documents for DN-008 and DN-009**, which trace to verbal instructions.
- **The two deferred domain gaps** — no signed-in user and no purchase path — both the owner's
  explicit decision of 2026-08-06, to be ticketed when they are wanted. DN-040's login screen is the
  visible half of the first one and closes none of it.
