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

## Output template

The final document follows [assets/template.md](assets/template.md) exactly. It is written to `docs/architecture-communication-canvas.md` by default. The template:
- Keeps the three-area grouping and all nine sections in canonical order.
- Includes a short header (system name, generation date, repo identifier if known).
- Ends with a "Provenance" note listing which sections used user input vs. repo evidence.

## Assembly rules (orchestrator)

When assembling fragments returned by the category subagents:

1. Insert each subagent's fragment under its matching section heading, unchanged except for trivial whitespace.
2. Preserve every evidence tag and `TODO (human input needed)` placeholder verbatim.
3. For **Risks and Missing Information**, append the de-duplicated union of all `TODO`/gap items surfaced by the other eight subagents, grouped under a "Missing information" subheading, after the risk findings.
4. Do not collapse or summarize away placeholders - unresolved gaps must remain visible.
5. Fill the header fields (system name, date, repo) from evidence where possible; otherwise mark them as TODO.
6. Keep the document concise: the ACC is meant to be short. Prefer tight bullet lists over prose; trim subagent output that drifts long.
