# Tickets

One file per ticket, named `DN-XXX-<type>-<short-slug>.md` — the type is in the filename so the
kind of work is visible without opening anything:

```
DN-001-technical-secure-storage-encryption.md
DN-005-product-cooking-class-list.md
```

The id comes first so files still sort in creation order, which matters because that id is the
thread linking commits across repositories. **Branch names stay `ticket/DN-XXX-short-slug`** —
without the type, since the id already identifies the ticket and branches get typed by hand.

This index is regenerated as tickets change — it is derived, so if it drifts from the files, the
files win.

Lifecycle, autonomy rules and the Definition of Done live in
[../ARCHITECTURE-AND-WORKFLOW.md](../ARCHITECTURE-AND-WORKFLOW.md) §4–§6.

---

> **Source of truth.** For *what was asked for*, `../requirements/` wins — over the code, over any other
> document, over a commit message. Where no requirement exists, **the ticket is the source of truth**
> and its `## Rationale` carries the why.
>
> This governs **intent**, not facts. For *what the code does today*, believe the code. When intent
> and implementation disagree, the implementation is what is wrong: record the correction in the
> **ticket**, never by editing the requirement.

## Two kinds of ticket

| | **Product** | **Technical** |
|---|---|---|
| Origin | A requirement document you wrote | A problem you or the agent noticed |
| `source:` | Required — points at `docs/requirements/` | Omitted; there is no document |
| First section | `## Requirement (traced)` — quoted from the doc | `## Rationale` — the argument, written here |
| "Why does this exist?" | Open the requirement document | It is in the ticket |

Everything else — technical approach, API contract, test plan, done-when — is identical.

A **product** ticket delivers something a user asked for. A **technical** ticket changes code
nobody asked about: testability, architecture, tooling, debt. Nobody writes a requirement document
saying "make the HTTP engine injectable," so without this split such work cannot be ticketed at
all.

**Classify by where the justification comes from, not by subject matter.** "Add offline caching"
is a product ticket if a user asked for offline access, and a technical ticket if you decided the
architecture needs it.

> **Keep the categories to two.** Add a new one only when the *process* differs — different gates,
> different traceability — never because the *topic* differs. A bug in a feature is a product
> ticket.

**One number sequence.** `DN-001`, `DN-002`, … regardless of type. Not `DNP-`/`DNT-`. One counter,
nothing to renumber if a ticket is reclassified, and commit messages stay uniform (`DN-004: …`) —
which matters, because that id is the only thing linking work across the separate repos.

---

## Index

### Product

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-008](DN-008-product-cooking-class-list.md) | Data layer — fetch the list of cooking classes | `done` | data |
| [DN-009](DN-009-product-cooking-class-list-ui.md) | iOS — cooking-class list screen (SwiftUI + MVVM) on GET /classes | `done` | both |
| [DN-011](DN-011-product-cooking-class-detail-data.md) | Data layer — fetch one cooking class with its recipes | `done` | data |
| [DN-012](DN-012-product-cooking-class-detail-ui.md) | iOS — cooking-class detail screen, status-driven buy button and recipe tappability | `done` | ui |
| [DN-020](DN-020-product-recipe-detail-data.md) | Data layer — fetch one recipe in full, as a list of components | `done` | data |
| [DN-021](DN-021-product-recipe-detail-ui.md) | iOS — the recipe screen, replacing the placeholder | `done` | ui |
| [DN-024](DN-024-product-cooking-class-category.md) | Data layer — class category, and filtering GET /classes by it | `done` | data |
| [DN-025](DN-025-product-cooking-class-category-filter-ui.md) | iOS — category filter chips on the cooking-class list | `done` | ui |
| [DN-033](DN-033-product-cooking-class-selection-entry.md) | iOS — open on a choice between Kelas Online and Kelas Offline, with a reusable "not built yet" sheet | `done` | ui |
| [DN-035](DN-035-product-offline-class-schedule-data.md) | Data layer — the offline class schedule, its date window and its availability rule | `done` | data |
| [DN-036](DN-036-product-offline-class-schedule-ui.md) | iOS — the offline class schedule, with collapsible month sections and a materials sheet | `done` | ui |
| [DN-040](DN-040-product-login-screen.md) | iOS — the login screen, a reusable toast, and a hex colour palette | `done` | ui |
| [DN-047](DN-047-product-payment-destinations-data.md) | Data layer — the bank accounts a class is paid into | `done` | data |
| [DN-048](DN-048-product-payment-flow-ui.md) | iOS — choosing a bank account and sending proof of payment | `done` | ui |

DN-008 and DN-009 trace to **verbal** instructions from the owner (2026-08-06) — the requirement
documents are deliberately deferred and should be backfilled when the requirements path is
exercised. DN-009's UI was verified by the owner on the running app before its commit, per the
platform's UI gate.

**DN-011 and DN-012 are the first tickets to trace to a real requirement document** —
[`../requirements/2026-08-06-cooking-class-detail.md`](../requirements/2026-08-06-cooking-class-detail.md),
approved 2026-08-06 — so their `source:` is a genuine link rather than a flagged deviation. They are
ordered: **DN-011 landed before DN-012**, which needed its use case and its stub replay. Both are
`done` — merged 2026-08-08.

**DN-020 and DN-021 are the recipe screen — the level of the domain the product actually sells.**
Both are `done`, delivered 2026-08-07 and merged 2026-08-08. **103 data-layer tests passed** at that point (up from 89 — DN-024 has since taken it to 117) and
`swiftlint lint` reports **0 violations**, with every row of the iOS known-violations table now
struck — the last one, `RecipePlaceholderView`'s §3 exemption, died with the file DN-021 deleted. They are the first tickets whose
`source:` points at a requirement **known to be partly wrong**: the approved document describes
ingredients as a flat list with group labels, and the first real recipe proved a recipe is a list of
**components**, each with its own ingredients *and* its own method.

That is safe only because of what DN-019 put in place. The requirement carries
`corrected-by: DN-019, DN-020, DN-021` in its frontmatter, its prose is untouched, the corrected
shape lives in `docs/contracts/recipe.json`, and **both tickets carry the correction inside
`## Requirement (traced)`** — before the quote it modifies, not buried in an implementation note.

**DN-024 and DN-025 are the category filter**, from
[`../requirements/2026-08-08-cooking-class-category-filter.md`](../requirements/2026-08-08-cooking-class-category-filter.md)
— the first requirement drafted, corrected and approved inside a single session. Two things about them
are worth knowing before reading either ticket:

- **The owner corrected the third category from `Decor` to `COOKING` minutes after asking**, and both
  statements are preserved in the requirement. The correction is part of the record, not a reason to
  rewrite it.
- **The filtering is done by the server** (`GET /classes?category=`), by the owner's choice over
  client-side narrowing. That is why a UI ticket needed a data-layer ticket underneath it, and why the
  stub had to start filtering: with no backend, the stub *is* the server.

**DN-033 changes what the app opens on**, from
[`../requirements/2026-08-09-cooking-class-selection-entry.md`](../requirements/2026-08-09-cooking-class-selection-entry.md).
Two things about it are worth knowing before reading it:

- **It is the first screen that fetches nothing.** Every screen before it renders a `DNDataLayer`
  call, and two rules in `CODEBASE-ARCHITECTURE.md` are written for that shape and do not apply — no
  ViewModel and no three-state switch. The ticket records why rather than leaving it to be
  re-argued at review.
- **It takes no data-layer work at all** — no use case, no publish, no version bump, no repin. The
  first product ticket to go straight to `ios/DapurNaura/`.

**DN-035 and DN-036 are the offline classes**, from
[`../requirements/2026-08-09-offline-class-schedule.md`](../requirements/2026-08-09-offline-class-schedule.md)
— the other half of the choice DN-033 introduced, and the first product work that is not about
recipes. Three things are worth knowing before reading either:

- **DN-035 is the first ticket to add a dependency to the data layer** (`kotlinx-datetime`) and the
  first to put a third-party type in the public API. The window rule needs real calendar arithmetic,
  and hand-rolling month boundaries in a library shipping to two platforms is the wrong trade.
- **The clock is injected.** A use case reading the system date can only be tested on the day the
  test happens to run — *"30 September is inside the window"* is true in August and false in October.
  It is the same seam DN-006 cut for the HTTP engine, for the same reason.
- **The availability state is derived from the remaining quota, never stored**, and the quota itself
  is never rendered. The rule and the number stay in the library; the screen only ever sees the state.

**Merge [DNLibrary#19](https://github.com/Fostahh/DNLibrary/pull/19) before
[DapurNaura-iOS#15](https://github.com/Fostahh/DapurNaura-iOS/pull/15)**, and publish `0.8.0` in
between — the iOS branch calls API that no published version carries, so it does not compile against
the pinned range until the follow-up repin. That is the local package rule working as designed.

~~**Both are blocked on the release path.**~~ **Cleared 2026-08-10** — the owner made `SPMDNLibrary`
public again, `0.8.0` was released and the app repinned. That repin is what produced DN-037.

**DN-040 is the login screen**, from
[`../requirements/2026-08-10-login.md`](../requirements/2026-08-10-login.md) — the first requirement
drafted from an image rather than from spoken instructions. Four things are worth knowing before
reading it:

- **It authenticates nobody, by instruction** — *"a screen, no API call."* Any email and any password
  get in; the only gate is that both boxes are non-empty. The standing blocker of 2026-08-06 is
  untouched: still no session, no user, no token, no backend. The flag at the composition root is
  called `hasPassedLogin` rather than `isLoggedIn` precisely so nothing later mistakes it for one.
- **It runs behind DN-039**, which the owner scheduled first. This is the first screen built from
  fixed hex colours instead of adaptive system ones, so without the light-mode lock it renders
  white-on-white in dark mode.
- **It is the first screen in the app to take keyboard input.** Focus, field styling, autofill and
  keyboard avoidance have no precedent here.
- **The toast is reusable with three kinds and, at the time, one caller** — the same shape
  `NoticeSheet` took in DN-033, because the owner asked for reuse and named two kinds this screen
  cannot show. *DN-048 finally gave it the other two kinds.*

### Technical

| Id | Title | Status | Layer |
|---|---|---|---|
| [DN-001](DN-001-technical-secure-storage-encryption.md) | SecureStorage stores plaintext on Android | `done` | data |
| [DN-002](DN-002-technical-network-manager-hardening.md) | Harden DNNetworkManager — timeouts, strict JSON, hide internals | `done` | data |
| [DN-003](DN-003-technical-ios-build-variants.md) | iOS build variants — Development / Alpha / Beta / Release via xcconfig | `done` | ios |
| [DN-004](DN-004-technical-remove-scaffolding-dtos.md) | Delete the leftover scaffolding DTO and endpoint from DNLibrary | `done` | data |
| [DN-005](DN-005-technical-publish-preflight-provenance.md) | publish-spm.sh — validate the source repo and record release provenance | `done` | tooling |
| [DN-006](DN-006-technical-network-engine-seam.md) | Make DNNetworkManager testable — engine seam, no singleton | `done` | data |
| [DN-007](DN-007-technical-commit-msg-hook.md) | Enforce the DN-XXX commit-message convention with a commit-msg hook | `done` | tooling |
| [DN-010](DN-010-technical-bilingual-prompt-protocol.md) | Bilingual prompt protocol — English docs, confirm-before-work gate | `done` | docs |
| [DN-013](DN-013-technical-lower-deployment-target.md) | Lower IPHONEOS_DEPLOYMENT_TARGET from 26.2 to 17.0 everywhere | `done` | ios |
| [DN-014](DN-014-technical-ios-codebase-architecture.md) | Decide and document the iOS codebase architecture — CODEBASE-ARCHITECTURE.md | `done` | docs |
| [DN-015](DN-015-technical-apply-architecture-to-screens.md) | Bring the two existing screens up to CODEBASE-ARCHITECTURE | `done` | ui |
| [DN-016](DN-016-technical-move-formatters-to-library.md) | Move rupiah formatting and the Indonesian error vocabulary into DNLibrary | `done` | both |
| [DN-017](DN-017-technical-tidy-root-docs.md) | Move the standards documents out of the repository roots into docs/ | `done` | docs |
| [DN-018](DN-018-technical-per-repo-readme.md) | Give every repository a README, and settle on one name for the codebase document | `done` | docs |
| [DN-019](DN-019-technical-source-of-truth.md) | Settle where truth lives — hierarchy, requirement corrections, and the CLAUDE.md/playbook boundary | `done` | docs |
| [DN-022](DN-022-technical-agent-opens-prs.md) | Let the agent push ticket branches and open pull requests | `done` | docs |
| [DN-023](DN-023-technical-release-branch-topology.md) | publish-spm.sh refuses to release — its branch rule encodes the old topology | `done` | tooling |
| [DN-026](DN-026-technical-status-labels-in-swift.md) | PurchaseStatusBadge words a domain enum in Swift, which §10 sends to the library | `done` | ui |
| [DN-027](DN-027-technical-publish-atomic-tag-push.md) | publish-spm.sh can still orphan a tag — no staleness guard, and a non-atomic push | `done` | tooling |
| [DN-028](DN-028-technical-bootstrap-stale-facts.md) | bootstrap.sh — the umbrella never gets the hook, and three of its facts are stale | `done` | tooling |
| [DN-029](DN-029-technical-docs-match-reality.md) | The workspace documents describe a project that no longer exists | `done` | docs |
| [DN-030](DN-030-technical-range-pin-ios.md) | Pin SPMDNLibrary by range, not exactly — so a release needs no manual dependency edit | `done` | ios |
| [DN-031](DN-031-technical-remove-poc-local-storage.md) | Delete the POC local storage — four public types, zero consumers | `done` | data |
| [DN-032](DN-032-technical-repin-checklist-stale.md) | The repin checklist tells you to hand-edit project.pbxproj, which DN-030 made wrong | `done` | tooling |
| [DN-034](DN-034-technical-ios-build-gate.md) | Every iOS change must build before it is offered for review | `done` | docs |
| [DN-037](DN-037-technical-repin-verification.md) | A repin can silently land on the old version — verify the resolved version instead of trusting it | `done` | tooling |
| [DN-038](DN-038-technical-swiftui-review-fixes.md) | Dynamic Type and four view-level findings from the SwiftUI review | `done` | ui |
| [DN-039](DN-039-technical-light-mode-portrait-lock.md) | Lock the app to light mode and portrait — the owner believes both are already enforced, and neither is | `done` | ios |
| [DN-041](DN-041-technical-docs-login-drift.md) | The workspace documents say there is no login screen, and that the recipe screen is a placeholder | `done` | docs |
| [DN-042](DN-042-technical-documentation-gate.md) | The doc sweep is a list of remembered places rather than an enumeration, and it is not a gate | `done` | docs |
| [DN-043](DN-043-technical-root-view-transition.md) | The login transition never animates, because the flag it animates lives on an App rather than a View | `done` | ui |
| [DN-044](DN-044-technical-strip-prose-comments.md) | Strip prose comments, and restore Xcode's header template across every file | `done` | ios |
| [DN-045](DN-045-technical-done-without-a-pr.md) | A ticket with no PR can never be marked done, because the rule only names a merged PR | `done` | docs |
| [DN-046](DN-046-technical-camera-usage-description.md) | The app has no camera usage description, and opening the camera without one terminates it | `done` | ios |
| [DN-049](DN-049-technical-lift-exception-mapping.md) | The exception-to-DNError mapping is copied in three repositories, and the second copy said when to stop | `done` | data |
| [DN-050](DN-050-technical-mockoon-serves-the-app.md) | The app runs on a local Mockoon server instead of the in-library stub | `done` | data + ui |
| [DN-051](DN-051-product-recipe-progress-storage.md) | Remember which ingredients are ticked, and which page the cook was on, across app restarts | `in-review` | data |
| [DN-052](DN-052-product-cooking-flow-screen.md) | The cooking flow — three pages from ingredients to finished, entered from the recipe | `in-review` | ui |
| [DN-053](DN-053-product-recipe-video-and-timestamps.md) | Page 2/3 plays the recipe video, and tapping a step seeks it | `todo` | data + ui |

**DN-051, DN-052 and DN-053 are one feature and merge in that order.** They come from
[`2026-09-12-cooking-a-recipe.md`](../requirements/2026-09-12-cooking-a-recipe.md), approved the same
day. **DN-052 cannot start until DN-051 is merged** — the checklist reads and writes its ticks
through it — and **DN-053 replaces a placeholder DN-052 leaves** on page 2/3. Only DN-051 moves the
public API, so only it implies a version bump.

> **DN-051 and DN-052 were each used once before, on 2026-09-12, and reused.** Two tickets were filed
> and deleted the same day — DN-051 for a stale `SPMDNLibrary` README, DN-052 for removing a loopback
> exception that was reverted instead. Both deletions and their reasoning are recorded in **DN-050**,
> and **DN-050 still refers to the numbers as they meant them then.** The numbers were reused rather
> than left as gaps, on the owner's instruction, so the sequence has no holes.
>
> **What this costs, stated so nobody is caught by it:** `git log -- docs/tickets/DN-051*` shows a
> file created and deleted whose content has nothing to do with the DN-051 that exists now. The
> deleted ones never merged as work — they were filed and withdrawn — so nothing built or shipped
> under either number.

**DN-027 to DN-029 come from a rule-compliance audit on 2026-08-09**, which checked every documented
rule against 27 merged PRs, 6 releases and four repositories. The finding worth carrying forward is
that **the rules held wherever they were encoded and drifted wherever they were prose** — the
commit-msg hook and `explicitApi()` have zero violations between them, while "pull before
publishing", "keep the status block current" and "no essay paragraphs in a PR body" each slipped.
They are ordered by what they can cost: DN-027 is the only hazard that had already fired.

**DN-030 is not an audit finding — it is a standard the owner set on 2026-08-09**, and it moves in
the opposite direction from the others: it *removes* a manual step rather than adding a guard. The
app now pins by range, so a release needs no edit to `project.pbxproj` at all. It supersedes the
exact pin DN-022 introduced, and in doing so restores what §7 originally specified.

**DN-031 removes the library's local storage**, and the reason it existed is the part worth keeping:
this repository began as a **POC to prove a KMP module could be exported as a library and consumed by
an iOS native project, locally and remotely**. `LocalDataSource` was the *local* half of that proof.
Nothing in the repository recorded that, so what a cold reader saw was encrypted, tested storage that
nothing calls — which reads as a forgotten integration rather than finished scaffolding. **There is
no requirement for local storage and the owner has deliberately not implemented it.** Do not
reintroduce it speculatively.

**DN-034 gives iOS work its first agent-side gate.** Owner's rule, 2026-08-09: every change to the
iOS project is built — build only, no simulator run — and `** BUILD SUCCEEDED **` or it is not
finished. It is documentation, not code, and it corrects a sentence in §6 that was being misread:
*"no automated gate"* meant no automated **test** gate, and was taken to mean the agent had nothing
it could check. SwiftLint compiles nothing, so *"0 violations"* was equally true of code that did not
build. **It shares DN-033's branch in both repos** — the rule arrived mid-ticket and DN-033 is its
first application; the commits are separate and each carries its own id.

**DN-037 is the second time the repin checklist has been behind reality**, after DN-032. Found while
repinning to `0.8.0` on 2026-08-10: the resolve landed on `0.7.0` and reported success, because the
cached SPM clone had never fetched the new tag. **When that happens `Package.resolved` does not
change at all**, so `git status` is clean — which reads as *nothing to do*, one short inference away
from DN-030's true statement that a repin needs no project edit.

What caught it was luck: `0.8.0` added API the new screen calls, so a stale `0.7.0` failed to
compile. A behaviour-only release has no such net and would ship green while never reaching anyone.
Scheduled by the owner the same day. **Its first run caught a mistake in itself** — it cleared three
caches, asked for `0.8.0` and resolved to `0.7.0`, because a *fourth* location nobody had recorded,
`DerivedData/SourcePackages/workspace-state.json`, also stores the resolved version. The script
would have shipped doing the wrong thing; the assertion it exists to perform is what stopped it.

**DN-039 is a belief checked against the code, and the code won.** The owner stated on 2026-08-10
that the app forces light mode and is portrait only. Neither was true: nothing sets a colour scheme
anywhere, and orientation was still Xcode's default — iPhone portrait plus both landscapes, iPad all
four. It survived unnoticed because every screen so far draws from **adaptive** system colours, so
all four look right in dark mode by construction rather than by decision. DN-040 is what ends that,
which is why the owner scheduled this ahead of it.

The fix has to go in the four app-target build configurations, and the two obvious homes both lose:
`Info.plist` is overwritten because Xcode merges its generated keys on top of it, and an xcconfig is
overridden because these keys are set at target level. `UIUserInterfaceStyle` is used rather than
`.preferredColorScheme(.light)` because the keyboard — which DN-040 introduces — lives outside the
SwiftUI view tree.

**DN-042 is why DN-041 was possible.** A doc sweep rule already existed — `AGENT-PLAYBOOK.md` §6 —
and it was followed badly because it is built so that following it badly is the path of least
resistance: a **table of remembered locations** rather than an instruction to enumerate, naming
`CLAUDE.md` files and **no READMEs**, with one path (`DNLibrary/CODEBASE-ARCHITECTURE.md`) left stale
by DN-017's move into `docs/`. The doc sweep section was itself a casualty of doc drift.

**The load-bearing fault was that it is not a gate.** The Definition of Done had never mentioned
documentation, so nothing made a ticket unfinished without it — while DN-034's build gate, one
section away, has not been skipped once since it was written. That contrast is the whole argument.
The gate now sits beside it, the playbook leads with `git ls-files '*.md'`, and all four
`## Done when` templates carry the line.

**DN-041 is DN-029's finding recurring, and the recurrence is the point.** DN-040 made one sentence
false in three documents — *"nothing anywhere carries identity: no login, no session, no user
model"* — inside the paragraph a cold session reads to learn what the app lacks. A reader who meets
that and then opens `Presentation/Login/` cannot tell which half is stale, and the natural inference
is the wrong one: that login works. Beside it sat two older drifts, `README.md`'s *"two screens run"*
and the iOS document's *"three screens exist"*, both wrong by four merged tickets.

The fix is not only the numbers. **The screen inventories now name tickets and give no count**,
because a count is a fact with no owner and nothing forces anyone to update it — which is precisely
what DN-029 concluded when it found the rules holding wherever they were encoded and drifting
wherever they were prose.

**DN-043 is a defect that passed every gate the project has.** The login transition DN-040 wrote has
never once run: `withAnimation` was wrapped around `@State` on an `App`, and the transaction does not
cross the `Scene` boundary into the `WindowGroup`'s content, so `.transition` degraded to an instant
cut. The code is correct — what was wrong is *where it lived*. The build compiled it, SwiftLint
passed it, the PR was reviewed and merged, and nothing in that chain inspects the difference between
a `View` and an `App`. Only running the app finds it, and a missing animation reads as a design
choice rather than a failure.

It carries a second change the owner scheduled with it: **the authentication screens become a flow
module** (`Presentation/Auth/`) owning their own `NavigationStack`, because onboarding, forgotten
passwords and registration are all expected to push within it. That establishes the rule the app will
grow by — **one `NavigationStack` per presentation context, flows composing by swap or by present and
never by nesting** — and the rule for where a path lives: on the router only if it must survive
something or be reached from outside the view that draws it. **Merge
[DapurNaura-iOS#21](https://github.com/Fostahh/DapurNaura-iOS/pull/21) (DN-041) first** — it is the
lower open id and corrects the same three documents.

**DN-044 strips the prose comments the agent had been accumulating** — roughly a third of every
non-component file, ~507 lines across 35 files, with `Components/` folders excluded on the owner's
instruction. It is safe for one structural reason worth stating: this project runs Document Driven
Development, so **every decision those comments restated already lives in the ticket that made it.**
The comments were a second copy nothing kept in sync, which is what DN-029, DN-041 and DN-042 were
each filed about. What is given up is proximity — the rationale no longer sits where the mistake gets
made — so the six load-bearing warnings are catalogued in the ticket alongside the rule that still
enforces each.

It carries a second instruction given the same day: **every file header returns to Xcode's creation
template.** Fifty-three of fifty-five had replaced the attribution line with a `DN-XXX — what this
file is` summary, which is the same failure one level up — a description written once that nothing
keeps true. Dates are each file's real creation date, recovered from history rather than invented.
**Headers were corrected inside `Components/` too**, since that exclusion was about comments.
**It must be committed after DN-043**, whose working tree it shares.

**DN-045 is DN-042's own closure failing.** DN-042 made the doc sweep a gate; it then sat at
`in-review` for a month with its work merged since `4755790`, because the rule that closes a ticket
names a **merged PR** and the umbrella takes none by policy. The condition could never be met, so the
ticket had no reachable end state — and a stuck ticket looks exactly like one still under review,
which is why 44 tickets passed before anyone asked.

Three earlier umbrella tickets missed it by luck: **DN-029** had a real PR back when the umbrella took
them, **DN-034** rode DN-033's iOS PR, and **DN-010** was closed with the box left unticked. The fix
is one clause in four places — where there is no PR, the owner confirming the merge closes it — plus a
`## Done when` variant so the next umbrella-only ticket writes a checklist it can finish. **The agent
gains no authority: the owner's word is still the trigger.**

**DN-046, DN-047 and DN-048 are the payment flow**, from
[`../requirements/2026-09-11-payment-flow.md`](../requirements/2026-09-11-payment-flow.md) — the
first work against the purchase gap the owner deferred on 2026-08-06, and the first requirement
drafted through a visual mockup before a word of it was written. Four things are worth knowing before
reading any of them:

- **Nothing is sent anywhere.** Owner's instruction: the send button makes no API call yet, it pops
  back. The class therefore still reads *Belum Dibeli* afterwards, and **the tickets forbid faking a
  status to hide that.** A toast tells the user their proof was taken; that is all.
- **The bank accounts live in DNLibrary, against the agent's recommendation.** The agent argued for
  Swift constants on §4's "no structure without a caller"; the owner overruled it because Android may
  come before the backend, and a Swift constant would then have to be written twice. **The owner's
  reasoning was better and DN-047 records why.**
- **Colour and logo stay in Swift** (DN-026's rule — a colour is view context), so the library models
  the bank as an enum rather than a display string. The consequence is stated rather than
  discovered: a third bank needs an app release either way, because its logo is an asset.
- **DN-046 is split out for DN-039's reason.** A pull request titled *the payment flow* must not
  quietly add a camera permission to all four build variants.

**Order: DN-046, then DN-047 — published and repinned — then DN-048.** DN-048 calls API that no
released library version carries, so it cannot start until DN-047 ships.

**A CI ticket was filed and then deleted on the owner's instruction the same day** — *"that process
is very far off for me to implement."* The gap it described is real: `:sharedLogic:check` is run by
the agent and attested by the agent. The compensating control is that the owner reviews every diff.
Recorded here in one line so the finding is not silently lost, and **not to be re-proposed.**

~~**Branches are stacked in all three repos.** Each is built on the previous because they touch the
same files — **merge each repo's PRs in the order shown**~~ — **every stack below is merged as of
2026-08-08.** Verified against `git log` in all four repos on 2026-08-08, not read off this index.
The stacks are kept struck rather than deleted because the ticket files record SHAs that only make
sense against this order:

| Repo | Base | Stack |
|---|---|---|
| **DNLibrary** | `development` | ~~`DN-001` → `DN-002` → `DN-004` → `DN-006` → `DN-008` → `DN-009` → `DN-011` → `DN-017` → `DN-016` → `DN-018` → `DN-019` → `DN-020`~~ **all merged** |
| **ios/DapurNaura** | `development` | ~~`DN-003` → `DN-009` → `DN-013` → `DN-012` → `DN-014` → `DN-015` → `DN-016` → `DN-018` → `DN-019` → `DN-021`~~ **all merged** |
| **umbrella** | `development` | ~~`DN-010` → `DN-011` → `DN-012` → `DN-013` → `DN-014` → `DN-015` → `DN-016` → `DN-018` → `DN-019` → `DN-020` → `DN-021`~~ **all merged** (DN-007 sat on its own branch) |
| **ios/SPMDNLibrary** | `development` | ~~`DN-018` → `DN-019`~~ **all merged** — its first ticket branches; the repo had no markdown at all |

**Nothing is stacked for DN-024 / DN-025.** Both branch straight from a `development` that is level
with its remote, in the first repos to start from a clean base since DN-001:

| Repo | Branch | Commit | PR |
|---|---|---|---|
| **DNLibrary** | `ticket/DN-024-cooking-class-category` | `308694b` | [#14](https://github.com/Fostahh/DNLibrary/pull/14) |
| **ios/DapurNaura** | `ticket/DN-025-cooking-class-category-filter-ui` | `f076cd1` | [#11](https://github.com/Fostahh/DapurNaura-iOS/pull/11) |
| **umbrella** | `ticket/DN-024-cooking-class-category` | — | none, by policy |

**The umbrella carries both tickets on one branch**, named for DN-024. Splitting them would have put
the requirement, the contract revision and this index on one side of a stack and the DN-025 ticket on
the other, for two changes that are one piece of work and take no PR anyway.

**Merge DNLibrary#14 before DapurNaura-iOS#11**, and publish `0.6.0` in between: the iOS branch calls
API that only exists in that version, so it does not compile against the pinned `0.5.0` until the
follow-up repin commit. That is the local package rule working as designed, not a broken branch.

**All four repos target `development`.** `main` is frozen until the app reaches `1.0.0`, when
`development` merges into it once — owner's instruction, 2026-08-07. The umbrella's `development` was
created from `main` at `30c711d` that day; it had none before.

**The umbrella takes no PRs** — its ticket branches are pushed into `development` directly. It
carries only docs and workspace config, so there is no build to break and nothing to review that was
not already reviewed on the ticket.

**Merge with a merge commit, not a squash.** DN-001 was, and `f263523` survived into `development`
as a result. That matters beyond one ticket: the commit SHAs recorded throughout these ticket files
stay valid, and every downstream branch stayed correctly based, so none needed rebasing. A squash
would rewrite `development`, orphan every branch above it, and turn ~20 recorded SHAs into dead
references. See [DN-022](DN-022-technical-agent-opens-prs.md).

> **Always `--no-ff`. A fast-forward is not a merge commit either.** Owner's rule, 2026-09-11, added
> after a fast-forward happened on the umbrella and nothing in the rules forbade it — the sentence
> above was written against *squash*, back when branches were stacked and a fast-forward was not
> even possible. It is the same shape of gap DN-045 closed: the rule named one thing and reality had
> three.
>
> **The reason is that ticket branches are deleted after merging**, so the merge commit is the only
> surviving record that a set of commits was one unit of work — cut together, reviewed together,
> landed together. A fast-forward loses that boundary permanently, and the `DN-XXX` prefixes do not
> recover it: `13aa4e0` is prefixed DN-046 and carries three tickets.
>
> It also keeps the umbrella reading like the other three repositories, where GitHub writes a merge
> commit for every PR — and it makes `git log --merges` an accurate list of what has landed.
> `git log --first-parent` gives the linear view when that is what you want.

**Work the lowest open id first.** Owner's instruction, 2026-08-06: tickets are reviewed and executed
in ascending order, and a higher id must not run ahead of a lower one. DN-016 already did — see
below — and that is the exception the rule exists to prevent, not a precedent.

**DN-015 is `done`.** Its original scope landed in `8d6937c`; an amendment on the same branch
then settled the folder conventions and navigation ownership the owner raised on 2026-08-06, and
added `DapurNauraAppRouter`, which `CODEBASE-ARCHITECTURE.md` §4 had specified since DN-014 without
anything implementing it. Awaiting the owner on the running app.

**DN-016 is `done`, delivered in two halves.** Its Kotlin half was committed (`28f00e2`) out of
order, *before* DN-015 and before the lowest-id-first rule existed — that commit stays, and this is
the exception that prompted the rule, not a precedent. The Swift half was held until the owner
approved DN-015 on 2026-08-06 and then landed: both Swift formatters deleted, eight call sites moved
to `DNFormat` / `DNErrorKt`, and `Helper/` gone entirely.

**`swiftlint lint` now reports 0 violations** — the first time, and every row in
`CODEBASE-ARCHITECTURE.md`'s known-violations table is struck. Keep it there: a clean linter makes
the next violation visible the moment it appears, which a habitual "3 known ones" never does.

⚠️ **DN-016 is the first ticket to need the full release path** — `publish-spm.sh publish`, a tag, a
GitHub release, then bumping the app off `../DNLibraryLocal` to the published version. All of it is
human-triggered and none of it has run. Until it does, the app builds only against the local package.

**DN-018 is `done`.** Every repository now carries a `README.md`, and the codebase document is
called `CODEBASE-ARCHITECTURE.md` everywhere — `DNLibrary`'s was renamed from `CODEBASE-STANDARD.md`,
which is why tickets DN-001 … DN-017 still cite the old name. **Those were left alone deliberately:**
a ticket records what was true when it was written, and rewriting closed work to match a later
decision makes the record lie. The renamed file carries a *formerly named* line so the old term still
resolves.

`docs/GETTING-STARTED.md` is gone, folded into the umbrella `README.md`. Four of its statements had
become false and were corrected rather than carried across.

**DN-019 states which artefact wins when documents disagree** — the requirement, and where none
exists, the ticket. Owner's instruction, 2026-08-07, after the agent revised an approved requirement
in place to absorb a corrected recipe shape. **That violated the standing immutability rule and was
reverted.** The rule is unchanged; what was missing was any document saying where truth lives, so
"put the correction in the ticket" read as bookkeeping rather than as the answer.

⚠️ **The approved recipe requirement is knowingly wrong and stays that way.**
`2026-08-06-recipe-detail.md` describes ingredients as a flat list with group labels. The first real
recipe proved a recipe is a list of **components**, each with its own ingredients *and* method. The
document is **not edited** — the corrected shape lives in `docs/contracts/recipe.json`, in
`docs/contracts/README.md`, and in the recipe tickets when they are written.

⚠️ **Found while writing SPMDNLibrary's README, and verified**: that repository has **no tags and no
releases**, and the binary-target URL in its `Package.swift` returns **404**. SPM resolves by tag, so
the package cannot resolve at all today. Nothing is broken in practice — the app has only ever built
against `ios/DNLibraryLocal` — and the first `publish-spm.sh publish` fixes all three in one step, so
no separate ticket was filed. It is recorded in that repository's README.

The umbrella stack exists because the ticket index and the rulebooks are shared files that every
one of those tickets touches; branching them independently would have produced four conflicting
edits of the same paragraphs.

**DN-010 changes the workflow standard itself**, not the product: it is the first `docs` ticket, and
the first to be filed and started in the same step because the owner's instruction scheduled it.
Its branch is cut from `main` — the umbrella repo has no `development` — independent of DN-007's.

---

## States

| State | Meaning | Who sets it |
|---|---|---|
| `todo` | Written up, not started | Agent, at creation |
| `in-progress` | Being implemented | Agent |
| `in-review` | Implemented, data-layer tests green, awaiting review | Agent |
| `done` | PR merged, **or the branch merged where there is no PR** | Agent, **only after the owner says so** |

**A ticket with no PR is closed by the owner confirming the merge** (DN-045). Umbrella-only work
has no pull request — the umbrella takes none by policy — so the PR condition can never be met
and the ticket would otherwise have no reachable end state. That is what stranded DN-042.

Rejections are verbal — flip back to `in-progress` and fix. If the same feedback arrives twice,
write it into the ticket so it survives the next session.

If implementation is blocked, append a `## Blocked` section, stop, and tell the human. Do not
improvise around it.

**The agent may create a technical ticket** at `status: todo` when it notices a problem — that is
how an incidental finding becomes tracked work instead of scope creep or a lost observation. It
must not **start** one until the human schedules it.

---

## Template — product ticket

```markdown
---
id: DN-005
type: product
title: Short imperative title
status: todo          # todo | in-progress | in-review | done
source: docs/requirements/2026-08-recipe-catalogue.md
branch: ticket/DN-005-short-slug
layer: data | ui | both | tooling | docs
---

## Requirement (traced)

> Quoted lines from the source document that this ticket satisfies.

[…shared sections below…]
```

## Template — technical ticket

```markdown
---
id: DN-001
type: technical
title: Short imperative title
status: todo
source: —             # no requirement document exists, and that is correct
branch: ticket/DN-001-short-slug
layer: data | ui | both | tooling | docs
---

## Rationale

What is wrong today, in specifics — name the file and the behaviour.
Why it is worth fixing now, and what it unblocks.

There is no requirement document to point at, so this section is the only record
of why this code changed. Write it for someone reading it in six months.

[…shared sections below…]
```

## Shared sections — both kinds

```markdown
## Context

Which files to read before starting, and anything already true that constrains the
approach. An agent starts every session cold — this is what stops it rediscovering
the codebase from nothing each time.

## Technical approach

What changes, where, and why. Name the files.

## Public API contract

What Swift and Kotlin callers see after this lands. DNLibrary ships as a binary, so
its public surface is a contract, not an implementation detail. Call out anything
source-breaking for existing consumers.

**Version bump implied:** patch | minor | major — and why.

## Out of scope

What this deliberately does not cover. Prevents sprawl, and saves an argument at review.

## Test plan

Specific cases, not "add tests". Which Gradle task proves it.
Data layer only — UI is verified manually by the human.

## Done when

Data-layer work:
- [ ] Code implemented on `ticket/DN-XXX-short-slug`
- [ ] Unit tests written and passing — `./gradlew :sharedLogic:check` from `DNLibrary/`
- [ ] **Doc sweep done** — every tracked `.md` enumerated, not grepped (DN-042)
- [ ] Committed, not merged

UI work:
- [ ] Code implemented on `ticket/DN-XXX-short-slug`
- [ ] Verified manually by the human
- [ ] **Doc sweep done** — every tracked `.md` enumerated, not grepped (DN-042)
- [ ] Committed, not merged

Tooling work (scripts, build config):
- [ ] Change implemented
- [ ] Behaviour demonstrated, including the failure paths it should catch
- [ ] **Doc sweep done** — every tracked `.md` enumerated, not grepped (DN-042)
- [ ] Committed, not merged

Docs work (the workflow standard itself):
- [ ] Every document stating the rule updated — they must agree with each other
- [ ] **Doc sweep done** — every tracked `.md` enumerated, not grepped (DN-042)
- [ ] Ticket index regenerated
- [ ] Diff reviewed by the human
- [ ] Committed, not merged

Always, and pick the line that matches where the work lives:
- [ ] PR merged, ticket marked `done` by the human
- [ ] **No PR — every changed file is in the umbrella, which takes none by policy**
- [ ] **Merged into `development`, and the human confirms it** — umbrella-only tickets close on this
```

**Use the second pair instead of the first when the ticket touches no project repo** (DN-045). The
umbrella takes no pull requests, so a `PR merged` line there can never be ticked — DN-042 carried one
and stalled at `in-review` for a month with its work already merged.

---

## Filling it in

- **`type:`** decides whether `source:` or `## Rationale` carries the justification.
- **`layer:`** decides which gates apply. A `ui` ticket has no tests, no `publish-spm.sh` run, and
  no version bump. A `docs` ticket — a change to the workflow standard itself, like DN-010 — has no
  automated gate at all; the human reading the diff *is* the verification, so say in the ticket
  what they should be checking for.
- **Commit messages must start with the ticket id** (`DN-004: …`). The projects are separate git
  repositories, so that id is the only thread linking the work across them.
