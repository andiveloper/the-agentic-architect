---
name: define-bounded-contexts
description: Orchestrates discovery of Domain-Driven Design bounded contexts and the context map for the current repository. Detects optional ACC and ubiquitous-language inputs, discovers candidate contexts, analyzes each via parallel subagents, then merges them into a single Markdown artifact (bounded contexts + context map with relationship patterns + discussion points). Invoke explicitly as /define-bounded-contexts.
disable-model-invocation: true
---

# Define Bounded Contexts

Orchestrates discovery of [Domain-Driven Design](https://martinfowler.com/bliki/BoundedContext.html) **bounded contexts** and the **context map** (the relationships between them) for the repository currently open in the workspace.

## Goal

Identify the real boundaries in the system - where one model/language ends and another begins - and how those contexts relate (integration patterns). The result is a strategic-design artifact for architects and teams to validate and refine, not a final truth. This goal drives every rule below:

- **Boundaries follow the model, not just the folders.** A bounded context is where a term has one consistent meaning. The same word meaning different things in different places is a strong boundary signal; matching folder names are only one piece of evidence.
- **Map the relationships, not just the boxes.** A list of contexts without a context map is half the value. Always classify how contexts integrate (see the relationship patterns in `ddd-bounded-contexts`).
- **Evidence-or-gap.** Every context and relationship cites a real artifact. Boundaries with weak evidence are marked low-confidence / `Inferred:`; unknowns become `> TODO (human input needed)` placeholders, never invented.

You coordinate; the per-context `bc-context-analyzer` subagents do the analysis in their own context windows. Read the `ddd-bounded-contexts` skill for the boundary signals, relationship patterns, and output template, and the `repo-discovery` skill for black-box scanning. Keep your own context lean: pass instructions to subagents and consume only their compact fragments.

## Optional inputs improve quality

Two artifacts produced by sibling tools, if present, sharpen the analysis far beyond what code structure alone allows:

- `docs/architecture-communication-canvas.md` (from `/build-architecture-communication-canvas`) - product vision, value proposition, core functions, and components.
- `docs/ubiquitous-language.md` (from `/discover-ubiquitous-language`) - the domain language and rough domain classification, the single best seed for context boundaries.

**Detect both before doing anything else.** If at least one exists, use it. If **both are missing**, you must ask the user how to proceed (see step 0) - because without them, bounded contexts can only be derived from existing code, not the product vision or strategy, which materially lowers quality.

## The subagent

`bc-context-analyzer` - a readonly per-context analyzer. There is one subagent *type*, spawned once per candidate bounded context (scoped to that context's paths). Launch them with the Task tool, all in a single message (parallel).

## Workflow

Copy this checklist and track progress:

```
- [ ] Step 0: detect optional inputs; if both missing, ask the user (run-first vs proceed code-only)
- [ ] Discover candidate bounded contexts (repo-discovery + available inputs)
- [ ] Analyze each context: one bc-context-analyzer per candidate (parallel)
- [ ] Merge contexts; classify relationships into a context map
- [ ] Assemble and write docs/bounded-contexts.md
- [ ] Summarize context count, relationships, and discussion points / TODOs
```

### Step 0 - Detect optional inputs and decide

1. Check whether `docs/architecture-communication-canvas.md` and `docs/ubiquitous-language.md` exist.
2. If at least one exists, note which, and continue to step 1 (use whatever is available).
3. If **both are missing**, ask the user with the AskQuestion tool, offering these choices:
   - **Run the other tools first** - run `/build-architecture-communication-canvas` and/or `/discover-ubiquitous-language` now, then continue with their outputs. (Recommended - highest quality.)
   - **Proceed code-only** - derive bounded contexts from existing code structure alone. Make clear this has a **negative impact on quality**: contexts come from code, not the product vision or strategy.
   Honor the choice. If the user picks run-first, follow those skills' workflows (or wait for the user to run the commands) before continuing. If the user proceeds code-only, record this so the output document carries an explicit "derived from code only" note.

### 1 - Discover candidate bounded contexts

1. Use `repo-discovery` to scan the repo black-box: list the tree, read root docs, enumerate top-level modules/packages/services, data stores, and deployment units.
2. Seed candidates from available inputs: the ubiquitous-language **domain classification** (each area is a candidate context), and the ACC **Components / Modules** section.
3. Derive a list of candidate contexts as `{context name, paths}` using the boundary signals in `ddd-bounded-contexts`. A small or flat repo may collapse to a single context covering the whole repo.

### 2 - Analyze each context (parallel)

1. Launch one `bc-context-analyzer` subagent per candidate in a single parallel message. In each prompt include: the context name, that context's paths, the repository root path, and any relevant excerpts from the ACC / ubiquitous-language docs (inline them; subagents start with clean context).
2. Instruct each to return only the per-context fragment defined in `ddd-bounded-contexts` (boundary summary, responsibility, core model/language terms, owned data, integration points/relationships to other contexts, evidence tags, and TODOs).

### 3 - Merge and build the context map

1. Collect the fragments. Reconcile overlapping or duplicated contexts; merge or split where the evidence warrants and note why.
2. From each context's integration points, classify the relationships between contexts using the patterns in `ddd-bounded-contexts` (Partnership, Shared Kernel, Customer/Supplier, Conformist, Anti-Corruption Layer, Open Host Service, Published Language, Separate Ways). Mark direction (upstream/downstream) where evident.
3. Compile **discussion points**: ambiguous boundaries, contexts that may need splitting or merging, the same term spanning contexts, and undetermined relationships.

### Assemble and write

1. Load the template from the `ddd-bounded-contexts` skill (`assets/template.md`).
2. Fill it: purpose framing line (including the "derived from code only" note if applicable), the bounded-context list, the relationships / context-map section with the mermaid diagram, and Discussion points / possible gaps. Preserve every evidence tag and TODO placeholder.
3. Write the result to `docs/bounded-contexts.md` (create the `docs/` directory if needed). If the file exists, confirm overwrite with the user.
4. Report a short summary: number of contexts, the relationships in the map, and the discussion points / unresolved TODOs to take to the team.

## Rules

- Black-box: never assume language, framework, or layout (see `repo-discovery`).
- Boundaries follow the model and the language, not folder names alone.
- Always produce a context map, not just a list of contexts.
- Evidence-or-gap: every context and relationship cites a real artifact; unknowns become `> TODO (human input needed)` placeholders, never guessed.
- If both optional inputs are missing, never silently skip - ask, and record the user's choice in the output.
