---
status: approved
date: 2026-09-12
author: owner
drafted-by: agent
approved: 2026-09-12
---

# Cooking a recipe, step by step

> **Every quotation below is the agent's English translation of an instruction the owner gave in
> Bahasa Indonesia on 2026-09-12**, per the platform's language rule. The originals are not stored.
> Where a translation could plausibly have changed the meaning, the point was put to the owner rather
> than settled quietly; the answers are recorded at the end.
>
> **User-facing strings are not translated.** *Mulai buat resep* and the rest stay in Bahasa
> Indonesia, and any wording here that the app will actually show is quoted as it will appear.

## Who this is for

**Someone who has bought a class and is standing in their kitchen about to cook.** They have the
recipe open; what they do not have is a way to work through it without losing their place.

It is not for anyone else. A recipe belongs to a class, and a class the user has not bought answers
its recipe endpoint with **403** — so this flow is unreachable for them by construction, not by a
check the app performs.

## What they need

**A guided flow that walks them through one recipe, from gathering ingredients to finishing.**

The owner's instruction, translated:

> "Inside the Recipe Detail screen there are already ingredients, step by step and so on. Make a
> button for *Mulai buat resep* and navigate to the next screen."

**The entry point is a new button on the recipe detail screen.** Nothing else about that screen
changes — it stays the reference view it is today.

**The button is pinned to the bottom**, above the safe area, over the scrolling content. Owner's
decision, 2026-09-12. A recipe is long — thirteen ingredients and ten steps here — and a cook who
already knows it should not have to scroll to the end to start.

> **This departs from how the app places its other primary action**, and deliberately. *Beli Kelas*
> sits inline inside the class detail's scroll view. That one is a decision a reader makes **after**
> reading; *Mulai buat resep* is what a returning cook wants **immediately**. The precedent was put
> to the owner, who chose pinned.

## The flow is three pages, moving vertically

> "This screen has a progress bar at the top. A horizontal line with three segments and a counter.
> For example, on the first step it shows 1/3, then 2/3, finally 3/3."

> "Hopefully this is one View struct, because this screen changes vertically — roughly similar to
> onboarding."

**One screen, three pages, a progress indicator pinned at the top.** The indicator is a horizontal
line divided into three segments with a counter reading `1/3`, `2/3`, `3/3`.

**Movement is by button only.** Owner's decision, 2026-09-12, asked directly whether the pages should
also be swipeable: **buttons only, no swipe.** A user cannot reach the congratulations page without
passing through the cooking.

**Going back is a control on the page itself.** Owner's decision, 2026-09-12. Pages after the first
carry their own back control beside the forward one, and the vertical animation reverses. The
owner's original description asked for this — *"or even 2/3 back to 1/3"*.

> **The navigation bar's back button therefore means one thing only: leave the flow.** It is not
> overloaded to step between pages, so the same arrow never does two different jobs depending on
> where the user is.

> **[ASSUMPTION]** The transition between pages is animated vertically, since the owner described the
> screen as changing vertically and compared it to onboarding.

> **[ASSUMPTION]** The labels on the forward and back controls for pages 1/3 and 2/3 are not yet
> fixed. User-facing wording belongs to the owner; the agent will draft them alongside the page 3/3
> strings and they can be replaced without argument.

### Page 1/3 — the ingredients, as a checklist

> "Page 1/3 contains check-boxes similar to a to-do list, containing the ingredients, which the user
> can tap. When tapped, the check-box becomes checked and the text is struck through. Then there is
> a button to move to 2/3."

**Each ingredient is a tappable row with a check-box.** Tapping it checks the box and strikes through
the text. Tapping again unchecks it.

**Ingredients stay grouped by their recipe component.** Owner's decision, 2026-09-12. This recipe has
six ingredients under *Brownies* and seven under *Toping creamcheese*; they are never shown as one
list of thirteen.

> **The grouping is not presentational.** The owner splits a recipe into components so each can be
> measured into its own bowl, and the same ingredient appears in two components at different
> quantities — *gula halus* does exactly that here. A flat checklist would show it twice with no way
> to tell which bowl each tick belonged to.

**Each component is introduced by its name in bold, and a grey divider line separates one group from
the next.** Owner's instruction, translated: *"Make it like the recipe detail page, a grey separator
to divide the two, but with check-boxes."*

> **The grey line is new; the app does not have one today.** The recipe detail screen separates
> components with the bold name and spacing alone — no rule. Put to the owner, who chose the heading
> **and** a divider. **This is a deliberate difference from recipe detail, not a copy of it**, and
> recipe detail is not changed to match.

**A tick is remembered by the ingredient's name, scoped to its component.** Owner's decision,
2026-09-12, translated:

> "Track it by name. The name sits inside each respective array — for example Brownies, and inside it
> the ingredient Dark chocolate; then Toping creamcheese, and inside it the ingredient Dark
> chocolate. So just by name, since those are different arrays and different objects anyway."

**That reasoning is what makes it safe, and it was checked against the data.** No ingredient name
repeats *within* a single component: Brownies has six distinct names, Toping creamcheese seven.
*Gula halus* appears in both components, and the component scope is exactly what tells the two apart.

> **No id is added to the contract, and an earlier draft of this document was wrong to require one.**
> The agent first recommended giving every ingredient a stable id, on the grounds that a recipe being
> edited would otherwise corrupt stored ticks. **Nobody can edit a recipe today** — they come from a
> committed fixture and a mock server, with no backend and no admin tool — so the failure that
> justified the id cannot happen yet, and the recommendation was stronger than the evidence for it.
>
> **What is given up, stated plainly:** if an ingredient or a component is ever renamed, the tick
> that pointed at it is **forgotten** and the user re-ticks. That is a mild failure. The one worth
> avoiding — a tick silently moving to the *wrong* ingredient — cannot happen when the key is a name.

> **[ASSUMPTION]** The component half of the key is its **position**, not its name, because
> `RecipeComponent.name` is nullable and a null name cannot key anything. The ingredient half stays a
> name, as the owner asked. Inserting a component is a far larger change than inserting an
> ingredient, and if it ever happened the ticks would simply not match and be forgotten.

### Page 2/3 — the video, with the method as timestamps

> "Page 2/3 contains a video. I will provide the video later; for now use this YouTube video. The
> video will have timestamps in mm:ss format. When tapped, the video jumps to the frame at that
> minute and second."

**Tapping a timestamp seeks the video to that point.** The timestamps are shown as a list, each
reading `mm:ss` beside its label.

**The timestamps are the recipe's own steps, and every step gets one.** Owner's decision, 2026-09-12,
on both points: the list is the existing steps rather than separate chapter markers, and **all ten
are tappable** rather than only some milestones. `RecipeStep.videoTimestampSeconds` already exists in
the approved contract for exactly this, and nothing has ever filled it in.

**The timestamp values may be invented for now.** Owner's decision, translated: *"Just make a random
timestamp at the moment, since it is just dummy data and a dummy video. No problem with it."* The
placeholder video is not a recording of this recipe, so no honest value exists; arbitrary ones are
accepted **because the video and the fixture are both placeholders, and they are replaced together.**

> The owner's illustration was two lines — *"Membuat adonan brownies 00:00"*, *"Membuat adonan red
> velvet 01:05"* — followed by *"for now like this first."* **The contract's recipe has ten steps
> across two components, and none of their wording matches those two lines.** Put to the owner, who
> chose the ten existing steps: the illustration showed the *shape* of the list, not its content.

**The video source is YouTube, for now.** Owner's decision, translated: *"For now let's play YouTube.
Maybe in the future, after the backend is ready, I can finally decide. So YouTube first at the
moment."*

> **This is explicitly temporary, and the approved contract disagrees with it.** `Recipe.videoUrl` in
> the contract is an `.mp4` file, not a YouTube link. A YouTube video cannot be played by the
> platform's normal video player, and its stream cannot be extracted without breaking YouTube's
> terms — it has to be embedded in a web view and driven through YouTube's own player interface.
> **Seeking a YouTube video and seeking a file are different work**, so choosing YouTube now means
> the second is written later. The owner made that trade knowing it.

### Page 3/3 — finished

> "Page 3/3 is like congratulations. YAY, you have finished making [the recipe name]."

**A congratulations page naming the recipe just made**, with two controls: one to finish, one to
start the recipe again.

```
Selamat!

Anda sudah selesai membuat

Brownies Red Velvet Cheese & Original Cheese

        [ Ulangi ]      [ Selesai ]
```

**The recipe name sits on its own line rather than inside the sentence.** The owner's illustration
ran it inline — *"YAY, Anda sudah selesai membuat [nama resep]"* — but this recipe is called
*Brownies Red Velvet Cheese & Original Cheese*, forty-four characters, which wraps across three or
four lines on a phone and buries the headline. Owner's decision, 2026-09-12, after seeing both.

*Anda* is used because it is what the app already uses everywhere it addresses the reader.

**Selesai returns to the recipe detail**, where the flow was entered. Owner's decision, 2026-09-12.

**Ulangi appears only on this page.** Owner's decision, 2026-09-12: restarting mid-cook is not
offered, so a user who wants to begin again leaves and re-enters.

> **[ASSUMPTION]** The exact strings — *Selamat!*, *Anda sudah selesai membuat*, *Ulangi*, *Selesai*
> — were drafted by the agent from the owner's illustration and approved rather than dictated.
> User-facing wording belongs to the owner, so any of them can be replaced without argument.

> **[ASSUMPTION]** Something celebratory accompanies the headline. The owner said *"congratulations"*
> and *"YAY"*, which implies a graphic or emoji, but nothing specific was described.

## What happens when it is finished, and what cannot happen yet

The owner's instruction, translated:

> "There will be some sort of tracker on the backend side, to track whether the class is finished or
> not, triggered after screen 3/3 is shown and the client taps done. There will be a reset/restart
> button to go back to the 1/3 screen and submit a restart to the backend."

**None of that can be built yet, and the reason is one the platform has already written down.**

A completion tracker is **per-user data by definition**. The backend records that a recipe is
finished — *against whom?* There is no signed-in user, no session and no token; the app's only
credential is a static API key. There is also no deployed backend to submit to. These are the same
two missing pieces the owner identified on 2026-09-11 about payment, and the ordering set then —
**auth, then a backend, then anything that completes** — applies here unchanged.

**Owner's decision, 2026-09-12: build the buttons, submit nothing.** *Selesai* and *Ulangi* are
present and navigate, and **record nothing anywhere**. This is deliberately the same shape as the
payment screens, which show bank accounts and photograph a receipt while being unable to record a
payment.

> **The screens must not fake a completed state to hide the gap.** That rule was set for the payment
> screens and applies here for the same reason: a status the app invents is worse than one it admits
> it does not have.

## What is remembered between visits

**The ticked ingredients survive the app being closed and reopened.** Owner's decision, 2026-09-12,
asked how far the ticks should survive: **across app restarts**, not only within a session.

**The flow also resumes on the page it was left on.** Owner's decision, 2026-09-12. A user who
reached 2/3 and closed the app returns to 2/3, not to the checklist — so the stored progress is the
ticked ingredient ids **and** the page.

**This is progress, and the backend never learns it.** Owner's instruction, translated:

> "Ticking all the ingredients is progress, and the backend does not need to know. It is just a
> local, on-device thing. If one user has two devices and the progress happens on device one, device
> two does not know about it."

> **That settles a question this document had flagged as an assumption.** The ticks and the deferred
> completion tracker are **different data, permanently** — not one thing split by circumstance. Ticks
> are local working state a cook wants in a kitchen with no signal; completion is one coarse fact the
> backend will own. Two devices disagreeing about ticks is **the accepted behaviour**, not a gap to
> close later.

> **This reverses part of a decision the platform took deliberately.** DN-031 deleted the local
> storage that existed, and `DNLibrary/CLAUDE.md` says it must not be reintroduced *speculatively*.
> A stated requirement is not speculation, so the rule is satisfied — but reintroducing storage is a
> real change with its own consequences and belongs in its own ticket rather than riding inside this
> feature.

**The storage lives in the shared library, not in the iOS app.** Owner's decision, 2026-09-12, so
Android inherits it rather than building the same thing again.

**Ticks are stored per recipe**, so ticking an ingredient in one recipe does not affect another.

> **There is no user to key this against, and that is accepted** — confirmed by the owner above.
> Stored progress belongs to the device, not to a person: two people sharing a phone share the ticks,
> and one person with two phones has two separate sets. This is the same absence that blocks the
> completion tracker, but unlike that one it is **not waiting to be fixed.**

## Questions raised while drafting, and how the owner answered them

All were put to the owner on 2026-09-12. Kept here so a later reader can see what was uncertain and
what settled it.

| Question | Answer |
|---|---|
| The timestamp values do not exist and the placeholder video is not this recipe — invent them? | **Yes.** *"Just make a random timestamp at the moment, since it is just dummy data and a dummy video."* Both are placeholders and are replaced together |
| All ten steps, or only milestones? | **All ten**, every one tappable |
| Does the checklist group ingredients by component? | **Yes** — six under *Brownies*, seven under *Toping creamcheese*, never one list of thirteen |
| Where does *Selesai* go? | **Back to the recipe detail**, where the flow was entered |
| Where does the restart control live? | **Only on page 3/3**, beside *Selesai* |
| What does page 3/3 say? | Headline, then the recipe name on its own line |
| Does recipe detail change beyond gaining the button, and where does it sit? | **Nothing else changes.** The button is **pinned to the bottom** |
| Swipe between pages, or buttons only? | **Buttons only** |
| How far do the ticks survive? | **Across app restarts** |
| Where does that storage live? | **DNLibrary**, so Android inherits it |
| Where will the real videos live? | **YouTube for now**; revisited once a backend exists |
| Nothing identifies an ingredient, and *Gula halus* appears twice — how is a tick keyed? | **By name, scoped to its component.** No id is added. Each component has its own `ingredients` array, so the scope disambiguates; names were verified unique within each component. An earlier draft recommended adding an id and was revised — see *Page 1/3* |
| Re-entering the flow — which page? | **Resume where they left off**, so the page is stored alongside the ticks |
| Is ticking progress the backend should know? | **No.** Local and on-device only, permanently. Two devices are expected to disagree |
| With no swipe, how does the user go back from 2/3 to 1/3? | **A back control on the page itself.** The navigation bar's back button then means only "leave the flow" |
| The grey separator described does not exist on recipe detail — copy that screen, or add a line? | **Bold heading *and* a grey divider.** A deliberate difference from recipe detail, which is left unchanged |

## Still open

**Nothing blocking.** Two things are recorded above as `[ASSUMPTION]` rather than instruction, and
can be corrected at any time without reopening this document:

- The exact Indonesian strings on page 3/3, which the agent drafted from the owner's illustration
- Whether something celebratory accompanies the headline, and what it is

**One thing is deferred rather than unanswered:** the backend completion tracker, which cannot be
built until there is a signed-in user and a deployed backend. That is not a gap in this document — it
is the platform's existing ordering, and this feature is explicitly built without it.
