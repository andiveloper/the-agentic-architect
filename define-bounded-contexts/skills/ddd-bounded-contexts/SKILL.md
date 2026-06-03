---
name: ddd-bounded-contexts
description: Domain-Driven Design strategic-design heuristics for identifying bounded contexts and the context map of a codebase, and for filling out a Bounded Context Canvas per context - what a bounded context is, the signals that reveal boundaries, how to use ubiquitous-language and ACC inputs, the context-map relationship patterns (Shared Kernel, Customer/Supplier, Conformist, ACL, Open Host Service, Published Language, Partnership, Separate Ways), the Bounded Context Canvas fields (ddd-crew), and the per-context canvas fragment format. Use when discovering, analyzing, or assembling bounded contexts from a repository.
disable-model-invocation: true
---

# DDD bounded contexts

Reusable knowledge for identifying [bounded contexts](https://martinfowler.com/bliki/BoundedContext.html) and the [context map](https://martinfowler.com/bliki/BoundedContext.html) - the strategic design - **as it appears in an existing codebase**, and for documenting each context as a [Bounded Context Canvas](https://github.com/ddd-crew/bounded-context-canvas). The output is meant to be reviewed and refined with architects and teams. Discovery heuristics for unknown repos live in `repo-discovery`; this skill is the source of truth for **what** a bounded context is, **how** to map the relationships between them, and **how** to fill out a canvas per context.

## Strategic-design principles (apply everywhere)

1. **Boundaries follow the model and its language.** A bounded context is a boundary within which a domain model and its ubiquitous language are internally consistent: a term has exactly one meaning. The clearest boundary signal is the **same word meaning different things** (e.g. `Order` in Sales vs `Order` in Shipping) or different words for the same concept across areas.
2. **A context owns its model and (usually) its data.** Prefer boundaries where a cluster of types/aggregates, their language, and their persistence belong together and are not shared wholesale with other areas.
3. **Always map relationships.** Identifying contexts is only half the work; classify how each pair of related contexts integrates and in which direction (upstream/downstream). A list without a context map is incomplete.
4. **Evidence-or-gap.** Every context and relationship cites the artifact(s) it came from `(evidence: services/billing/)`. Weakly evidenced boundaries are marked `Inferred:` and low-confidence. If something cannot be determined, emit `> TODO (human input needed): <what to confirm>` - never guess.
5. **Always explain abbreviations.** Never leave a bare acronym in a diagram, table, or sentence. Expand it on first use with a short explanation - `OHS (Open Host Service)`, `ACL (Anti-Corruption Layer)`, `U`/`D` = upstream/downstream - and add a one-line legend beneath any diagram that uses abbreviations.
6. **Pitch it for an architect bridging business and development - neither too technical nor too abstract.** The reader is a software architect who will use each canvas to talk with both **business** and **development**, so work at the level of *subdomains and capabilities*: concrete enough that developers recognize the system (name the key aggregate, the defining event, the owned data store, the real integration seam - terms verbatim), but framed in business language (Purpose, value, relationships) a stakeholder can follow. Don't drift to either extreme: avoid a low-level code inventory (do **not** enumerate individual functions, methods, classes, files, endpoints, or columns - capture only the few that genuinely characterize the context and summarize the rest), and equally avoid vague abstractions that give the team nothing to act on. A context's Purpose and rationale are 1-2 short sentences; each canvas field lists only the handful of items that matter. The `(evidence: <path>)` tag is a lightweight provenance pointer for traceability only - never the subject of an entry. When in doubt, summarize and omit rather than list.

## What is a bounded context (vs not)

A bounded context is **not** the same as:

- a single class or aggregate (too small - aggregates live *inside* a context),
- a technical layer (`controllers`, `services`, `repositories` are horizontal slices, not contexts),
- a microservice by definition (a service *may* equal a context, but services can split or share a context).

A candidate bounded context typically corresponds to a **subdomain / capability** - Sales, Billing, Catalog, Identity, Shipping, Notifications - with its own consistent language and model.

## Boundary signals (where to look)

Use whatever the repo actually has; always have a "none found" answer. Combine several signals before drawing a boundary.

- **Language clusters**: distinct ubiquitous-language groups; the same term meaning different things; different terms for one concept. (Strongest signal; seed from `docs/ubiquitous-language.md` if present.)
- **Module / service / package structure**: top-level modules, `services/`, `apps/`, `packages/`, deployable units, separate manifests.
- **Data ownership**: separate databases, schemas, or table groups; distinct migration sets; per-area data stores.
- **API / integration seams**: separate OpenAPI/GraphQL/`.proto` surfaces, message topics/queues, event namespaces, public clients between areas.
- **Team / ownership boundaries**: `CODEOWNERS`, directory ownership, per-area maintainers (Conway's law).
- **Deployment / runtime units**: separate Dockerfiles, charts, pipelines, runtimes.
- **Aggregate clusters**: groups of entities that change together and reference each other but not other groups.

Prefer breadth-first sampling over reading everything; cite representative files. For a flat or tiny repo, a single bounded context covering the whole repo is a valid (and honest) answer.

## Using the optional inputs

- **Ubiquitous language (`docs/ubiquitous-language.md`)**: its **Domain classification** areas are the best seed for candidate contexts; its discussion points (synonyms, conflicting use) often pinpoint boundaries. Note that domain areas there are a *rough* grouping - here you refine them into true contexts with owned models and relationships.
- **ACC (`docs/architecture-communication-canvas.md`)**: the **Components / Modules** section gives structural candidates; **Core Functions** and **Value Proposition** help name contexts by capability and judge which are core vs supporting/generic subdomains.

If neither input is available, derive contexts from code signals only and state in the output that boundaries were derived from code, not product vision/strategy (lower confidence).

## The Bounded Context Canvas

Each context is documented as a [Bounded Context Canvas](https://github.com/ddd-crew/bounded-context-canvas) (ddd-crew, CC BY 4.0): a one-page description of a single context's design. Fill the sections below. Many are strategic/operational and **cannot be derived from code** - emit `> TODO (human input needed): <what to confirm>` for those rather than guessing. Always keep model/term names verbatim and attach `(evidence: <path>)` to every code-derived claim.

- **Name** - the context name (verbatim from the code/language where possible).
- **Purpose** - a few sentences in **business language** (no technical detail) on the why and what of the context, and the key actors it serves. Often partly inferable from the ACC; otherwise a TODO.
- **Strategic Classification** - three independent axes:
  - *Domain*: `core` (key strategic differentiator) | `supporting` (necessary, not a differentiator) | `generic` (common, off-the-shelf capability).
  - *Business Model*: `revenue generator` | `engagement creator` | `compliance enforcer` (usually a TODO unless the ACC/strategy says so).
  - *Evolution* (Wardley): `genesis` | `custom built` | `product` | `commodity` (usually a TODO).
- **Domain Roles** - how the context behaves, e.g. `analysis` (crunches data into insight), `execution` (enforces a workflow), `gateway`, `draft`, `audit`. Infer from code behavior; flag uncertain ones.
- **Inbound Communication** - collaborations **initiated by others**. For each: the *message(s)* and their type (`command` = do something, `query` = ask for information, `event` = something happened), the *collaborator* (another context, a frontend, direct user interaction, an external system), and the *relationship type* (a context-map pattern, see below).
- **Outbound Communication** - collaborations **initiated by this context** toward others; same message types and notations as inbound.
- **Ubiquitous Language** - key domain terms in this context and what they mean (seed from `docs/ubiquitous-language.md` if present; keep terms verbatim).
- **Business Decisions** - key business rules and policies enforced in the context (e.g. invariants, validations, pricing/refund rules).
- **Assumptions** - design decisions made without full knowledge; make them explicit. Usually a TODO unless code comments/ADRs reveal them.
- **Verification Metrics** - metrics that would tell the team whether the boundary is a good fit (from CI/CD, issue trackers, or live systems). Usually a TODO.
- **Open Questions** - unanswered questions about the design; fold in the boundary/relationship `TODO`s discovered during analysis.

## Context-map relationship patterns

Classify each relationship between two related contexts using these patterns. Mark direction where evident: **U** = upstream (influences), **D** = downstream (is influenced).

- **Partnership** - two contexts succeed or fail together; coordinated, bidirectional.
- **Shared Kernel** - they share a common subset of model/code; changes require mutual agreement.
- **Customer/Supplier** - downstream (customer) needs drive upstream (supplier) planning.
- **Conformist** - downstream simply conforms to the upstream model with no translation.
- **Anti-Corruption Layer (ACL)** - downstream isolates itself with a translation layer to avoid upstream's model leaking in.
- **Open Host Service (OHS)** - upstream exposes a well-defined protocol/API for many consumers.
- **Published Language** - a shared, documented interchange format (e.g. published schema/events) between contexts.
- **Separate Ways** - no integration; the contexts are intentionally decoupled.
- **Big Ball of Mud** - flag (as a risk/discussion point) when no clear boundary exists and models are tangled.

Cite the integration evidence for each relationship (client call, shared library, event topic, schema, etc.). If the relationship type cannot be determined, record the link with a `> TODO`.

### Context map: required mermaid diagram

The index (`docs/bounded-contexts.md`) MUST render the context map as a mermaid diagram (one node per context, one edge per relationship, the pattern as the edge label, direction from upstream to downstream), built from the relationships table - it is not optional. Keep prose concise: prefer the diagram and the tables over paragraphs; a context's Purpose/rationale is 1-2 short sentences.

Mermaid guardrail (so the diagram renders): no spaces in node IDs (use the lowercased context name); put the display name in brackets (`sales["Sales"]`); quote any label containing `/`, `(`, `)`, or `:` - e.g. `sales -->|"Customer/Supplier"| delivery`; no styling, colors, or `click` directives.

Always explain abbreviations: directly beneath the diagram add a one-line **Legend** expanding every pattern abbreviation actually used as an edge label (e.g. `OHS = Open Host Service`, `ACL = Anti-Corruption Layer`) and the direction convention (arrows point upstream -> downstream; `U` = upstream, `D` = downstream). Never leave a bare acronym in a diagram, table, or sentence without expanding it on first use - `OHS (Open Host Service)`.

## Per-context canvas fragment format (returned by each subagent)

Each `bc-context-analyzer` returns one **filled Bounded Context Canvas** plus a short relationships/discussion block the orchestrator uses to build the index context map. Keep names verbatim, attach `(evidence: <path>)` to every code-derived claim, write `none found` for empty sections, and use `> TODO (human input needed): <...>` for anything not determinable from code.

```markdown
### Context: <context name>

- Confidence: <high|medium|low>
- Paths: <dir(s)/module(s)> (evidence: <path>)

#### Purpose
<business-language why/what + key actors, or TODO>

#### Strategic Classification
- Domain: <core | supporting | generic | unknown> (evidence: <path>)
- Business Model: <revenue generator | engagement creator | compliance enforcer | TODO>
- Evolution: <genesis | custom built | product | commodity | TODO>

#### Domain Roles
- <role, e.g. execution / analysis / gateway> (evidence: <path>)

#### Inbound Communication
| Message | Type (command/query/event) | Collaborator | Relationship type |
| --- | --- | --- | --- |
| <message> | <type> | <context/frontend/user/external> | <pattern> (evidence: <path>) |

#### Outbound Communication
| Message | Type (command/query/event) | Collaborator | Relationship type |
| --- | --- | --- | --- |
| <message> | <type> | <context/frontend/user/external> | <pattern> (evidence: <path>) |

#### Ubiquitous Language
- `<Term>` - <meaning> (evidence: <path>)

#### Business Decisions
- <key rule/policy> (evidence: <path>)

#### Assumptions
- <assumption, or TODO>

#### Verification Metrics
- <metric, or TODO>

#### Open Questions
- <open question / unresolved boundary or relationship TODO>

#### Owned data
<stores/schemas/tables, or "none found"> (evidence: <path>)

Relationships (for the index context map):
- <other context> - <pattern: e.g. Customer/Supplier (D), ACL, OHS> - <integration evidence> (evidence: <path>)

Discussion points (for the index):
- <ambiguous boundary, possible split/merge, shared term, etc.> (evidence: <path>)
```

The canvas sections feed `docs/bounded-contexts/<context>.md`; the trailing **Relationships** and **Discussion points** blocks feed the index `docs/bounded-contexts.md` (context map + discussion points).

## HTML overview per canvas

Alongside each markdown canvas, produce a single-page **HTML overview** that renders the canvas in the visual ddd-crew Bounded Context Canvas layout (Purpose / Strategic Classification / Domain Roles across the top; Inbound Communication, Ubiquitous Language + Business Decisions, Outbound Communication in the middle; Assumptions / Verification Metrics / Open Questions across the bottom; Owned data footer). The template is `assets/canvas-template.html` - a self-contained file (inline CSS, no JS or external assets) with `{{TOKEN}}` slots and per-cell fill instructions.

Render it by **filling the template from the markdown, not by parsing it with a script**: the markdown's exact shape varies between runs and models, so a brittle parser would silently drop content. Transcribe the markdown into the template's cells verbatim - keep domain terms, every `(evidence: <path>)` tag, and every `> TODO (human input needed)` line - using the template's helper spans (`<code>`, `<span class="evidence">`, `<span class="todo">`). Clone the example item markup once per table row / bullet / term, follow the cell comments, strip the leading instruction comment block, and keep the wrapper tags, class names, and `<style>` block unchanged so every overview looks identical.

## Updating existing outputs (re-run)

These artifacts are re-runnable. When a canvas or the index already exists, merge into it rather than replacing it: keep human-authored edits and any `TODO (human input needed)` a human has since answered, refresh fields against the current code, add newly evidenced items, and rebuild the index contexts table and context-map mermaid diagram from the current set. Reuse existing context slugs so refreshed canvases land on the same files; a context that lost its evidence is marked retired in the index rather than silently deleted. These templates and conventions are authoritative over whatever shape the existing files have - they may predate changes to the canvas fields, the file layout (single file vs per-context files), the index/context-map format, or the diagram-vs-prose balance. Re-shape existing outputs to match the current templates and migrate preserved human content into the new structure rather than keeping the old layout.
