# Requirements

Requirement documents. **This is the INPUT to the workflow.** The content is always the human's
decision, but the human does not have to type it.

## How one gets written

The human explains what they want — as a product owner, or as a mobile developer describing
behaviour. The agent drafts it into this folder as `status: draft`, then asks whether it is
correct. The human corrects; the agent revises. That repeats until the human approves.

```
Human explains  →  agent drafts (status: draft)  →  "is this right?"
                          ↑                              │
                          └──── no: human corrects ──────┤
                                                         │ yes
                                            status: approved  →  FROZEN
                                                         ↓
                                              agent writes tickets
```

### The agent's obligation when drafting

**Every statement must be traceable to something the human actually said.** Drafting means
structuring and transcribing, not inventing. Where the agent fills a gap on its own initiative it
must mark it, so approval is informed rather than a rubber stamp:

- `[ASSUMPTION]` — inline, for anything the agent added that the human did not say
- `## Open questions` — for anything genuinely undecided

An unmarked invention that gets approved becomes a "requirement" nobody ever asked for. That is
the one failure mode this process has, and flagging is what prevents it.

## The one rule

**An approved requirement document is immutable.** Never edit one to match what was built — that
destroys the audit trail, which is the entire point of Document Driven Development. If what was
built differs from what was asked, the correction goes in the *ticket*, not here.

Drafts are mutable. That is what `status:` is for — it marks exactly when the document freezes.

## Naming

`YYYY-MM-dd-short-slug.md` — for example `2026-08-05-recipe-catalogue.md`.

The date is when the requirement was written, not when it was implemented.

## What goes in one

Write what the user needs, not how to build it. If it names a Kotlin class or a SwiftUI view, it
has drifted into being a ticket. The technical translation is the agent's job.

```markdown
---
status: draft          # draft | approved — approved documents are frozen
date: 2026-08-10
author: <human>        # whose decisions these are
drafted-by: agent      # omit if the human wrote it directly
approved: <date>       # filled in on approval
---

# Recipe catalogue

## Who this is for

Which user, and what they are trying to do.

## What they need

Plain description of the behaviour. Screens, flows, data the user sees.
Concrete enough to check against — "loads without a visible spinner on repeat
visits", not "is fast".

## Out of scope

What this deliberately does not cover. Prevents scope creep and saves an
argument at review.

## Open questions

Anything not yet decided. The agent puts unknowns here rather than guessing.
```

## What happens next

Once approved, the agent reads the document and writes one or more **product** tickets into
[`../tickets/`](../tickets/), each carrying a `source:` field pointing back here. That link is how
anyone answers "why does this code exist" in one hop.

Work with no requirement document — testability, refactors, tooling — becomes a **technical**
ticket instead, which carries its own `## Rationale`. See
[`../ARCHITECTURE-AND-WORKFLOW.md`](../ARCHITECTURE-AND-WORKFLOW.md) for the full loop.
