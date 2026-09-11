---
id: DN-044
type: technical
title: Strip prose comments, and restore Xcode's header template across every file
status: done
source: —
branch: ticket/DN-044-strip-prose-comments
commit: d534f6c
pr: https://github.com/Fostahh/DapurNaura-iOS/pull/23
merge-commit: c93c17f
layer: ios
---

## Rationale

**The owner's instruction, 2026-09-11:**

> "Also, delete all the comments that really annoys me inside all classes excluding inside Components
> Folder"

**This repository had grown an unusual comment density** — roughly a third of every non-component
file was prose. Much of it was written by the agent, and the habit compounded: each ticket added
explanation to files the previous ticket had already explained, because the explanation was the
cheapest place to put a decision that had just been argued out.

**The argument against doing this is weaker than it looks, and it is worth saying why.** Nothing is
lost that is not recorded elsewhere: this project runs Document Driven Development, and every
decision those comments restated already lives in the ticket that made it. `docs/tickets/` is the
record; the comments were a second copy that nothing kept in sync. DN-041 and DN-042 exist precisely
because the second copies had drifted.

**What is genuinely given up** is proximity — the rationale no longer sits where the mistake would be
made. That is a real cost and it is recorded under *What the tripwires were*, so the knowledge is
findable by grep rather than only by memory.

**Nothing in the standards required them.** `docs/CODEBASE-ARCHITECTURE.md` mandates that comments be
English (§8) and says nothing about their presence or shape; `.swiftlint.yml` says the same in its
own words — *"the document says nothing about comment shape."* No rule was bent.

## Context

- `ios/DapurNaura/DapurNaura/` — 35 files in scope, all outside any `Components/` folder
- `ios/DapurNaura/docs/CODEBASE-ARCHITECTURE.md` §8 — comments must be English; nothing more
- `ios/DapurNaura/.swiftlint.yml` — `vertical_whitespace_closing_braces` is enabled, so deletions
  cannot leave a blank line above a `}`

**Scope was settled with the owner before anything was deleted**, because *"all the comments"* has
more than one reading:

| | |
|---|---|
| **Deleted** | every `///` doc comment, and every whole-line `//` explanation |
| **Rewritten** | the header block — see *The headers* |
| **Kept** | `// MARK: -` markers — navigation aids, not prose |
| **Untouched** | **every `Components/` folder**, at both scopes — the owner's exclusion |

Seven `Components/` folders are excluded: `Presentation/Components/` and one inside each of
`Auth/Login/`, `CookingClassList/`, `CookingClassDetail/`, `CookingClassSelection/`, `RecipeDetail/`
and `OfflineClassSchedule/`.

## Technical approach

Two scripts, not 88 hand edits — `strip_comments.py` and `fix_headers.py`, both in the session
scratchpad and deliberately not committed: they are one-offs, and a tool kept around invites a second
run nobody wanted.

Per file: treat the leading `//` block as the header and set it aside; drop every `///` line and
every whole-line `//` that is not `// MARK:`; repair what the deletions leave — collapse runs of blank
lines to one, and remove any blank line left sitting above a `}`; then replace the header with the
template below.

**Two hazards were checked before running it, not after:**

- **`//` inside string literals.** `LoginView` carries
  `"https://placehold.co/600x400/png?text=Segera+Hadir"`. Verified there are **no** end-of-line
  trailing comments anywhere in scope, so stripping whole lines only is provably safe and no
  string-literal parsing was needed. The URL is intact.
- **Multi-line string literals.** The script tracks `"""` and passes their contents through
  untouched. None were present, but a strip that only works on today's files is the wrong tool.

**507 lines removed, 2295 → 1788.**

## The headers

**A second instruction followed, once the comments were gone and the headers were left standing.**
The owner gave the template, showed a file that broke it, and closed in Bahasa Indonesia —
*"ini melanggar ya"* — **translated: "this violates it,"** followed by *"header should follows Xcode
Files Creation."* Translated and dated 2026-09-11, per the platform's language rule.

```swift
//
//  <Filename>.swift
//  DapurNaura
//
//  Created by Mohammad Azri Khairuddin on <dd/mm/yy>.
//
```

**Fifty-three of fifty-five files broke it**, each having replaced the attribution line with a
`DN-XXX — what this file is` summary. Only `DapurNauraApp.swift` and `DapurNauraAppConfig.swift` were
ever correct. The summaries were the same mistake as the prose one level up: a description of the
file, written once, that nothing keeps true — `CookingClassSelectionView.swift` still called itself
*"the app's entry screen, taken over from the class list"* two tickets after that stopped being what
it was.

**This applies to `Components/` as well.** The exclusion the owner gave was about *comments*; a header
is a template every file follows. Components keep their documentation and get the correct header.

### Where the dates came from

**The real creation date, recovered from the first commit that added each file** — the owner's choice
over stamping one uniform date, on the grounds that a header claiming a creation date the file does
not have is the same class of untrue statement the ticket is removing.

Basenames are unique across all 55 files (verified), which is what made this possible: DN-043 has
renames staged but not committed, so `git log --follow` on a new path finds nothing, while a
`*/<basename>` pathspec still finds the history. Dates land between 06/08/26 and 11/08/26, with
11/09/26 for the four files created in this session.

**One correction caught on review of the script's own output.** `DapurNauraAppConfig.swift` already
carried a correct header dated 10/06/26; the script replaced it with its git *add* date, 06/08/26.
Those are different facts — the file was created in Xcode in June and first committed in August. **A
header that already exists is evidence and is not recomputed**, so the original was restored by hand.
`DapurNauraApp.swift` was unaffected, its two dates being the same.

## What the tripwires were

**The owner chose to strip everything rather than preserve these**, having been shown them first.
Recorded here so the knowledge survives the deletion, which is the whole reason this section exists:

| Site | What the comment warned | Where the reasoning lives now |
|---|---|---|
| `RouteDestination` / `.id(route)` | Without it SwiftUI identifies a destination by **position** in the path, so replacing a route at a given depth reuses the previous screen's `@State` | DN-015, and §4 — which still states it as a **must** |
| `RootView` | Must stay a `View`; `withAnimation` on state owned by an `App` animates nothing | DN-043, and §4 |
| `DapurNauraApp` | The only place that may name `DNDataLayer` | §5 |
| `CookingClassSelectionView` | Do not move the `NavigationStack` back down here | DN-043, and §3's flow-module rule |
| `LoginViewModel` | No `State` enum, deliberately — the screen fetches nothing | DN-033, DN-040 |
| `DapurNauraApp` (`@MainActor`) | Swift 6 makes the implicit hop an error | DN-038 |

**Every one is still enforced by `docs/CODEBASE-ARCHITECTURE.md`**, which is the document a change is
reviewed against. That is what makes this survivable: the rules were never only in the comments.

## Public API contract

None. No symbol, signature or behaviour changed.

**Version bump implied:** none. No library change, no publish, no repin.

## Out of scope

- **Comments inside every `Components/` folder.** The owner's exclusion, applied literally at both
  scopes. **Their headers were still corrected** — the exclusion was about comments, and a header is
  a template every file follows.
- **`DNLibrary`.** The instruction was about the app. The Kotlin layer's KDoc is untouched, and its
  public API is a binary contract where documentation has a second job.
- **`docs/`.** Markdown is the record this ticket relies on; thinning it would remove the thing that
  makes the deletion safe.
- **Any behaviour.** Comments and headers only. If this ticket changes what the app does, something
  went wrong.
- **Re-adding comments elsewhere.** Not a licence to move the prose into the tickets either — the
  tickets already carry it.

## Test plan

Comments and headers only, so the proof is that nothing moved:

```sh
xcodebuild -project DapurNaura.xcodeproj -scheme "DapurNaura Dev" \
  -destination 'platform=iOS Simulator,id=4C82AD15-1365-4200-977C-C5DF10E11B1B' build
swiftlint lint
git diff --stat        # must show deletions and no insertions outside whitespace repair
```

**Nothing is asked of the owner on the running app beyond DN-043's own checks.** A comment cannot
change behaviour, and the build is the whole gate here.

## Done when

- [x] 35 files stripped; every `Components/` folder untouched
- [x] `// MARK:` markers preserved
- [x] All 55 headers conform to Xcode's template — verified by pattern across every file
- [x] Real per-file creation dates used; `DapurNauraAppConfig.swift`'s existing date restored
- [x] No blank line left above a `}`; no run of blank lines longer than one
- [x] String literals intact — the `placehold.co` URL verified by hand
- [x] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034), 2026-09-11
- [x] `swiftlint lint` reports 0 violations, 2026-09-11
- [x] The tripwires recorded above, with where each rule still lives
- [x] Owner has reviewed the diff — approved 2026-09-11
- [x] Committed, not merged — iOS `959780c`, umbrella `09fb9e5`
- [x] PR opened — [DapurNaura-iOS#23](https://github.com/Fostahh/DapurNaura-iOS/pull/23), stacked on #22
- [x] PR merged — [DapurNaura-iOS#23](https://github.com/Fostahh/DapurNaura-iOS/pull/23), merge commit `c93c17f`, owner confirmed 2026-09-11. **Rebased onto `5b1c6f2` on merge, landing as `d534f6c`** — content verified identical to what was reviewed

## Blocked

~~**Blocked on DN-043's commit.**~~ **Cleared 2026-09-11.**

DN-043 is still uncommitted — the owner has not yet verified its transition on the running app — and
both sets of changes therefore share one working tree. Roughly 31 of the 35 stripped files are also
renamed or edited by DN-043, so a clean two-commit split is not available by staging alone.

**It resolved without reproducing anything.** The index still held the moved files at their *original*
content, so DN-043 committed as 34 genuine renames and the strip fell out cleanly as this ticket's own
commit. No intermediate state had to be fabricated, and DN-043's commit was built in isolation to
confirm it stands alone. **Merge #22 before #23.**

## Notes

**The four files DN-043 adds were never committed with the prose in them.** `RootView`, `RootRoute`,
`AuthFlowView` and `CookingsFlowView` were written, stripped and committed in one motion, so git
history shows them as they are rather than as a paragraph that was deleted a day later. Only the 31
pre-existing files show a deletion diff.

**This is the second instruction in two days about documentation volume**, after DN-042 made the doc
sweep a gate. They pull in opposite directions only on the surface: DN-042 said the *documents* must
be correct, and this says the *code* need not repeat them. Both reduce the number of places a fact is
written down, which is the same problem DN-029 and DN-041 were filed about.
