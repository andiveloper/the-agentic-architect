---
name: arc42-acc-canvas
description: Defines the arc42 Architecture Communication Canvas (ACC) - its nine categories, the output Markdown template, evidence/TODO conventions, and final assembly rules. Use when building, assembling, or formatting an ACC document, or when a subagent needs the canonical definition and source-vs-human guidance for a canvas category.
disable-model-invocation: true
---

# arc42 Architecture Communication Canvas (ACC)

Canonical knowledge for producing an [Architecture Communication Canvas](https://canvas.arc42.org/architecture-communication-canvas): "the shortest possible description of your architecture." This skill is the source of truth for **what** each section means and **how** the final document is formatted. Discovery heuristics live in `repo-discovery`; gap handling lives in `acc-gap-analysis`.

## The nine categories

Grouped into three areas. Each line: category - owning subagent - one-line intent.

**Requirements (what should the system do?)**
- Value Proposition - `acc-value-proposition` - core business case / economic driver / major objectives.
- Key Stakeholder - `acc-key-stakeholder` - for whom value is created; who pays, contributes, benefits.
- Core Functions - `acc-core-functions` - most important functions, features, use-cases, processes.
- Quality Requirements - `acc-quality-requirements` - quality goals (speed, scalability, reliability, usability, security, safety, capacity, flexibility).

**Solution (how is it done?)**
- Business Context - `acc-business-context` - important external interfaces, neighbouring systems, actors/roles.
- Components / Modules - `acc-components-modules` - major building blocks, subsystems, modules, services.
- Core Decisions (Good or Bad) - `acc-core-decisions` - decisions that led to the current state.
- Technologies - `acc-technologies` - important technologies for development and operation.

**Problems & risks**
- Risks and Missing Information - `acc-risks-missing-info` - known problems, risks, and what information is missing or lost.

See [references/field-reference.md](references/field-reference.md) for the full arc42 prompting questions per category.

## Confidence and evidence conventions

Every category section MUST follow these conventions so the document is trustworthy and auditable.

1. **Evidence tags.** Each derived statement ends with an evidence tag citing the concrete artifact(s) it came from:
   `(evidence: package.json, .github/workflows/ci.yml)`. For human-provided input use `(source: user input)`; for an ingested document use `(source: docs/strategy.md)`.
2. **No invention.** If something cannot be determined from the repository or provided inputs, do NOT guess. Emit a placeholder:
   `> TODO (human input needed): <specific question to answer>`
3. **Confidence label.** Begin each section body with a confidence line: `Confidence: high | medium | low` reflecting how much rests on direct evidence versus inference.
4. **Inference marker.** Statements that are reasoned rather than directly evidenced are prefixed with `Inferred:` and still carry an evidence tag for the signals they were inferred from.

## Diagrams (prefer over prose)

Two sections are inherently structural and MUST lead with a mermaid diagram, followed by tight evidence bullets (diagram nodes cannot carry `(evidence: ...)` tags, so evidence lives in the bullets beneath):

- **Business Context** - a context diagram: the system as one central node, each neighbouring system / external interface / actor as a node, edges showing direction (an inbound source points *into* the system; an outbound sink is pointed *to* by the system).
- **Components / Modules** - a component diagram: each major building block a node, dependencies/calls as edges.

Every other section stays concise: prefer tight bullet lists over prose, and a diagram over a list wherever it communicates better.

Every diagram is self-explanatory: precede it with a one-line caption saying what it shows, and if any node or edge label uses an abbreviation, add a short legend beneath expanding it.

### Always explain abbreviations

Never leave a bare acronym anywhere in the canvas (diagram, table, or sentence). Expand it on first use with a short explanation - e.g. `CI (Continuous Integration)`, `SLO (Service Level Objective)`, `ADR (Architecture Decision Record)`, `JWT (JSON Web Token)`. This keeps the canvas readable by non-experts.

### Mermaid guardrail

So generated diagrams render:
- No spaces in node IDs (use camelCase or underscores); put the human label in brackets: `taskflow["Taskflow API"]`.
- Quote any edge or node label containing `/`, `(`, `)`, or `:` - e.g. `a -->|"Customer/Supplier"| b`.
- Do not add styling, colors, or `click` directives - let the default theme apply.

## Output template

The final document follows [assets/template.md](assets/template.md) exactly. It is written to `docs/architecture-communication-canvas.md` by default. The template:
- Keeps the three-area grouping and all nine sections in canonical order.
- Includes a short header (system name, generation date, repo identifier if known).
- Ends with a "Provenance" note listing which sections used user input vs. repo evidence.

## HTML overview

A one-page, canvas-styled HTML overview can be generated from the Markdown using [assets/canvas-template.html](assets/canvas-template.html). It lays out the three areas as columns (Requirements / Solution / Problems & risks) with a full-width Value Proposition band, gray section cards with confidence badges, evidence/TODO styling, and in-browser mermaid rendering. The `acc-canvas-html` subagent fills this template **faithfully** from the Markdown - it is a renderer, never an analyst, and adds no facts. The fill rules and Markdown -> HTML mapping live in the template's top comment. Output defaults to `docs/architecture-communication-canvas.html`.

## Assembly rules (orchestrator)

When assembling fragments returned by the category subagents:

1. Insert each subagent's fragment under its matching section heading, unchanged except for trivial whitespace.
2. Preserve every evidence tag, `TODO (human input needed)` placeholder, and mermaid diagram block verbatim.
3. For **Risks and Missing Information**, append the de-duplicated union of all `TODO`/gap items surfaced by the other eight subagents, grouped under a "Missing information" subheading, after the risk findings.
4. Do not collapse or summarize away placeholders - unresolved gaps must remain visible.
5. Fill the header fields (system name, date, repo) from evidence where possible; otherwise mark them as TODO.
6. Keep the document concise: the ACC is meant to be short. Prefer tight bullet lists over prose; trim subagent output that drifts long.
7. **Updating an existing canvas (re-run):** when `docs/architecture-communication-canvas.md` already exists, merge into it rather than replacing it. Keep human-authored edits and any `TODO (human input needed)` that a human has since answered (look for `(source: user input)` and hand-written notes). Refresh each section against the current code, add newly evidenced items, and mark findings that lost their evidence as stale instead of deleting them silently. Update only the header date. **This template and these conventions are authoritative over whatever shape the existing file has** - it may predate changes to the section set, layout (single vs multiple files), diagram-vs-prose balance, or evidence/TODO format. Re-shape the existing document to match the current template and migrate preserved human content into the new structure rather than keeping the old layout.
