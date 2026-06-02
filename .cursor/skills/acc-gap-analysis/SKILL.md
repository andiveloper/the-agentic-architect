---
name: acc-gap-analysis
description: Catalog of which inputs each ACC category needs, how to detect existing strategy/Business Model Canvas docs and ADRs, the standard Missing Inputs Report format, and an inline question bank for gaps. Use during ACC gap analysis (phase 1) and input collection (phase 2), or when a category subagent decides what is missing.
disable-model-invocation: true
---

# ACC gap analysis

Knowledge for the gap-analysis and input-collection phases: what each category needs, how to find inputs already in the repo, how to format the Missing Inputs Report, and what to ask the user.

## Per-category input catalog

For each category: what is usually derivable from the repo vs. what requires human/document input.

| Category | Derivable from repo | Needs human / document input |
| --- | --- | --- |
| Value Proposition | README intro, product/marketing docs | Business goals, economic driver, target value - strategy doc / Business Model Canvas |
| Key Stakeholder | CODEOWNERS, AUTHORS, contributors, git authors | Paying customers, sponsors, business stakeholders |
| Core Functions | Entrypoints, public API, routes, CLI, README features | Which functions matter most / are highest value |
| Quality Requirements | Perf tests, caching, security middleware, SLO/SLA config | Prioritized quality goals and their targets |
| Business Context | External clients, APIs, env hosts, IaC managed services | Business meaning/criticality of each neighbour |
| Components / Modules | Dir structure, workspaces, services, packages | Intended logical architecture if not evidenced |
| Core Decisions | ADRs, design docs, notable git history | The good/bad judgement and rationale behind decisions |
| Technologies | Manifests, lockfiles, Dockerfiles, CI, IaC | Ops/runtime details not in the repo (hosting, datacenter) |
| Risks and Missing Information | TODO/FIXME, deprecated deps, missing tests/CI | Known operational pains, organizational risks |

## Detecting existing input documents

Before asking the user, look for inputs already present:

- **Strategy / Business Model Canvas**: files or headings mentioning "business model", "value proposition", "BMC", "strategy", "OKR", "vision", "product brief", `*.canvas`, `business-model*`, `strategy*`, pitch decks (`*.md`/`*.pdf`) in `docs/`, `business/`, `product/`.
- **ADRs / decisions**: `docs/adr/`, `adr/`, `decisions/`, `*.adr.md`, numbered decision files with Context/Decision/Consequences headings, `ARCHITECTURE.md`, RFC folders.
- **Quality/ops docs**: `SECURITY.md`, SLO/SLA docs, runbooks, on-call docs.
- **Stakeholder hints**: `CODEOWNERS`, `AUTHORS`, `MAINTAINERS*`, `.github/FUNDING.yml`, governance docs.

If a relevant document exists, treat it as a candidate source (cite it with `(source: <path>)`) instead of marking the category missing.

## Missing Inputs Report format

The orchestrator merges all nine gap-scan fragments into one report with this shape:

```markdown
# Missing Inputs Report

For each category: what I can derive from the repo, what is missing, and how to resolve it.

## <Category>
- Confidence without input: <high|medium|low>
- Derivable now: <short summary or "nothing">
- Missing: <what is missing>
- Resolve by: add document(s) [<suggested path/type>] OR answer: "<question>"
```

End the report with a single call to action: "Reply with documents/paths and/or answers, or say 'skip' to fill autonomously and leave TODO placeholders."

## Gap-scan fragment format (returned by each subagent)

Each category subagent in `gap-scan` mode returns only:

```markdown
### <Category>
- Confidence without input: <high|medium|low>
- Derivable now: <one or two lines, with evidence tags>
- Missing: <one or two lines>
- Suggested input: <document type/path> | Question: "<one specific question>"
```

## Inline question bank

One sharp question per category for phase-2 Q&A (ask only for categories still missing after document detection). Keep questions specific and answerable in a sentence.

- Value Proposition: "In one or two sentences, what core value/business goal does this system deliver, and to whom?"
- Key Stakeholder: "Who pays for and who most benefits from this system (customers, sponsors, key teams)?"
- Core Functions: "Which 3-5 functions are the most important or highest-value for users?"
- Quality Requirements: "Which quality attributes matter most (e.g. performance, security, reliability) and any concrete targets?"
- Business Context: "Which external systems are most critical, and which are risky or costly?"
- Components / Modules: "Is there an intended logical architecture beyond the folder structure I can see?"
- Core Decisions: "What are 1-3 architectural decisions you are proud of or regret, and why?"
- Technologies: "Any important runtime/ops technologies not visible in the repo (hosting, datacenter, monitoring)?"
- Risks and Missing Information: "What are the biggest known risks or pain points not obvious from the code?"

## Phase-2 handling rules

- Detect documents first; only ask questions for categories still missing.
- Accept answers as documents (paths/pasted text) and/or direct answers; record provenance for each.
- Anything the user skips or leaves blank stays a gap and becomes a `> TODO (human input needed)` placeholder in the final canvas - phase 3 never blocks on it.
