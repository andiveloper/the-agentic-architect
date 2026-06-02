---
name: discover-ubiquitous-language
description: Orchestrates discovery of the Domain-Driven Design ubiquitous language as it actually appears in the current repository. Discovers candidate domain areas, extracts domain terms per area via parallel subagents, then merges them into a single Markdown review artifact (rough domain classification + plain-language glossary + discussion points) for review with domain experts. Invoke explicitly as /discover-ubiquitous-language.
disable-model-invocation: true
---

# Discover Ubiquitous Language

Orchestrates discovery of the [Domain-Driven Design](https://martinfowler.com/bliki/UbiquitousLanguage.html) ubiquitous language for the repository currently open in the workspace - the real domain nouns, verbs, statuses, and events baked into the code.

## Goal

Surface the language **as the existing code actually uses it** so a developer can sit down with **non-technical domain experts** and ask "is this what these words mean to you?". The output is a conversation artifact for finding **gaps and misunderstandings** between code and domain - not a polished glossary. This goal drives every rule below:

- **Mirror the code, do not sanitize it.** Capture each term verbatim as it appears (including awkward, abbreviated, inconsistent, or duplicated names like `custOrd` vs `CustomerOrder`). Never "correct" or invent better names - the mismatches are exactly what experts need to see.
- **Plain-language definitions.** Each definition is one short, jargon-free sentence describing what the term appears to mean *in the domain* (not how it is implemented), so a non-technical reader can validate or refute it.
- **Surface discussion points, not just terms.** Flag synonyms/near-duplicates for one concept, the same word used differently in different areas, unclear abbreviations, and terms whose meaning could not be determined.

You coordinate; the per-area `ul-domain-extractor` subagents do the analysis in their own context windows. Read the `ddd-ubiquitous-language` skill for the term heuristics, classification rules, and output template, and the `repo-discovery` skill for black-box scanning. Keep your own context lean: pass instructions to subagents and consume only their compact fragments.

## The subagent

`ul-domain-extractor` - a readonly per-area term extractor. There is one subagent *type*, spawned once per discovered domain area (scoped to that area's paths). Launch them with the Task tool, all in a single message (parallel).

## Workflow

Copy this checklist and track progress:

```
- [ ] Discover candidate domain areas (repo-discovery + ddd-ubiquitous-language)
- [ ] Extract terms: one ul-domain-extractor per area (parallel)
- [ ] Merge, dedupe, classify; compile discussion points
- [ ] Assemble and write docs/ubiquitous-language.md
- [ ] Summarize term count, domain groups, and discussion points / TODOs
```

### 1 - Discover candidate domain areas

1. Use `repo-discovery` to scan the repo black-box: list the tree, read root docs, enumerate top-level modules/packages/services.
2. Derive a list of candidate domain areas as `{area name, paths}` using the `ddd-ubiquitous-language` classification rules (e.g. top-level modules, services, or bounded-context-like directories). A small or flat repo collapses to a single area covering the whole repo.

### 2 - Extract terms per area (parallel)

1. Launch one `ul-domain-extractor` subagent per area in a single parallel message. In each prompt include: the area name, that area's paths, and the repository root path.
2. Instruct each to return only the per-area fragment defined in `ddd-ubiquitous-language` (terms verbatim, plain-language definitions, evidence tags, suggested domain group, and any suspected synonyms/abbreviations/ambiguities).

### 3 - Merge and classify

1. Collect the fragments. Dedupe terms (case, singular/plural) while keeping notable verbatim variants visible.
2. Reconcile conflicting definitions; assign each term to a rough domain group.
3. Compile the **discussion points**: cross-area synonyms, the same term meaning different things in different areas, unclear abbreviations, and undetermined-meaning TODOs.

### Assemble and write

1. Load the template from the `ddd-ubiquitous-language` skill (`assets/template.md`).
2. Fill it: purpose framing line, the Domain classification as an `| Area | Terms |` table, the `| Term | Definition |` glossary (most important terms, one short definition each), and the Discussion points / possible gaps section. Preserve every evidence tag and TODO placeholder.
3. Write the result to `docs/ubiquitous-language.md` (create the `docs/` directory if needed). If the file exists, confirm overwrite with the user.
4. Report a short summary: term count, the domain groups, and the discussion points / unresolved TODOs to take to domain experts.

## Rules

- Black-box: never assume language, framework, or layout (see `repo-discovery`).
- Mirror the code; keep terms verbatim. Never invent or rename terms.
- Focus on the most important terms; do not pad the glossary. Surface notable variants/synonyms as discussion points, not extra rows.
- Evidence-or-gap: every term cites a real artifact; unknowns become `> TODO (human input needed): ...` placeholders, never guessed.
- Keep the document concise and table-first, readable by non-technical domain experts.
