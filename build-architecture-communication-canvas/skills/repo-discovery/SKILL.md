---
name: repo-discovery
description: Ecosystem-agnostic, black-box heuristics for discovering facts about an unknown repository (technologies, components, external context, functions, quality signals, risk signals) without assuming any language, framework, or layout. Use when a subagent needs to gather evidence from a repo it knows nothing about.
disable-model-invocation: true
---

# Repo discovery (black-box)

Heuristics for analyzing a repository you know **nothing** about. The repo may be any language, any layout, a monorepo, polyglot, docs-only, infra-only, or nearly empty. Treat every concrete file as evidence; treat every named example below as illustrative, never required.

## Hard rules

1. **No assumptions.** Never assume a language, framework, build tool, package manager, runtime, directory convention (`src/`, `app/`...), or VCS host. Detect from what exists.
2. **Discover before specializing.** Start broad (list the tree, read the README if any, enumerate top-level entries), then drill into whatever signals you actually found.
3. **Signals if present.** Each heuristic is "look for these; if none are found, say so." Always have a "none found" answer.
4. **Evidence-or-gap.** Every claim cites the file(s) it came from. If a fact is not determinable, report it as a gap - do not guess.
5. **Read-only.** Never modify the repo.

## Discovery order

1. List the repository tree (top levels first; note depth, file count, dominant file extensions).
2. Read root docs if present: `README*`, `docs/`, `CONTRIBUTING*`, `ARCHITECTURE*`, wiki exports.
3. Enumerate manifests/config at root and one level deep.
4. Branch into the category-specific signals below based on what was found.
5. If the repo is empty/near-empty or docs-only, record that as the primary finding.

## Signals by topic

Use only what is relevant to the requesting category.

### Technologies
- Manifests/lockfiles (open-ended examples): `package.json`/`*-lock*`, `pyproject.toml`/`requirements*.txt`/`Pipfile`, `go.mod`, `pom.xml`/`build.gradle*`, `Cargo.toml`, `*.csproj`/`*.sln`, `Gemfile`, `composer.json`, `mix.exs`, `pubspec.yaml`, `deno.json`, etc.
- Version pins: `.nvmrc`, `.python-version`, `.tool-versions`, `runtime.txt`, language toolchain files.
- Containers/infra: `Dockerfile*`, `docker-compose*`, `*.tf`, `*.tfvars`, Helm `Chart.yaml`/`values.yaml`, `k8s`/`manifests` YAML, `serverless.yml`, `Pulumi.*`.
- CI/CD: `.github/workflows/*`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `Jenkinsfile`, `.circleci/`, `bitbucket-pipelines.yml`.
- Observability/ops: logging, metrics, tracing configs; `Procfile`; process managers.
- None found: state "no manifests/config detected; technology stack not determinable from repository."

### Components / Modules
- Monorepo/workspace markers: `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, Cargo workspaces, Gradle multi-project, `go.work`, `packages/`, `apps/`, `services/`.
- Otherwise infer building blocks from top-level directories, package/namespace declarations, and service/container definitions.
- Note boundaries actually present; do not impose a layered architecture that isn't evidenced.
- None found: describe the flat structure as a single component and note low confidence.

### Business Context (external interfaces / neighbouring systems)
- Outbound: HTTP/SDK clients, third-party libraries, connection strings, broker/queue clients, webhook senders.
- Inbound/contracts: OpenAPI/Swagger, GraphQL schemas, `.proto`, AsyncAPI, route/controller definitions.
- Config: `.env*`/`*.env.example`, secrets references, host/endpoint settings, IaC referencing managed cloud services.
- None found: "no external integrations detected."

### Core Functions
- README "features"/"usage", entrypoints (`main`, `index`, CLI definitions, `bin/`), exported public API, route/handler maps, scheduled jobs, user-facing screens.
- Tests often reveal intended behavior - read test names/descriptions.
- None found: derive cautiously from directory/file names and mark low confidence.

### Quality Requirements (evidence only)
- Performance/load tests, benchmarks, caching layers, rate limiting, retries/circuit breakers, pooling.
- Security: auth middleware, input validation, dependency scanning, secrets management, `SECURITY.md`.
- Reliability/ops: health checks, readiness/liveness, retries, SLO/SLA mentions, error budgets.
- Usability/accessibility: a11y tooling/tests, i18n.
- None found: report that quality goals are not evidenced and need human confirmation.

### Core Decisions
- ADRs: `docs/adr/`, `adr/`, `decisions/`, `*.adr.md`, files matching `NNNN-*.md` with "Decision"/"Context"/"Consequences" headings.
- Design docs/RFCs, `ARCHITECTURE.md`, deprecation notes, large refactor commits/tags in git history (if available).
- None found: "no decision records found."

### Risk signals
- `TODO`/`FIXME`/`HACK`/`XXX` markers, deprecated dependency warnings, abandoned/`@deprecated` code.
- Missing tests, missing CI, missing docs, no license.
- Single points of failure, hardcoded secrets/credentials, very large or very old files, vendored copies.
- None found that are notable: say so.

## Efficiency notes

- Prefer breadth-first listing and targeted reads over reading everything. Sample representative files.
- Cap deep dives; if a directory is huge, summarize by file types and counts rather than reading all of it.
- Return only distilled findings with evidence tags - not raw file dumps.
