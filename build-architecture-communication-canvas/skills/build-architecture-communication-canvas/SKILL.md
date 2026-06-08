---
name: build-architecture-communication-canvas
description: Orchestrates generation of an arc42 Architecture Communication Canvas for the current repository. Runs gap analysis, collects missing inputs, then fills all nine categories autonomously via per-category subagents and renders an editable draw.io canvas as the default (and only automatic) output. Markdown, HTML, and PNG are offered as optional outputs at the end and produced only on request. Invoke explicitly as /build-architecture-communication-canvas.
disable-model-invocation: true
---

# Build Architecture Communication Canvas

Orchestrates the three-phase generation of an [arc42 Architecture Communication Canvas](https://canvas.arc42.org/architecture-communication-canvas) for the repository currently open in the workspace.

You coordinate; the nine category subagents do the analysis in their own context windows. Read the `arc42-acc-canvas` skill for the template, conventions, and assembly rules, and the `acc-gap-analysis` skill for the report/question formats. Keep your own context lean: pass instructions to subagents and consume only their compact fragments.

**draw.io is the single source of truth; it is the default (only automatic) output.** This tool assembles the canvas content from the nine subagents purely as scaffolding to fill the **draw.io canvas** (`docs/architecture-communication-canvas.drawio`) - the canonical, human-editable artifact. The assembled content is held in context and passed inline to the draw.io renderer; **no Markdown file is written by default and the content is not persisted anywhere except the draw.io**. After the draw.io is produced, you offer the three other formats - **Markdown**, **HTML overview**, and **PNG** - as optional outputs and produce each one only if the user asks. Never create them automatically. Each optional format is a **derived view regenerated from the draw.io** (Markdown and HTML read the `.drawio`; PNG reads the HTML) by its own dedicated renderer - one renderer per format.

## The nine category subagents

`acc-value-proposition`, `acc-key-stakeholder`, `acc-core-functions`, `acc-quality-requirements`, `acc-business-context`, `acc-components-modules`, `acc-core-decisions`, `acc-technologies`, `acc-risks-missing-info`.

Each accepts a `mode` (`gap-scan` or `fill`) in its prompt. Launch them with the Task tool. Launch all nine in a single message (parallel) each phase.

## The renderer subagents (one per output format)

Faithful renderers (not analysts) - they add no facts. There is one per format, and the draw.io renderer is the source-of-truth producer; the others derive their format from the draw.io:

- `acc-canvas-drawio` - the **default**, source-of-truth renderer. Fills the `arc42-acc-canvas` skill's `assets/canvas-template.drawio` from the assembled content (passed inline) to produce the canonical draw.io canvas (`docs/architecture-communication-canvas.drawio`).
- `acc-canvas-markdown` - **optional**, derived. Reads the `.drawio` (per `arc42-acc-canvas` "Reading the draw.io source of truth") and fills `assets/template.md` to produce `docs/architecture-communication-canvas.md`. Run only when the user requests Markdown.
- `acc-canvas-html` - **optional**, derived. Reads the `.drawio` and fills `assets/canvas-template.html` to produce `docs/architecture-communication-canvas.html`. Run only when the user requests the HTML (or PNG) output.

The PNG is produced by the `acc-canvas-png` skill from the HTML (see "Optional outputs").

## Workflow

Copy this checklist and track progress:

```
- [ ] Step 0: detect existing canvas -> initial run vs update run
- [ ] Phase 1: gap-scan all 9 categories (parallel) and merge into Missing Inputs Report; detect docs/commit-analysis.md
- [ ] Present report to the user; if commit-analysis is missing, ask upfront whether to run /analyze-commits
- [ ] Phase 2: collect documents and/or inline answers (or accept skip); run /analyze-commits if the user agreed
- [ ] Phase 3: fill all 9 categories (parallel) with collected inputs (pass commit-analysis to the Risks subagent)
- [ ] Assemble the canvas content in context (merge if updating) - scaffolding only; do NOT persist it anywhere except the draw.io
- [ ] Render docs/architecture-communication-canvas.drawio via the acc-canvas-drawio subagent (DEFAULT, the source of truth) - pass the assembled content inline
- [ ] Summarize unresolved TODOs (and what changed, if updating) to the user
- [ ] Offer the optional derived outputs (Markdown, HTML, PNG) and produce only the ones the user asks for, each regenerated from the draw.io:
  - [ ] (optional) Render docs/architecture-communication-canvas.md from the .drawio via the acc-canvas-markdown subagent
  - [ ] (optional) Render docs/architecture-communication-canvas.html from the .drawio via the acc-canvas-html subagent
  - [ ] (optional) Render docs/architecture-communication-canvas.png from the HTML via the acc-canvas-png skill (needs HTML; skip if Chrome unavailable)
```

### Step 0 - Detect existing canvas (initial vs update run)

This tool is re-runnable. Before anything else, check whether a canvas already exists under `docs/` - look for any of `docs/architecture-communication-canvas.drawio` (the default output), `docs/architecture-communication-canvas.md`, or `docs/architecture-communication-canvas.html`.

- **None exists** - this is an **initial run**. Proceed normally.
- **One or more exist** - this is an **update run**. Read the existing canvas artifact(s) first (prefer the Markdown if present, else extract the content from the `.drawio`) and treat it as the base to refine, not replace:
  - Carry its human-authored content forward: any `TODO (human input needed)` a human has since answered, hand-written notes, `(source: user input)` lines, and otherwise resolved gaps. These must survive the re-run.
  - In Phase 1, you may skip re-asking for inputs already captured in the existing canvas; only the still-open gaps need fresh attention.
  - In Phase 3, pass each subagent the matching existing section so it **refreshes** that section (correct/extend against current code) rather than regenerating blind.
  - Note the existing generation date so you can report what changed.
  - **The current skill is authoritative, including its structure.** The existing canvas may have been generated by an older version of this skill / the subagents / the template (e.g. different section set, single-file vs multi-file layout, more prose vs more diagrams, different evidence/TODO conventions). Do not preserve the old shape: conform the output to the **current** `arc42-acc-canvas` template and conventions, and migrate the preserved human content into the new structure. If a section was renamed/removed/added, move human content to its best new home (and mention any human content that no longer has a home in your summary).

### Phase 1 - Gap analysis

1. Launch all nine subagents in parallel with `mode: gap-scan`. In each prompt include: the mode, the repository root path, and the instruction to return only the gap-scan fragment defined in `acc-gap-analysis`.
2. Collect the nine fragments and merge them into one **Missing Inputs Report** using the format in `acc-gap-analysis` (per category: confidence without input, derivable now, missing, resolve-by document/question).
3. Check whether `docs/commit-analysis.md` exists. If it is **absent**, include in the report's call to action an upfront offer to run `/analyze-commits` first (per `acc-gap-analysis` "Offering to run /analyze-commits") - it strengthens the Risks section. If it is present, note it as a source for Risks.
4. Present the report to the user, ending with the call to action: reply with documents/paths and/or answers, run `/analyze-commits` (if offered), or say `skip`.

### Phase 2 - Input collection

1. If the user provides document paths or pasted text, note each as a source for the relevant category.
2. For categories still missing, you may ask the inline questions from `acc-gap-analysis` via the AskQuestion tool. Asking is optional and every question is skippable.
3. If the user agreed to run `/analyze-commits`, run that tool's flow now (per the `analyze-commits` skill) so `docs/commit-analysis.md` exists before Phase 3; note it as a source for the Risks category.
4. Record, per category, the collected inputs (document paths, pasted text, or direct answers) and their provenance. Anything left unresolved stays a gap - do not block.

### Phase 3 - Autonomous fill (no human intervention)

1. Launch all nine subagents in parallel with `mode: fill`. In each prompt include: the mode, the repository root path, and that category's collected inputs/answers verbatim (subagents start with clean context, so inline everything they need). Tell each to return only its section body following `arc42-acc-canvas` conventions.
2. For `acc-risks-missing-info`, also pass the de-duplicated list of unresolved `TODO`/gap items surfaced by the other eight subagents so it can populate "Missing information", and - if `docs/commit-analysis.md` exists - pass its path/contents so it can fold the commit-history risks (churn/bug hotspots, bus factor, firefighting, velocity) into the Risks list cited `(source: docs/commit-analysis.md)`.
3. Do not prompt the user during this phase.

### Assemble the canvas content (in context - scaffolding for the draw.io)

1. Insert each subagent's fragment under its matching heading, applying the assembly rules from `arc42-acc-canvas` (preserve evidence tags and TODO placeholders; build the Risks "Missing information" union; fill header fields from evidence or mark TODO). Use the `assets/template.md` shape as the mental model for the content.
2. Hold the assembled content **in context** only as scaffolding to fill the draw.io. **Do not persist it as a file** - the draw.io is the source of truth; the Markdown file is an optional derived output (see "Optional outputs").
   - **Initial run:** assemble from scratch.
   - **Update run:** the existing source of truth is the `docs/architecture-communication-canvas.drawio` (recover its content per `arc42-acc-canvas` "Reading the draw.io source of truth"; if only an older `.md`/`.html` exists, read that). Reconcile the assembled content with it instead of regenerating blind. Preserve human-authored content and answered TODOs; update sections whose evidence changed; add newly discovered items; and where a previous finding no longer has supporting evidence, mark it stale/removed rather than silently deleting it. Refresh the generation date and keep the content concise.
3. Report a short summary: confidence per area and the list of unresolved `TODO (human input needed)` items for the user to complete. On an update run, also summarize what changed since the previous version (sections updated, items added, items marked stale).

### Render the draw.io canvas (default; the source of truth)

After the canvas content is assembled, launch the `acc-canvas-drawio` subagent (Task tool) to produce the canonical artifact:

1. `acc-canvas-drawio`: pass the assembled canvas content **inline** in the prompt, the template path (`arc42-acc-canvas` skill `assets/canvas-template.drawio`), and the output path `docs/architecture-communication-canvas.drawio`. It copies the template and fills each category box and the header fields faithfully from the content (no new facts). Create the `docs/` directory if needed. The `.drawio` must carry the complete content so the other formats can be regenerated from it losslessly.
2. On an update run it re-renders from the refreshed content, overwriting the previous `.drawio`.
3. Mention the generated `docs/architecture-communication-canvas.drawio` in your summary so the user can open it (in draw.io or the VSCode Draw.io Integration extension).

### Optional outputs (Markdown, HTML, PNG) - derived from the draw.io, on request only

After reporting the draw.io result, offer the three other formats and produce **only** the ones the user explicitly asks for. Never create them automatically. Each is regenerated **from the `.drawio` source of truth** by its own renderer (so they always match the canonical canvas, even after hand-edits to the `.drawio`). Use the AskQuestion tool (or a short prompt) to offer: Markdown, HTML overview, PNG snapshot, or none.

- **Markdown** (`docs/architecture-communication-canvas.md`): launch `acc-canvas-markdown`, passing the source-of-truth path `docs/architecture-communication-canvas.drawio`, the template path (`arc42-acc-canvas` skill `assets/template.md`), and the output path. It recovers the content from the `.drawio` (per "Reading the draw.io source of truth"), copies the template, and fills it in place.
- **HTML overview** (`docs/architecture-communication-canvas.html`): launch `acc-canvas-html`, passing the same `.drawio` path, the template path (`arc42-acc-canvas` skill `assets/canvas-template.html`), and the output path. It recovers the content from the `.drawio`, copies the template, and fills it in place (rendering the mermaid diagrams in-browser).
- **PNG snapshot** (`docs/architecture-communication-canvas.png`): requires the HTML, so produce the HTML first (render it now if the user wants the PNG but not the HTML). Then follow the `acc-canvas-png` skill: run its `assets/html-to-png.py` with `--html docs/architecture-communication-canvas.html --out docs/architecture-communication-canvas.png`. It captures the whole page (no cutoff) via headless Chrome. If Chrome/Chromium is unavailable the script exits with code 2 - note that the PNG was skipped and continue.

Mention any optional artifacts you produced in your summary so the user can open them.

## Rules

- The analysis is black-box: never assume language, framework, or layout (see `repo-discovery`).
- Never invent facts; unknowns become `> TODO (human input needed)` placeholders.
- Keep the final document concise - the ACC is meant to be the shortest useful description.
