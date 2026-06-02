---
name: ddd-bounded-contexts
description: Domain-Driven Design strategic-design heuristics for identifying bounded contexts and the context map of a codebase - what a bounded context is, the signals that reveal boundaries, how to use ubiquitous-language and ACC inputs, the context-map relationship patterns (Shared Kernel, Customer/Supplier, Conformist, ACL, Open Host Service, Published Language, Partnership, Separate Ways), and the per-context fragment format. Use when discovering, analyzing, or assembling bounded contexts from a repository.
disable-model-invocation: true
---

# DDD bounded contexts

Reusable knowledge for identifying [bounded contexts](https://martinfowler.com/bliki/BoundedContext.html) and the [context map](https://martinfowler.com/bliki/BoundedContext.html) - the strategic design - **as it appears in an existing codebase**. The output is meant to be reviewed and refined with architects and teams. Discovery heuristics for unknown repos live in `repo-discovery`; this skill is the source of truth for **what** a bounded context is and **how** to map the relationships between them.

## Strategic-design principles (apply everywhere)

1. **Boundaries follow the model and its language.** A bounded context is a boundary within which a domain model and its ubiquitous language are internally consistent: a term has exactly one meaning. The clearest boundary signal is the **same word meaning different things** (e.g. `Order` in Sales vs `Order` in Shipping) or different words for the same concept across areas.
2. **A context owns its model and (usually) its data.** Prefer boundaries where a cluster of types/aggregates, their language, and their persistence belong together and are not shared wholesale with other areas.
3. **Always map relationships.** Identifying contexts is only half the work; classify how each pair of related contexts integrates and in which direction (upstream/downstream). A list without a context map is incomplete.
4. **Evidence-or-gap.** Every context and relationship cites the artifact(s) it came from `(evidence: services/billing/)`. Weakly evidenced boundaries are marked `Inferred:` and low-confidence. If something cannot be determined, emit `> TODO (human input needed): <what to confirm>` - never guess.

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

## Per-context fragment format (returned by each subagent)

Each `bc-context-analyzer` returns only:

```markdown
### Context: <context name>

- Confidence: <high|medium|low>
- Paths: <dir(s)/module(s)> (evidence: <path>)
- Responsibility: <one-line capability this context owns>
- Core model / language: <key aggregates/entities and domain terms, verbatim> (evidence: <files>)
- Owned data: <stores/schemas/tables, or "none found"> (evidence: <path>)
- Subdomain type: <core | supporting | generic | unknown>

Relationships (outgoing/observed):
- <other context> - <pattern: e.g. Customer/Supplier (D), ACL, OHS> - <integration evidence> (evidence: <path>)
- > TODO (human input needed): <relationship/boundary to confirm>

Discussion points:
- <ambiguous boundary, possible split/merge, shared term, etc.> (evidence: <path>)
```

If a section has nothing to report (e.g. no relationships), write "none found".
