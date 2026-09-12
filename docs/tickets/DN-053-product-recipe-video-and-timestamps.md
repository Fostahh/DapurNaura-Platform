---
id: DN-053
type: product
title: Page 2/3 plays the recipe video, and tapping a step seeks it
status: todo
source: docs/requirements/2026-09-12-cooking-a-recipe.md
branch: ticket/DN-053-recipe-video-and-timestamps
layer: data + ui
---

## Rationale

From the requirement, *Page 2/3*. The middle page of the cooking flow shows the video and lists the
recipe's steps with a `mm:ss` timestamp each; tapping one seeks the video to that point.

**Separated from DN-052 because it is different work and the riskiest part of the feature.** Three
SwiftUI pages are ordinary; a web view driving YouTube's player through a JavaScript bridge is not.
Landing the flow first means that if this proves awkward, everything else is already merged.

## Context

Read before starting:

- `docs/requirements/2026-09-12-cooking-a-recipe.md` — *Page 2/3*
- `docs/contracts/recipe.json` — where the timestamps go
- `DNLibrary`'s `StubRemoteDataSource` fixture, and `~/Desktop/DapurNaura.json` (Mockoon) — the two
  other copies of the same payload
- **DN-052 must be merged first** — this replaces the placeholder it leaves on page 2/3

## Technical approach

### The data half

**Fill in `videoTimestampSeconds` on all ten steps.** The field already exists on `RecipeStep`, is
already nullable, and has never carried a value. **No schema changes and no public API moves** —
this is fixture data only.

**The values may be invented.** Owner's decision, translated: *"Just make a random timestamp at the
moment, since it is just dummy data and a dummy video. No problem with it."*

> The placeholder video is *Red Velvet Cream Cheese Swirl Brownie* by **Whisk n Fold** — genuinely
> the same kind of brownie, so plausible timestamps are easy. They are still invented, and the video
> and the fixture are replaced together when the owner supplies a real recording.

**Three copies must move together**, which is the standing hazard with this payload: the contract in
the umbrella repo, the Kotlin fixture in `DNLibrary`, and the Mockoon environment on the owner's
machine. Mockoon is committed nowhere, so **only a person keeps it in step.**

### The video half

**YouTube, for now.** Owner's decision, translated: *"For now let's play YouTube. Maybe in the future,
after the backend is ready, I can finally decide."*

> **This contradicts the approved contract, knowingly.** `Recipe.videoUrl` is an `.mp4`. A YouTube
> video cannot be played by `AVPlayer` and its stream cannot be extracted without breaking YouTube's
> terms — it has to be embedded in a `WKWebView` and driven through YouTube's own player interface,
> with seeking done by evaluating JavaScript against it. **Seeking a YouTube video and seeking a file
> are different work**, so the second gets written when a real video arrives.

**The video was checked and is embeddable** — YouTube's oEmbed endpoint answers 200 for
`5lJ-0YS3VoM`, which it does not for videos whose owners disable embedding.

**Two things that decide whether this feels right:**

- **Inline playback must be enabled**, or iOS forces the video fullscreen and the timestamp list
  disappears behind it — which defeats the page.
- **Seeking must work while paused as well as playing**, since a cook taps a step to find a moment,
  not to start the video over.

**Tapping a step seeks; the list is the method.** All ten steps carry a timestamp and all ten are
tappable, grouped by component like everywhere else.

## Public API contract

**None.** The field exists and is nullable; filling it changes only data. **Version bump implied:
none** — though the fixture lives in `DNLibrary`, so a release is needed before the app sees the
values.

## Out of scope

- **Replacing the placeholder video**, and switching to `AVPlayer`. That is the day the owner supplies
  a recording, and it is a separate decision the requirement already records.
- **Persisting the video's position.** Only the ticks and the page are remembered (DN-051).
- **Adding a chapter field to the contract.** The owner chose the existing steps over chapter markers.

## Test plan

The data half touches `DNLibrary`, so its tests are required:

- The fixture decodes with all ten timestamps present and non-null
- A step's timestamp survives into the domain model
- **The existing test that a null timestamp is allowed must keep passing** — the field stays
  nullable, and a future recipe may genuinely have no video

What the owner checks on the running app, with Mockoon running:

| Check | Expected |
|---|---|
| Page 2/3 | The video plays **inline**, not fullscreen |
| The step list | Ten steps, grouped by component, each with `mm:ss` |
| Tapping a step | The video jumps to that point |
| Tapping a step while paused | Still seeks |
| The video with no network | The page fails visibly rather than showing a blank box |

## Done when

- [ ] All ten steps carry a timestamp in the contract, the Kotlin fixture **and** Mockoon
- [ ] The video plays inline and seeking works from the step list, paused or playing
- [ ] `./gradlew :sharedLogic:check` green on both platforms
- [ ] `xcodebuild … build` reports `** BUILD SUCCEEDED **` (DN-034)
- [ ] `swiftlint lint --strict` reports 0 violations
- [ ] Documentation sweep (DN-042) — `docs/contracts/README.md` describes the fixtures
- [ ] Diff reviewed by the owner on the running app
- [ ] Committed
- [ ] PR opened
- [ ] PR merged
