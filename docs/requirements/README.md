# Requirements

Human-authored requirement documents. **This is the INPUT to the workflow.**

## The one rule

**Requirement documents are immutable.** Never edit one to match what was built — that destroys
the audit trail, which is the entire point of Document Driven Development. If what was built
differs from what was asked, the correction goes in the *ticket*, not here.

## Naming

`YYYY-MM-short-slug.md` — for example `2026-08-recipe-catalogue.md`.

The date is when the requirement was written, not when it was implemented.

## What goes in one

Write in terms of what the user needs, not how to build it. The technical translation is the
agent's job and belongs in the ticket.

```markdown
# Recipe catalogue

**Date:** 2026-08-10
**Author:** <you>

## Who this is for

Which user, and what they are trying to do.

## What they need

Plain description of the behaviour. Screens, flows, data the user sees.

## Out of scope

What this deliberately does not cover — saves an argument later.

## Open questions

Anything you have not decided yet.
```

## What happens next

An agent reads the document and writes one or more tickets into [`../tickets/`](../tickets/),
each carrying a `source:` field pointing back here. That link is how anyone answers "why does
this code exist" in one hop.

See [`../ARCHITECTURE-AND-WORKFLOW.md`](../ARCHITECTURE-AND-WORKFLOW.md) for the full loop.
