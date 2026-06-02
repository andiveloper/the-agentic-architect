# The Agentic Architect

**The Agentic Architect** equips coding agents with reusable guidance for architectural work - so your agent ([Cursor](https://cursor.com/docs) or [Claude Code](https://code.claude.com/docs)) can genuinely assist software and solution architects and development teams, not just write code. It is a growing toolbelt of skills and subagents, each focused on one architecture task, each installable on its own, and each invoked as a single slash command.

Every tool analyzes your repository as a **black box** - no assumptions about language, framework, or layout - and follows an evidence-or-gap rule: every statement cites a real artifact, and anything that can't be derived from the repo is marked as a gap rather than invented.

## The problem it solves

Architecture documentation has two chronic failure modes:

- **It's never current.** Docs are written once, then drift away from the code as the system evolves. Within months the diagrams and decisions describe a system that no longer exists.
- **It's cumbersome to create for an existing codebase.** Reverse-engineering the architecture, domain language, and boundaries of a large or unfamiliar repo by hand is slow, tedious, and easy to get wrong.

The Agentic Architect attacks both: because the documentation is **generated from the code itself** by your coding agent, it's cheap to (re)create on demand - re-run a tool whenever the code changes and the artifact catches up. And because every statement is backed by evidence from the repo, you get an accurate starting point for a brand-new or inherited codebase in minutes instead of weeks.

## Tools on the belt

### 1. `/build-architecture-communication-canvas`

**Goal:** capture "the shortest possible description of your architecture" by filling out the [arc42 Architecture Communication Canvas (ACC)](https://canvas.arc42.org/architecture-communication-canvas) for any repository.

Nine category subagents scan the codebase, report what's derivable versus missing, let you fill the gaps, then assemble a single evidence-backed canvas with all nine ACC sections. The result lands in `docs/architecture-communication-canvas.md`.

Sample output: [Markdown](build-architecture-communication-canvas/example-architecture-communication-canvas.md) · [HTML](build-architecture-communication-canvas/example-architecture-communication-canvas.html)

[![Architecture Communication Canvas - HTML overview for the sample Taskflow API](build-architecture-communication-canvas/example-architecture-communication-canvas.png)](build-architecture-communication-canvas/example-architecture-communication-canvas.html)

### 2. `/discover-ubiquitous-language`

**Goal:** surface the [Domain-Driven Design ubiquitous language](https://martinfowler.com/bliki/UbiquitousLanguage.html) **as it actually appears in the code** - the real domain nouns, verbs, statuses, and events.

It produces a domain-expert review artifact (a rough domain classification, a plain-language keyword/definition glossary, and explicit discussion points) so you can sit down with non-technical domain experts and find gaps and misunderstandings between code and domain. The result lands in `docs/ubiquitous-language.md`.

Sample output: [Markdown](discover-ubiquitous-language/example-ubiquitous-language.md)

### 3. `/define-bounded-contexts`

**Goal:** identify the [Domain-Driven Design bounded contexts](https://martinfowler.com/bliki/BoundedContext.html) and the **context map** (how those contexts relate), and fill out a [Bounded Context Canvas](https://github.com/ddd-crew/bounded-context-canvas) for each one.

It scans the code black-box and, where available, folds in the outputs of the two tools above to draw boundaries from product vision and domain language, not just folder structure. When neither input exists it asks whether to run those tools first or proceed code-only (lower quality). The result is one canvas per context under `docs/bounded-contexts/` plus an index `docs/bounded-contexts.md` with the context map and its classic relationship patterns (Customer/Supplier, ACL, Open Host Service, ...).

Sample output: index [Markdown](define-bounded-contexts/example-bounded-contexts.md) · per-context canvas [Markdown](define-bounded-contexts/example-bounded-contexts/sales.md) · [HTML](define-bounded-contexts/example-bounded-contexts/sales.html) (also [billing](define-bounded-contexts/example-bounded-contexts/billing.html), [delivery](define-bounded-contexts/example-bounded-contexts/delivery.html), [identity](define-bounded-contexts/example-bounded-contexts/identity.html))

[![Bounded Context Canvas - Sales (sample HTML overview)](define-bounded-contexts/example-bounded-contexts/sales.png)](define-bounded-contexts/example-bounded-contexts/sales.html)

More tools (e.g. architecture review) will follow as additional top-level folders.

### Recommended order

The tools stand alone, but they compose - later tools get richer when earlier outputs exist. For a fresh repo, run them in this order:

1. **`/build-architecture-communication-canvas`** - establish the big picture: value proposition, stakeholders, components, decisions, and quality goals.
2. **`/discover-ubiquitous-language`** - extract the real domain vocabulary from the code, then validate it with domain experts.
3. **`/define-bounded-contexts`** - draw the bounded contexts and context map, informed by the product vision (from step 1) and the domain language (from step 2).

`/define-bounded-contexts` will detect and fold in the outputs of steps 1-2 automatically; if they're missing it offers to run them first or proceed code-only (lower quality).

## How a tool runs

Each tool is built the same way: an orchestrator skill invoked by its slash command, plus a set of readonly subagents that scan the repo in parallel. A typical run does a gap analysis (what's derivable from the code versus what's missing), pauses for you to add any missing docs or answer questions, then autonomously assembles the output - marking anything still unknown as a clearly-labelled `> TODO (human input needed)` placeholder rather than inventing it.

```mermaid
flowchart LR
    cmd["/slash-command"] --> p1["Phase 1: Gap analysis (readonly subagents)"]
    p1 --> p2["Phase 2: You add docs / answer questions"]
    p2 --> p3["Phase 3: Autonomous fill"]
    p3 --> out["docs/<output>.md"]
```

### Why subagents + skills?

- **Subagents** (Cursor [docs](https://cursor.com/docs/subagents) / Claude Code [docs](https://code.claude.com/docs/en/sub-agents)) give each category its own context window, so the noisy repo scanning never bloats the main conversation. One subagent per category keeps the work transparent and independently improvable.
- **Skills** (Cursor [docs](https://cursor.com/docs/skills) / Claude Code [docs](https://code.claude.com/docs/en/skills)) carry the reusable knowledge (templates, discovery heuristics, question banks) and load progressively. Each entrypoint is a skill with `disable-model-invocation: true`, so it installs via the skills standard but is still invoked as a slash command.

## Install

The `install.sh` script copies the toolkit's skills and subagents into the right place for your coding agent. Pick one or more agents (`--cursor`, `--claude`) and exactly one scope (`--user` for all your projects, `--target <dir>` for a single project).

### Option A - run directly from GitHub (no checkout needed)

```bash
# Cursor, user-scoped (all your projects):
curl -fsSL https://raw.githubusercontent.com/andiveloper/the-agentic-architect/main/install.sh | bash -s -- --cursor --user

# Claude Code, into a specific project:
curl -fsSL https://raw.githubusercontent.com/andiveloper/the-agentic-architect/main/install.sh | bash -s -- --claude --target /path/to/your/project
```

### Option B - from a local checkout

```bash
git clone https://github.com/andiveloper/the-agentic-architect.git
cd the-agentic-architect

# Cursor + Claude Code into another project (project-scoped):
./install.sh --cursor --claude --target /path/to/your/project

# Or user-scoped (all your projects):
./install.sh --cursor --user
```

Per agent, the script installs into:

| Agent | Flag | Skills | Subagents |
| --- | --- | --- | --- |
| Cursor | `--cursor` | `<base>/.cursor/skills/` | `<base>/.cursor/agents/` |
| Claude Code | `--claude` | `<base>/.claude/skills/` | `<base>/.claude/agents/` |

where `<base>` is `$HOME` (`--user`) or your `--target` directory. Run `./install.sh --help` for all options.

## Usage

1. Open the repository you want to document in your coding agent (Cursor or Claude Code).
2. Run the slash command for the tool you want:
   - `/build-architecture-communication-canvas` → `docs/architecture-communication-canvas.md`
   - `/discover-ubiquitous-language` → `docs/ubiquitous-language.md`
   - `/define-bounded-contexts` → `docs/bounded-contexts.md` + one canvas per context under `docs/bounded-contexts/`
3. Answer the gap report inline (add docs or answer questions, or skip).
4. Review the generated file(s) and resolve any `TODO (human input needed)` placeholders.

The tools compose: `/define-bounded-contexts` optionally consumes the outputs of the other two, so running all three in the [recommended order](#recommended-order) yields the richest result.

## What's in this repo

The toolkit is agent-neutral: each tool lives in a single top-level folder, and `install.sh` maps the source files into each coding agent's directories. Future toolkits (e.g. `architecture-review/`) will be added as sibling top-level folders.

```
build-architecture-communication-canvas/         # the ACC tool
  skills/
    build-architecture-communication-canvas/      # orchestrator entrypoint
    arc42-acc-canvas/                              # canvas template (md + html) + conventions
    repo-discovery/                                # black-box discovery heuristics
    acc-gap-analysis/                              # inputs catalog + question bank
  agents/
    acc-value-proposition.md ... acc-risks-missing-info.md   # 9 category subagents
    acc-canvas-html.md                             # renders the HTML overview from the Markdown
  example-architecture-communication-canvas.md    # sample output (Markdown)
  example-architecture-communication-canvas.html  # sample output (HTML)
  example-architecture-communication-canvas.png   # sample output (HTML rendered to PNG)
discover-ubiquitous-language/                     # the DDD ubiquitous-language tool
  skills/
    discover-ubiquitous-language/                  # orchestrator entrypoint
    ddd-ubiquitous-language/                       # DDD term heuristics + output template
  agents/
    ul-domain-extractor.md                         # per-area term-extraction subagent
  example-ubiquitous-language.md                   # sample output (Markdown)
define-bounded-contexts/                          # the DDD bounded-context + context-map tool
  skills/
    define-bounded-contexts/                       # orchestrator entrypoint
    ddd-bounded-contexts/                          # boundary signals + relationship patterns + canvas + index templates
  agents/
    bc-context-analyzer.md                         # per-context canvas subagent
  example-bounded-contexts.md                      # sample index output (Markdown)
  example-bounded-contexts/                        # sample per-context canvases (Markdown + HTML + PNG preview)
install.sh
```

## License

[MIT](LICENSE)

## Credits

The Architecture Communication Canvas is by Gernot Starke, Patrick Roos and arc42 contributors - <https://canvas.arc42.org/architecture-communication-canvas>.

The Bounded Context Canvas is by the DDD Crew and contributors (CC BY 4.0) - <https://github.com/ddd-crew/bounded-context-canvas>.
