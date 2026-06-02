# ACC field reference

Full arc42 prompting questions for each category, plus what is typically repo-derivable versus human-only. Source: <https://canvas.arc42.org/architecture-communication-canvas>.

## Value Proposition

Answer at least one:
- What are the system's major objectives?
- What value does the system deliver to the customer?
- What are the major business goals of the system?
- Why is the system built and operated?
- What is its core responsibility?

Repo signal: README intro, product docs, marketing copy, package descriptions. Mostly human / strategy doc.

## Key Stakeholder

- For whom are we creating value?
- Who is paying for development? For operations?
- Who are our most important customers? Contributors?

Repo signal: CODEOWNERS, AUTHORS, MAINTAINERS, contributor list, git authors, funding files. Business stakeholders are human-only.

## Core Functions

- Most important functions, features, or use-cases?
- What activities or processes does it offer? The major use-case?
- Which functions generate high value? Which are risky/critical?

Repo signal: README features, entrypoints, public API surface, route definitions, CLI commands, exported modules, user-facing flows.

## Quality Requirements

Important quality goals: speed, scalability, reliability, usability, security, safety, capacity, flexibility, etc. (130+ attributes on the arc42 quality site.)

Repo signal: performance/load tests, caching, rate limiting, retries/circuit breakers, security middleware, SLAs/SLOs in config or docs, accessibility tooling. Actual prioritized goals usually need human confirmation.

## Business Context

Which external systems / interfaces / neighbouring systems:
- are the most important data sources or sinks?
- determine reliability, availability, performance?
- are volatile or risky? have high operational cost? are hard to operate/monitor?

Repo signal: external API clients, third-party SDKs, env vars / secrets referencing hosts, DB/broker connection strings, webhooks, IaC referencing managed services, OpenAPI/proto contracts.

## Components / Modules

Major building blocks: modules, subsystems, packages, components, services.

Repo signal: top-level directory structure, workspace/monorepo manifests, service folders, package boundaries, module/namespace declarations, container/service definitions.

## Core Decisions (Good or Bad)

Which decisions:
- led to the current state?
- are you especially proud of?
- turned out dubious, wrong, or painful?
- can't be understood from today's perspective?

Repo signal: ADRs (e.g. `docs/adr`, `*.adr.md`, `decisions/`), design docs, RFCs, notable git history, deprecation notes. The good/bad judgement and rationale need human input.

## Technologies

Important technologies for development and operation:
- programming languages and technologies
- frameworks
- database or middleware
- infrastructure (hardware, server, datacenter, cloud provider)
- operating environment
- monitoring and administration

Repo signal: package manifests + lockfiles, language/runtime version files, Dockerfiles/compose, CI configs, IaC (Terraform/Helm/k8s), observability configs.

## Risks and Missing Information

- Known problems? Parts known to cause trouble in implementation/test/operation?
- Which processes cause problems? What hinders value generation?
- What would you like to know but cannot find out?

Repo signal: TODO/FIXME/HACK markers, deprecated dependencies, missing tests/CI/docs, single points of failure, security advisories, large/old files, flaky areas. Also aggregates unresolved gaps from every other category.
