---
name: ddd-ubiquitous-language
description: Domain-Driven Design heuristics for discovering the ubiquitous language of a codebase - what counts as a domain term vs technical jargon, where to mine terms, how to write plain-language definitions, how to group terms into a rough domain classification, and how to surface discussion points for review with domain experts. Use when extracting or assembling a ubiquitous-language glossary from a repository.
disable-model-invocation: true
---

# DDD ubiquitous language

Reusable knowledge for discovering the [ubiquitous language](https://martinfowler.com/bliki/UbiquitousLanguage.html) - the shared vocabulary of the business domain - **as it appears in an existing codebase**. The output is meant to be reviewed with non-technical domain experts to find gaps and misunderstandings between code and domain. Discovery heuristics for unknown repos live in `repo-discovery`; this skill is the source of truth for **what** a domain term is and **how** to present it.

## Review-with-experts principles (apply everywhere)

1. **Mirror the code, do not sanitize it.** Record each term exactly as it appears in the code (casing, abbreviation, plural/singular). Keep notable variants (`custOrd`, `CustomerOrder`, `cust_order`) - never normalize or invent a "better" name. Inconsistencies are signal, not noise.
2. **Plain-language definitions.** One short, jargon-free sentence describing what the term appears to mean *in the domain*, never how it is implemented. A non-technical reader must be able to confirm or refute it. If meaning is unclear, do not guess - emit a TODO. When a term is an abbreviation or acronym (e.g. `POD`, `SKU`), always expand it in the definition - or, if it cannot be expanded with confidence, make that the explicit question in the TODO.
3. **Evidence-or-gap.** Every term carries an evidence tag citing the artifact(s) it came from: `(evidence: src/orders/Order.java)`. If meaning cannot be determined, emit `> TODO (human input needed): <what to ask the expert>`.
4. **Surface discussion points.** Flag, for expert review: synonyms / near-duplicates pointing at one concept; the same word used with different meanings in different areas; unclear abbreviations; and undetermined-meaning terms.
5. **Pitch it for an architect bridging business and development - neither too technical nor too abstract.** The reader is a software architect who will use this artifact to talk with both **business** (domain experts) and **development**. So work at the level of the domain *concepts* both sides would recognize: keep the term verbatim from the code (the anchor developers act on) but explain it in plain domain language (so business can validate it). Do **not** drift to either extreme: avoid low-level implementation detail (individual functions, methods, files, modules, internal variables - those are not ubiquitous language), and equally avoid vague, generic abstractions that no longer point at anything concrete in the system. A term earns a row because it names a real, shared domain concept (a noun, status, event, role, activity). The `(evidence: <file>)` tag is a lightweight provenance pointer for traceability only - never the subject of the entry, and never something to elaborate on in the definition.
6. **Focus on the most important terms; stay concise.** This is a review artifact, not an exhaustive index. Prioritize the core domain nouns, verbs, statuses, events, and roles a domain expert would actually recognize and care about; do not pad the glossary with low-signal or near-duplicate technical names. This does not conflict with "mirror the code": every term you *do* keep stays verbatim, and notable variants/synonyms worth discussing are still surfaced - as discussion points rather than extra glossary rows. Keep each definition to one short, jargon-free sentence. Prefer tables over prose throughout. When in doubt, summarize and omit rather than list - a tight glossary of the concepts that matter beats an exhaustive catalog.

## What counts as ubiquitous language

Include domain concepts a business person would recognize:

- **Domain nouns / entities**: `Order`, `Delivery Note`, `Invoice`, `Customer`, `Shipment`, `Tariff`.
- **Domain verbs / activities**: `Fulfill`, `Cancel`, `Settle`, `Reconcile`, `Dispatch`.
- **Lifecycle / status terms**: order states like `Draft`, `Confirmed`, `Backordered`; enum values.
- **Domain events / commands**: `OrderPlaced`, `PaymentCaptured`, `ShipmentDispatched`.
- **Roles / actors**: `Merchant`, `Courier`, `Account Manager`.

Exclude purely technical or framework jargon that carries no domain meaning:

- Pattern/plumbing names when used only technically: `Controller`, `DTO`, `Repository`, `Factory`, `Mapper`, `Helper`, `Util`, `Manager` (keep them only if they clearly name a domain concept, e.g. `RiskRepository` as a business register).
- Infra/tech terms: `Logger`, `Config`, `HttpClient`, `Serializer`, `Cache`, `Thread`, framework class names.
- Generic CRUD verbs with no domain nuance: `get`, `set`, `save`, `update`, `delete` (keep domain-specific ones like `void`, `refund`, `accrue`).

When unsure whether a term is domain or technical, keep it and add it as a discussion point rather than dropping it.

## Where to mine terms (signals)

Use whatever the repo actually has; always have a "none found" answer.

- **Type/class/interface names**, especially aggregate roots and entities.
- **Enum values and constants** (rich source of statuses and categories).
- **Database schema**: table and column names, migrations.
- **API surface**: REST resource paths, GraphQL types, `.proto` messages, route/handler names.
- **Events/commands/messages**: event class names, queue/topic names, handler names.
- **Domain method names** that express business operations (not generic getters/setters).
- **Domain errors / validation messages / status strings**.
- **Docs**: README, domain/glossary docs, comments describing business rules.

Prefer breadth-first sampling over reading everything; cite representative files.

## Rough domain classification

Group the discovered terms into a handful of candidate domain areas (subdomains) - this is a *rough* grouping for discussion, not a rigorous bounded-context analysis (that is a separate tool).

- Derive areas from top-level modules/packages/services, directory names, or natural clusters of related terms (e.g. `Orders`, `Delivery`, `Billing`, `Catalog`).
- Assign each term to its most fitting area. Terms that span areas or have no clear home go under a **Shared / cross-cutting** area.
- Keep the number of areas small (typically 3-8). If the repo is flat/small, a single area is fine.
- Present the classification as an `| Area | Terms |` table (one row per area, terms comma-separated), not a bullet list.

## Per-area fragment format (returned by each subagent)

Each `ul-domain-extractor` returns only:

```markdown
### Area: <area name>

| Term | Definition |
| --- | --- |
| <verbatim term> | <plain-language sentence> (evidence: <file>) |
| <verbatim term> | > TODO (human input needed): <what to ask the expert> (evidence: <file>) |

Suggested group: <area name> (note any terms that may belong elsewhere)

Discussion points:
- Synonyms: <term-a> / <term-b> appear to mean the same concept (evidence: ...)
- Conflicting use: <term> used differently here than in <other area> (evidence: ...)
- Unclear abbreviation: <abbr> - meaning not determinable (evidence: ...)
```

If a section has nothing to report (e.g. no discussion points), write "none found".

## Updating an existing glossary (re-run)

The glossary is re-runnable. When `docs/ubiquitous-language.md` already exists, merge into it rather than replacing it: keep human-authored edits and any `TODO (human input needed)` a human has since answered (expert-confirmed definitions, notes, manual groupings), reuse the existing domain areas as the starting classification, add newly found terms, and refresh definitions whose code evidence changed. A term that no longer appears in the code is marked stale rather than silently deleted - keep terms verbatim either way. This template and these conventions are authoritative over whatever shape the existing file has - it may predate changes to the section set, layout (single vs multiple files), table-vs-prose balance, or evidence/TODO format. Re-shape the existing glossary to match the current template and migrate preserved human content into the new structure rather than keeping the old layout.
