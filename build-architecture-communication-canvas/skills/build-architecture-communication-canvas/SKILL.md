---
name: build-architecture-communication-canvas
description: Orchestrates generation of an arc42 Architecture Communication Canvas for the current repository. Runs gap analysis, collects missing inputs, then fills all nine categories autonomously via per-category subagents and writes a single Markdown file. Invoke explicitly as /build-architecture-communication-canvas.
disable-model-invocation: true
---

# Build Architecture Communication Canvas

Orchestrates the three-phase generation of an [arc42 Architecture Communication Canvas](https://canvas.arc42.org/architecture-communication-canvas) for the repository currently open in the workspace.

You coordinate; the nine category subagents do the analysis in their own context windows. Read the `arc42-acc-canvas` skill for the template, conventions, and assembly rules, and the `acc-gap-analysis` skill for the report/question formats. Keep your own context lean: pass instructions to subagents and consume only their compact fragments.

## The nine category subagents

`acc-value-proposition`, `acc-key-stakeholder`, `acc-core-functions`, `acc-quality-requirements`, `acc-business-context`, `acc-components-modules`, `acc-core-decisions`, `acc-technologies`, `acc-risks-missing-info`.

Each accepts a `mode` (`gap-scan` or `fill`) in its prompt. Launch them with the Task tool. Launch all nine in a single message (parallel) each phase.

## Workflow

Copy this checklist and track progress:

```
- [ ] Phase 1: gap-scan all 9 categories (parallel) and merge into Missing Inputs Report
- [ ] Present report to the user
- [ ] Phase 2: collect documents and/or inline answers (or accept skip)
- [ ] Phase 3: fill all 9 categories (parallel) with collected inputs
- [ ] Assemble and write docs/architecture-communication-canvas.md
- [ ] Summarize unresolved TODOs to the user
```

### Phase 1 - Gap analysis

1. Launch all nine subagents in parallel with `mode: gap-scan`. In each prompt include: the mode, the repository root path, and the instruction to return only the gap-scan fragment defined in `acc-gap-analysis`.
2. Collect the nine fragments and merge them into one **Missing Inputs Report** using the format in `acc-gap-analysis` (per category: confidence without input, derivable now, missing, resolve-by document/question).
3. Present the report to the user, ending with the call to action: reply with documents/paths and/or answers, or say `skip`.

### Phase 2 - Input collection

1. If the user provides document paths or pasted text, note each as a source for the relevant category.
2. For categories still missing, you may ask the inline questions from `acc-gap-analysis` via the AskQuestion tool. Asking is optional and every question is skippable.
3. Record, per category, the collected inputs (document paths, pasted text, or direct answers) and their provenance. Anything left unresolved stays a gap - do not block.

### Phase 3 - Autonomous fill (no human intervention)

1. Launch all nine subagents in parallel with `mode: fill`. In each prompt include: the mode, the repository root path, and that category's collected inputs/answers verbatim (subagents start with clean context, so inline everything they need). Tell each to return only its section body following `arc42-acc-canvas` conventions.
2. For `acc-risks-missing-info`, also pass the de-duplicated list of unresolved `TODO`/gap items surfaced by the other eight subagents so it can populate "Missing information".
3. Do not prompt the user during this phase.

### Assemble and write

1. Load the template from the `arc42-acc-canvas` skill (`assets/template.md`).
2. Insert each subagent's fragment under its matching heading, applying the assembly rules from `arc42-acc-canvas` (preserve evidence tags and TODO placeholders; build the Risks "Missing information" union; fill header fields from evidence or mark TODO).
3. Write the result to `docs/architecture-communication-canvas.md` (create the `docs/` directory if needed). If the file exists, confirm overwrite with the user.
4. Report a short summary: confidence per area and the list of unresolved `TODO (human input needed)` items for the user to complete.

## Rules

- The analysis is black-box: never assume language, framework, or layout (see `repo-discovery`).
- Never invent facts; unknowns become `> TODO (human input needed)` placeholders.
- Keep the final document concise - the ACC is meant to be the shortest useful description.
