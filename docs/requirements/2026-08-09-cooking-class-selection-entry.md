---
status: approved
date: 2026-08-09
author: owner
drafted-by: agent
approved: 2026-08-09
---

# Choosing between an online and an offline class

## Who this is for

Someone who opens the Dapur Naura app and has to decide which of the two things the business
actually sells they came for. Dapur Naura teaches **online** classes and **offline** classes; the
app today shows only the online catalogue, and shows it immediately, so a visitor is given no
choice and never learns the offline classes exist.

[ASSUMPTION] The owner described the change, not the person it serves. The paragraph above is the
agent's reading of who benefits.

## What they need

**The app opens on a choice between the two kinds of class, not on the class list.**

The owner's instruction, given in mixed Bahasa Indonesia and English on 2026-08-09 and recorded
here as the agent's English translation per DN-010:

> "Let's develop another screen. I want to change the entry screen. At the moment ListCookingClass
> is the entry. I want it changed to CookingClassSelection. What I mean is, Dapur Naura's cooking
> classes are split into 2, Class Online and Class Offline, but the Class written in Bahasa which is
> Kelas. What we are developing at the moment is Kelas Online.
>
> I want the class Selection to look like this [a reference image was supplied], it does not need
> data from remote, this is only static data. If Kelas Online is pressed, then navigate to
> ListCookingClass. If Kelas Offline is pressed, show a bottom sheet containing a Placeholder Image
> with a fixed height size and text describing that the feature is being built, please wait."

Answering the agent's questions the same day:

> "3. No need for a button at the bottom of the bottom sheet, insert a floating view with an X icon
> that indicates that if you want to close the bottom sheet, you press this floating view.
>
> NOTE: By the way, make this bottom sheet a component that will be shared across screens, make it
> customisable, such as receiving an image and also text in its init parameters. WDYT?
>
> 4. Kelas Offline still looks normal.
>
> 5. Yes there is a back button, and the title becomes Kelas Online.
>
> No pictures needed, only a placeholder URL like recipe.json. The title is Dapur Naura. The card
> colours are pink and salmon, per the image."

### The first thing the app shows

A screen headed **Dapur Naura**, offering exactly two choices. **Nothing is fetched** — the two
choices are fixed, and the screen is drawn with no loading, no failure and no retry, because there
is nothing that can fail.

### The two choices

| Choice | What pressing it does |
|---|---|
| **Kelas Online** | Opens the cooking-class list, which the user can leave with a back button to return here |
| **Kelas Offline** | Shows a notice that the feature is still being built |

**Both choices look equally available.** Kelas Offline is not dimmed, greyed out, marked
*coming soon* or made unpressable — it is pressed like any other, and the notice is what answers
it. Owner's decision, 2026-08-09.

**The class list is retitled "Kelas Online".** It is titled *Kelas Masak* today; once it sits behind
this choice, its title names the choice that led there. Owner's decision, 2026-08-09.

### The notice for something not built yet

Presented as a sheet from the bottom of the screen, containing:

- **a picture at a fixed height** — the same height whatever picture it is given, so the notice
  does not change size with its content;
- **wording saying the feature is being built and asking the user to wait**;
- **a floating control marked with an X**, which is how the notice is closed. There is no button
  along the bottom of the sheet.

**The notice must be reusable, not built for this one case.** Whoever shows it supplies the picture
and the wording; the notice itself owns only how it looks and how it closes. Owner's instruction,
2026-08-09.

> The reason this is a requirement and not an implementation note: the same *"not built yet"*
> message already exists elsewhere in the app, worded separately. A notice that only Kelas Offline
> can show guarantees the next unfinished feature words it a third way, and §7 of the iOS codebase
> architecture requires one vocabulary for the whole app.

### Pictures

**No artwork is supplied and none is needed yet.** Every picture on this screen and in the notice
is a placeholder URL in the same style the contract fixtures already use
(`https://placehold.co/...`). Owner's decision, 2026-08-09. They are replaced with real pictures
when the owner supplies them, and that replacement changes no behaviour.

### Appearance

The two choices are cards stacked vertically, each with rounded corners, a picture overlapping the
top of the card, a large title, and one line of description beneath it. **The cards are coloured
pink and salmon**, following the reference image the owner supplied on 2026-08-09.

## The wording

**[ASSUMPTION] Every line below was written by the agent, not the owner** — the owner supplied the
screen title and the two card names, and the agent proposed the rest. **The owner read the table and
accepted it in full on 2026-08-09** (*"Untuk assumption saya setuju semua dengan saran anda"*), which
is what makes it a requirement; the tag stays because it records who authored the words, and that
does not stop being true once they are approved.

Per the platform rule, all of it is Bahasa Indonesia and none of it is translated.

| Where | Text |
|---|---|
| Screen title | Dapur Naura |
| First card | **Kelas Online** — Belajar masak dari rumah lewat video dan resep |
| Second card | **Kelas Offline** — Belajar langsung bersama di Dapur Naura |
| Notice title | Segera Hadir |
| Notice body | Kelas Offline sedang kami siapkan. Mohon ditunggu, ya. |

## Out of scope

- **Building the offline classes themselves.** This delivers the choice and the notice, nothing
  behind it.
- **Any server involvement.** The choice is static, and no endpoint, contract or data-layer change
  comes with it.
- **Rewording or restyling the existing "purchase not available" message.** It is the obvious
  second user of the reusable notice, but changing a message on a screen the owner did not ask
  about belongs in its own piece of work.
- **Remembering the choice.** The app opens on this screen every time; it does not skip straight to
  the class list because the user chose online last time.
- **Anything else about the class list.** Its content, its category filter and its behaviour are
  unchanged — only its title and the fact that it is now reached by pressing something.

## Open questions

- **What the offline notice should eventually picture.** A placeholder stands there now, and no
  decision has been made about what replaces it.

*Resolved before approval:* the wording table was the agent's proposal and the owner accepted it in
full on 2026-08-09. It is recorded above rather than here.
