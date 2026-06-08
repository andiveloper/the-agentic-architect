---
name: define-bounded-contexts
description: Orchestrates discovery of Domain-Driven Design bounded contexts and the context map for the current repository, producing one filled-out Bounded Context Canvas (ddd-crew) per context. Detects optional ACC and ubiquitous-language inputs, discovers candidate contexts, analyzes each via parallel subagents, then renders an editable draw.io canvas per context plus a draw.io context map as the default (and only automatic) outputs under docs/bounded-contexts/. Markdown (per-context canvases + the index), HTML, and PNG are offered as optional outputs at the end and produced only on request. Invoke explicitly as /define-bounded-contexts.
disable-model-invocation: true
---

# Define Bounded Contexts

Orchestrates discovery of [Domain-Driven Design](https://martinfowler.com/bliki/BoundedContext.html) **bounded contexts** and the **context map** (the relationships between them) for the repository currently open in the workspace, documenting each context as a filled-out [Bounded Context Canvas](https://github.com/ddd-crew/bounded-context-canvas).

## Goal

Identify the real boundaries in the system - where one model/language ends and another begins - and how those contexts relate (integration patterns) - and capture each context on its own Bounded Context Canvas. The result is a strategic-design artifact for architects and teams to validate and refine, not a final truth. This goal drives every rule below:

- **Boundaries follow the model, not just the folders.** A bounded context is where a term has one consistent meaning. The same word meaning different things in different places is a strong boundary signal; matching folder names are only one piece of evidence.
- **Map the relationships, not just the boxes.** A list of contexts without a context map is half the value. Always classify how contexts integrate (see the relationship patterns in `ddd-bounded-contexts`).
- **Evidence-or-gap.** Every context and relationship cites a real artifact. Boundaries with weak evidence are marked low-confidence / `Inferred:`; unknowns become `> TODO (human input needed)` placeholders, never invented.

You coordinate; the per-context `bc-context-analyzer` subagents do the analysis in their own context windows. Read the `ddd-bounded-contexts` skill for the boundary signals, relationship patterns, and the Bounded Context Canvas format/templates, and the `repo-discovery` skill for black-box scanning. Keep your own context lean: pass instructions to subagents and consume only their compact fragments.

**draw.io is the single source of truth; it is the default (only automatic) output.** This tool assembles each context's canvas content from the analyzers purely as scaffolding to fill the **draw.io** artifacts: one editable Bounded Context Canvas `.drawio` per context (`docs/bounded-contexts/<context>.drawio`, the canonical per-context artifact) plus one `.drawio` **context map** of the relationships (`docs/bounded-contexts/context-map.drawio`). The assembled content is held in context and passed inline to the renderer; **no Markdown file is written by default and the content is not persisted anywhere except the draw.io**. After the draw.io artifacts are produced, you offer the other formats - **Markdown** (the per-context canvases and the `docs/bounded-contexts.md` index with the context map + discussion points), **HTML** overviews, and **PNG** snapshots - as optional outputs and produce each only if the user asks. Never create them automatically. Each optional per-context format is a **derived view regenerated from that context's `.drawio`** (Markdown and HTML read the `.drawio`; PNG reads the HTML) by its own dedicated renderer - one renderer per format.

## Optional inputs improve quality

Two artifacts produced by sibling tools, if present, sharpen the analysis far beyond what code structure alone allows:

- `docs/architecture-communication-canvas.md` (from `/build-architecture-communication-canvas`) - product vision, value proposition, core functions, and components.
- `docs/ubiquitous-language.md` (from `/discover-ubiquitous-language`) - the domain language and rough domain classification, the single best seed for context boundaries.

**Detect both before doing anything else.** If at least one exists, use it. If **both are missing**, you must ask the user how to proceed (see step 0) - because without them, bounded contexts can only be derived from existing code, not the product vision or strategy, which materially lowers quality.

## The subagents

- `bc-context-analyzer` - a **readonly** per-context analyzer, spawned once per candidate bounded context (scoped to that context's paths) to produce its filled canvas fragment. Launch them with the Task tool, all in a single message (parallel).
- `bc-canvas-drawio-renderer` - the **default**, source-of-truth per-context renderer, write-capable. Spawned once per context to build that context's canonical draw.io canvas by **copying** the `ddd-bounded-contexts` skill's `assets/canvas-template.drawio` and filling its cells from the assembled content (passed inline). Launch one per context, in parallel.
- `bc-canvas-markdown-renderer` - an **optional**, derived per-context renderer, write-capable. Spawned once per context only when the user requests Markdown, to recover that context's content from its `.drawio` (per `ddd-bounded-contexts` "Reading the draw.io source of truth") and fill `assets/canvas-template.md`. Launch one per context, in parallel.
- `bc-canvas-html-renderer` - an **optional**, derived per-context renderer, write-capable. Spawned once per context only when the user requests the HTML (or PNG) output, to recover that context's content from its `.drawio` and fill the HTML template. Launch one per context, in parallel.

## Workflow

Copy this checklist and track progress:

```
- [ ] Step 0: detect optional inputs; if both missing, ask the user (run-first vs proceed code-only)
- [ ] Step 0b: detect existing bounded-context outputs -> initial run vs update run
- [ ] Discover candidate bounded contexts (repo-discovery + available inputs)
- [ ] Analyze each context: one bc-context-analyzer per candidate (parallel), each returning a filled canvas
- [ ] Merge contexts; classify relationships into a context map
- [ ] Assemble each context's canvas content in context (merge if updating) - scaffolding only; do NOT persist it except in the draw.io
- [ ] Render one draw.io canvas per context to docs/bounded-contexts/<context>.drawio via the bc-canvas-drawio-renderer subagent (DEFAULT, the source of truth) - pass the assembled content inline, in parallel
- [ ] Render the context map to docs/bounded-contexts/context-map.drawio (DEFAULT) - native nodes/edges built from the relationships
- [ ] Summarize context count, relationships, and discussion points / TODOs (and what changed, if updating)
- [ ] Offer the optional derived outputs (Markdown, HTML, PNG) and produce only the ones the user asks for, each regenerated from the .drawio:
  - [ ] (optional) Render docs/bounded-contexts/<context>.md per context from its .drawio via the bc-canvas-markdown-renderer subagent + assemble the index docs/bounded-contexts.md
  - [ ] (optional) Render docs/bounded-contexts/<context>.html per context from its .drawio via the bc-canvas-html-renderer subagent
  - [ ] (optional) Render docs/bounded-contexts/<context>.png per context from the HTML via the acc-canvas-png skill (needs HTML; skip if Chrome unavailable)
```

### Step 0 - Detect optional inputs and decide

1. Check whether `docs/architecture-communication-canvas.md` and `docs/ubiquitous-language.md` exist.
2. If at least one exists, note which, and continue to step 1 (use whatever is available).
3. If **both are missing**, ask the user with the AskQuestion tool, offering these choices:
   - **Run the other tools first** - run `/build-architecture-communication-canvas` and/or `/discover-ubiquitous-language` now, then continue with their outputs. (Recommended - highest quality.)
   - **Proceed code-only** - derive bounded contexts from existing code structure alone. Make clear this has a **negative impact on quality**: contexts come from code, not the product vision or strategy.
   Honor the choice. If the user picks run-first, follow those skills' workflows (or wait for the user to run the commands) before continuing. If the user proceeds code-only, record this so the output document carries an explicit "derived from code only" note.

### Step 0b - Detect existing outputs (initial vs update run)

This tool is re-runnable. Check whether any bounded-context outputs already exist under `docs/bounded-contexts/` - the default `<context>.drawio` canvases and `context-map.drawio`, or `<context>.md`/`<context>.html` and the `docs/bounded-contexts.md` index from a prior run.

- **None exist** - this is an **initial run**. Proceed normally.
- **Some exist** - this is an **update run**. Read the existing canvases first (prefer any Markdown if present, else extract the content from the `.drawio` canvases) and treat them as the base to refine, not replace:
  - Carry forward human-authored content: answered `TODO (human input needed)` items, hand-written notes, manually corrected boundaries/relationships, and edited prose.
  - When discovering candidates (step 1), reuse the existing context names/slugs so refreshed canvases land on the same files; only add, split, merge, or retire contexts where the current evidence warrants it (and note why).
  - When analyzing (step 2), pass each `bc-context-analyzer` the matching existing canvas so it refreshes rather than regenerates blind.
  - **The current skill is authoritative, including its structure.** The existing outputs may have been generated by an older version of this skill / the `bc-context-analyzer` / the templates (e.g. different canvas fields, single-file vs per-context-file layout, a Markdown-first default vs the current draw.io-default, different index/context-map format, more prose vs more diagrams, different evidence/TODO conventions). Do not preserve the old shape: conform the outputs to the **current** `ddd-bounded-contexts` templates (the default `assets/canvas-template.drawio` per context and the `context-map.drawio`; `assets/canvas-template.md` and `assets/template.md` only for the optional Markdown) and conventions, and migrate the preserved human content into the new structure - including consolidating an old single-file output into per-context files (or vice-versa) if the current layout differs. Mention in your summary any human content that no longer has a home.

### 1 - Discover candidate bounded contexts

1. Use `repo-discovery` to scan the repo black-box: list the tree, read root docs, enumerate top-level modules/packages/services, data stores, and deployment units.
2. Seed candidates from available inputs: the ubiquitous-language **domain classification** (each area is a candidate context), and the ACC **Components / Modules** section.
3. Derive a list of candidate contexts as `{context name, paths}` using the boundary signals in `ddd-bounded-contexts`. A small or flat repo may collapse to a single context covering the whole repo.

### 2 - Analyze each context (parallel)

1. Launch one `bc-context-analyzer` subagent per candidate in a single parallel message. In each prompt include: the context name, that context's paths, the repository root path, and any relevant excerpts from the ACC / ubiquitous-language docs (inline them; subagents start with clean context).
2. Instruct each to return only the per-context **canvas fragment** defined in `ddd-bounded-contexts` (the full Bounded Context Canvas - purpose, strategic classification, domain roles, inbound/outbound communication, ubiquitous language, business decisions, assumptions, verification metrics, open questions, owned data - plus the trailing relationships and discussion-points blocks). Every code-derived claim carries an evidence tag; fields not determinable from code become `> TODO (human input needed)`.

### 3 - Merge and build the context map

1. Collect the fragments. Reconcile overlapping or duplicated contexts; merge or split where the evidence warrants and note why.
2. From each context's integration points, classify the relationships between contexts using the patterns in `ddd-bounded-contexts` (Partnership, Shared Kernel, Customer/Supplier, Conformist, Anti-Corruption Layer, Open Host Service, Published Language, Separate Ways). Mark direction (upstream/downstream) where evident.
3. Compile **discussion points**: ambiguous boundaries, contexts that may need splitting or merging, the same term spanning contexts, and undetermined relationships.

### Assemble the canvas content (in context - scaffolding for the draw.io)

1. For **each context**, assemble its canvas content from that context's analyzer fragment following the `assets/canvas-template.md` shape (purpose, strategic classification, domain roles, inbound/outbound communication, ubiquitous language, business decisions, assumptions, verification metrics, open questions, owned data). Hold it **in context** only as scaffolding to fill that context's draw.io. Preserve every evidence tag and TODO placeholder. Slug each context name (lowercase, hyphenated) for its filenames. **Do not persist the content as a Markdown file** - each `<context>.drawio` is the source of truth; Markdown is an optional derived output (see "Report and offer optional outputs").
2. Keep the context map and discussion points in context too (built in step 3): the relationships between contexts (with patterns and direction) and the discussion points / possible gaps.

### Render the draw.io canvases and context map (default, only automatic outputs)

After the content is assembled, produce the default draw.io artifacts. Create `docs/bounded-contexts/` if needed.

1. **One canvas per context (parallel).** For each context, launch a `bc-canvas-drawio-renderer` subagent and pass it: the assembled canvas content for that context **inline** (so no Markdown file is needed), the template path (`ddd-bounded-contexts` skill `assets/canvas-template.drawio`), and the output path `docs/bounded-contexts/<context-slug>.drawio`. It copies the template and fills its cells faithfully (no new facts). Launch all contexts in a single parallel message. (`bc-canvas-drawio-renderer` is write-capable; do not use the readonly `bc-context-analyzer` for this.)
2. **The context map (one file).** Render the relationships as an editable draw.io diagram at `docs/bounded-contexts/context-map.drawio`: one rounded node per context and one edge per relationship, the pattern as the edge label, the arrow pointing upstream -> downstream. Build it as native draw.io shapes/edges (this small diagram has no fixed template, so generate it directly as valid `<mxfile>` XML). Add a short title and a one-line legend expanding any pattern abbreviation used as an edge label (e.g. `OHS = Open Host Service`, `ACL = Anti-Corruption Layer`) and the direction convention. Use the canvas palette (node `style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1C1C1C;fontColor=#1C1C1C;"`, edge `style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;strokeColor=#1C1C1C;endArrow=block;"`). A flat/tiny repo with a single context still gets a one-node map.
3. On an update run both re-render from the refreshed content, overwriting the previous `.drawio` artifacts.
4. Mention the generated `docs/bounded-contexts/<context>.drawio` files and `docs/bounded-contexts/context-map.drawio` in your summary so the user can open them (in draw.io or the VSCode Draw.io Integration extension).

### Report and offer optional outputs

1. Report a short summary: number of contexts (and their `.drawio` canvas files), the relationships in the context map, and the discussion points / unresolved TODOs to take to the team. On an update run, also summarize what changed (contexts added/split/merged/retired, relationships changed, items added or marked stale).
2. **Optional outputs (Markdown, HTML, PNG) - derived from the draw.io, on request only.** Offer the other formats and produce **only** the ones the user explicitly asks for. Never create them automatically. Each per-context format is regenerated **from that context's `.drawio` source of truth** by its own renderer (so they always match the canonical canvas, even after hand-edits). Use the AskQuestion tool (or a short prompt) to offer: Markdown, HTML overviews, PNG snapshots, or none.
   - **Markdown** (`docs/bounded-contexts/<context>.md` + index `docs/bounded-contexts.md`): for each context, launch a `bc-canvas-markdown-renderer` subagent (one per context, in parallel) and pass it the source-of-truth path `docs/bounded-contexts/<context>.drawio`, the template path (`ddd-bounded-contexts` skill `assets/canvas-template.md`), and the output path; it recovers the content from the `.drawio` (per "Reading the draw.io source of truth"), copies the template, and fills it in place. Then assemble the index by copying `assets/template.md`: purpose framing line (including the "derived from code only" note if applicable), the contexts table linking to each `bounded-contexts/<context-slug>.md`, the relationships / context-map section with its **required** mermaid diagram (follow the mermaid guardrail in `ddd-bounded-contexts`; you can reuse the relationships you built for `context-map.drawio`), and Discussion points / possible gaps. On an update run, reconcile with the existing Markdown per the merge rules rather than overwriting blindly.
   - **HTML overviews** (`docs/bounded-contexts/<context>.html` per context): for each context, launch a `bc-canvas-html-renderer` subagent (one per context, in parallel) and pass it the source-of-truth path `docs/bounded-contexts/<context>.drawio`, the template path (`ddd-bounded-contexts` skill `assets/canvas-template.html`), and the output path. It recovers the content from the `.drawio`, copies the template, and fills its cells faithfully.
   - **PNG snapshots** (`docs/bounded-contexts/<context>.png` per context): require the HTML, so produce the HTML first. Then for each context follow the `acc-canvas-png` skill (it is ecosystem-agnostic and renders any self-contained HTML): run its `assets/html-to-png.py` with `--html docs/bounded-contexts/<context>.html --out docs/bounded-contexts/<context>.png`. If Chrome/Chromium is unavailable the script exits with code 2 - note that the PNG was skipped and continue.
   Mention any optional artifacts you produced in your summary so the user can open them.

## Rules

- Black-box: never assume language, framework, or layout (see `repo-discovery`).
- Boundaries follow the model and the language, not folder names alone.
- Pitch it for an architect bridging business and development - not too technical, not too abstract. Concrete enough that developers recognize the system (key aggregate, defining event, owned data store, real integration seam - verbatim), but framed in business language a stakeholder can follow. Don't drift to a code inventory (never enumerate individual functions, methods, files, endpoints, or columns - capture only the few that characterize each context and summarize the rest), nor to vague abstractions the team can't act on. Keep Purpose and rationale to 1-2 short sentences; the evidence tag is a provenance pointer only. When in doubt, summarize and omit rather than list.
- Always produce a context map, not just a list of contexts.
- Evidence-or-gap: every context and relationship cites a real artifact; unknowns become `> TODO (human input needed)` placeholders, never guessed.
- If both optional inputs are missing, never silently skip - ask, and record the user's choice in the output.
