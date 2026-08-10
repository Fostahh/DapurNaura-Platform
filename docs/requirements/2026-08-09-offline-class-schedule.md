---
status: approved
date: 2026-08-09
author: owner
drafted-by: agent
approved: 2026-08-09
corrected-by: DN-036    # the availability colour is on the badge only, and the buy button carries no price
---

# The offline class schedule

## Who this is for

Someone who wants to attend a Dapur Naura class **in person** rather than follow one online. Today
the app answers them with a notice saying the feature is being built, so there is no way to learn
that offline classes exist, when they run, what they cost, or what is taught in them — even though
that schedule is published every month on social media.

[ASSUMPTION] The owner described the screen, not the person. The paragraph above is the agent's
reading of who benefits.

## What they need

**A schedule of the offline classes coming up, opened from the Kelas Offline choice on the home
screen.**

The owner's instruction, given in Bahasa Indonesia on 2026-08-09 and recorded here as the agent's
English translation per DN-010:

> "I want to build the Kelas Offline detail page. […] This screen contains the Upcoming Kelas
> Offline for 1 month+ from the current month. For example it is currently August, I will show the
> Upcoming Kelas Offline in September, and that is the full offline class schedule for September.
>
> The data concept for an offline class is the class name, the class price, the day and date, and
> the materials available in that class."

Answering the agent's questions the same day:

> "+2 months, so September and October — the point is +2 months from the current month."

> "Compact, with the materials opening when pressed."

> "Replace it — open the schedule screen."

**Correcting the agent's first draft, the same day.** The draft had said the current month is not
shown at all. The owner read that sentence and answered it:

> "Right now in August there are offline classes too. Today is 9 August — as an example, the offline
> classes in August fall on the 12th (Wednesday), 15th (Saturday), 19th (Wednesday), 22nd
> (Saturday), 26th (Wednesday) and 29th (Saturday). Those are shown as well, as long as the date is
> still ahead of today's date."

### Which classes appear

**Everything still to come, out to the end of next month.** Two rules together:

- **Nothing in the past.** A class whose date has already gone does not appear, even though the rest
  of its month still does.
- **The window ends one month out.** In August it runs to the end of September.

On 9 August 2026 that means: the remaining August classes, and all of September.

**Corrected by the owner on 2026-08-09**, having first said two months: *"instead of month + 2, change
it to month + 1 — so the list only shows August and September when it is currently August, and so
on."* The earlier `+2` is not the rule.

**A class dated today still appears.** Owner's decision, 2026-08-09, asked because *"still ahead of
today"* does not settle the day itself. A class running this evening is exactly what someone opening
the app today wants to see.

The window moves with the calendar — nobody edits anything when a month turns. **The screen
therefore has to know today's date**, and what it shows on the last day of a month differs from what
it shows the next morning.

**There is no "schedule not published yet" state.** The owner considered one and then ruled it out
on 2026-08-09: *"the scenario of a schedule not yet being drawn up cannot happen."* The schedule is
always ahead of the window, so nothing needs to explain a month that has not been planned.

That decision is about the business, not about the network. **The screen still needs something to
say when the list comes back with nothing in it** — a failed load, or a month that empties as its
last class passes — because the alternative is a blank screen with no explanation. That is a
fallback, not a feature, and it is not to be designed into something the owner did not ask for.

### What each class tells the reader

Five things, and no more:

- **its name** — *Kelas Pizza*
- **what it costs**, written *"HTM Rp150.000"*. Owner's decision, 2026-08-09: this wording is for
  offline classes specifically, and it is produced in one shared place rather than by each app
- **the day and the date** it runs — *Rabu, 2 Sept 2026*, the weekday included
- **whether a place is still available** — see below
- **what will be taught** — the list of materials, five or six items for a typical class

### Whether a place is still available

Every class is in exactly one of three states. Owner's decision, 2026-08-09:

| State | Reads | Colour |
|---|---|---|
| Open | **MASIH BISA DAFTAR** | green |
| Nearly full | **HAMPIR PENUH** | yellow |
| Full | **SUDAH PENUH** | red |

**The state follows from how many places are left**, and is not set by hand. Owner's decision,
2026-08-09 — *"when the quota is down to around 10 slots left"*:

| Places remaining | State | Colour | Can still join? |
|---|---|---|---|
| more than ten | **MASIH BISA DAFTAR** | green | yes |
| ten or fewer, but not none | **HAMPIR PENUH** | yellow | **yes** — nearly full is not closed |
| none | **SUDAH PENUH** | red | no |

Because it is worked out from the count, the state can never disagree with the number of places
actually left — which a hand-set flag eventually would.

**Nearly full still takes bookings.** Owner's emphasis, 2026-08-09. The yellow is a warning to hurry,
not a closed door, and nothing about the row may suggest otherwise.

**Being full removes the button, and nothing else.** The row still presses, the sheet still opens,
the materials still read. What a full class loses is the way in, not the way to look.

**The number of places left is never shown to the reader.** Owner's decision, 2026-08-09: the row
carries the state and not the count. The count decides the state and stays behind it — how many
people have signed up for a class is the owner's business, not something the app publishes.

**A full class is still listed.** It is not hidden or moved to the bottom — someone who wants to
know what Dapur Naura teaches should see it, and someone hoping to join needs to be told plainly
that they cannot rather than left to guess from an absent row.

**How the state is shown: both a phrase and a colour, never colour alone.** The owner asked for the
row to be identifiable by colour and left the form to the agent. [ASSUMPTION] the proposal, and the
reason for it:

- **The phrase carries the meaning.** These three states are green, yellow and red — precisely the
  set that red-green colour blindness collapses, and it affects roughly one man in twelve. A reader
  who cannot tell *SUDAH PENUH* from *MASIH BISA DAFTAR* would arrive at a class with no place left.
  The word is not decoration next to the colour; it is what makes the colour safe to use.
- **The colour makes the row scannable**, which is what the owner asked for — carried on the class's
  outline and on the phrase's own background, so the state reads from across the row without being
  read word by word.
- **Not a fully tinted card.** A list of solid green, yellow and red blocks is loud at three rows and
  unreadable at ten, and a red card reads as *something went wrong* rather than *this one is full*.

### How the screen is arranged

**A month is a section; a class is a row inside it.** Owner's decision, 2026-08-09. So in August the
screen carries two sections — August and September — each holding that month's classes in date
order.

**A section opens and closes**, with an arrow at its right-hand end showing which it is. Owner's
decision, 2026-08-09.

[ASSUMPTION] **Both sections start open.** The owner did not say which state a section opens in.
Starting closed would hide everything the screen exists to show behind two more taps.

**A section states how many of its classes can still be joined**, as a bare number beside the arrow
— owner's decision, 2026-08-09. That is the count of classes with places left, so a month whose
classes are all full shows no number rather than a zero. It is what makes a closed section still
worth reading: a reader scanning two collapsed months can see where there is still room without
opening either.

**The screen is titled Kelas Offline**, matching the online list's *Kelas Online*. Sections run in
calendar order, the current month first, and the classes inside a section run by date, earliest
first. [ASSUMPTION] — all three follow from the screen's purpose and none were stated.

### How much is shown at once

**The list stays compact: a reader can scan several classes without scrolling.** The materials are
the long part, so they are not shown until the reader asks for them by pressing the class. Nothing
is lost — every material is reachable — but the scan comes first and the detail second.

Each class is drawn as a **ticket**: a picture on the left, the class and its details in the middle,
and the month and date standing apart on the right. Owner's reference, supplied as an image on
2026-08-09.

### Pressing a class

**Every class can be pressed, including a full one.** Owner's clarification, 2026-08-09: *"if it is
already full, yes, the class can still be pressed to see the materials — there is just no register
button when the status is full."* Being full closes the door on joining, not on finding out what is
taught; someone who arrives too late is exactly the person deciding whether to wait for the next run.

Pressing raises a sheet from the bottom of the screen carrying, in order:

- **the class's name**, as the sheet's heading
- **a picture** of the class
- **the materials, as a bulleted list** — every item, not a truncated line
- **a button at the foot of the sheet**, carrying the price with it — *Beli Kelas · HTM Rp150.000* —
  except when the class is full, where there is no button at all

Owner's decisions, 2026-08-09. The price rides on the button so it is read in the moment before it
is pressed, which is how the online class detail already works.

**It uses the same bottom sheet the app already has**, rather than a second one that behaves
slightly differently. Owner's instruction, 2026-08-09 — the existing sheet is to gain the ability to
show a list, not to be replaced by a second sheet for this screen.

**The button buys the class, and buying is not built** — see `## Out of scope`. Pressing it answers
that the app cannot do it yet, in the same words the online buy button already uses:
*"Pembelian lewat aplikasi belum tersedia."*

**The owner first asked for something else and changed it**, and both are kept because the reasoning
is worth having on the record. The instruction on 2026-08-09 was *"just show an alert that the class
has been bought."* The agent recorded it as asked and flagged that it states money has changed hands
and a place is held when neither is true — on builds that reach family through TestFlight, not just
the developer's machine. The owner then chose the honest wording. **Every unfinished action in this
app now says so plainly, with no exceptions.**

### Where it is reached from

**The Kelas Offline card on the home screen opens this screen.** It currently opens a notice saying
the feature is being built; that notice is replaced. Owner's decision, 2026-08-09.

### The three classes to start with

Taken from the owner's published September 2026 schedule, supplied as an image on 2026-08-09:

Prices below are the poster's own shorthand. What a reader sees on the screen is the wording settled
above — *"HTM Rp150.000"*.

| Class | Price | Day and date | Materials |
|---|---|---|---|
| Kelas Pizza | 150k | Rabu, 2 Sept 2026 | Black Pizza, Original Pizza, Pizza mini, Pizza gulung, Pizza sosis bite, Saus Pizza |
| Kelas Aneka Pie | 250k | Sabtu, 5 Sept 2026 | Pie Susu, Pie buah, Pie keju, Pie brownies, Pie vegetable |
| Kelas Cake & Brownies | 250k | Rabu, 9 Sept 2026 | Neapolitan cake 3 warna, Marmer cake, Banana buttercake, cup cake tape, Brownies hias, Brownies Sekat |

**The Aneka Pie date is 2026**, confirmed by the owner on 2026-08-09 after the agent raised it. The
supplied image reads *"Sabtu, 5 Sept 2025"* while the other two read 2026; the poster is wrong and
the class is 2026. Recorded rather than silently fixed, because left at 2025 the class sits in the
past and would never have appeared — and nobody would have known why.

The three classes above carry no state in the owner's poster. [ASSUMPTION] all three start as
**MASIH BISA DAFTAR**; the other two states need to be reachable for the screen to be checked, so
the sample data should not leave them unexercised.

[ASSUMPTION] **Pictures.** None were supplied. Placeholder URLs stand in, as they do everywhere else
in the app, and are replaced when the owner supplies photographs.

## Out of scope

- **Booking, paying or reserving a place.** The screen tells a reader what is on; it does not sell
  it. The same deferral already applies to the online classes.
- **Any way to add, edit or remove a class from the app.** The schedule is authored by the owner
  elsewhere; the app only shows it.
- **Recipes.** An offline class lists what will be taught, not how to cook it. The recipe screen
  belongs to the online classes.
- **A history of classes that have already run.** Once a date has passed the class leaves the
  screen; there is no archive.
- **Anything beyond the end of next month**, even if the owner has planned further ahead.
- **Notifying or reminding anyone** that a class is coming up.
- **Android.** Does not exist.

## Open questions

- **How many places a class holds.** Only the number *remaining* is needed to decide the state, so
  the total is not required and is not assumed.
- **Which state a section opens in.** Assumed open, above.
- **What the screen says when the list comes back empty or fails.** A fallback is required (see
  above); its wording is not chosen.

*Resolved on 2026-08-09, after the agent raised it as blocking:* a full class **is** pressable and
its materials **are** readable — being full removes the register button and nothing else. The two
earlier statements, *"a full class cannot be tapped"* and *"tapping is how materials are read"*,
would together have hidden the materials of every full class.

*Resolved before approval, on 2026-08-09:* the Aneka Pie year (2026), the price wording
(*"HTM Rp150.000"*), that a class dated today is shown, that a not-yet-published schedule cannot
occur, and that the state follows from the remaining places. All are recorded in the body above
rather than here.
