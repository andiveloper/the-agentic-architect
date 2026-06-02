---
name: analyze-commits
description: Orchestrates a fast, diagnostic read of a repository's git history before reading any code - code-churn hotspots, contributors and bus factor, bug clusters, project velocity, and firefighting/crisis patterns - and assembles them into a single Markdown report. Based on Ally Piechowski's "The Git Commands I Run Before Reading Any Code". Invoke explicitly as /analyze-commits.
disable-model-invocation: true
---

# Analyze Commits

Orchestrates a diagnostic read of the **git history** of the repository currently open in the workspace - before reading a single file. The commit history gives a picture of the project: who built it, where problems cluster, whether the team is shipping with confidence or tiptoeing around land mines.

This tool implements the five diagnostics from Ally Piechowski's [The Git Commands I Run Before Reading Any Code](https://piechowski.io/post/git-commands-before-reading-code/) and merges them into a single Markdown report.

## Goal

Tell the reader **which code to read first and what to look for** when they get there - the difference between spending the first day reading methodically versus wandering. Five diagnostics, each from one git command, plus one cross-reference:

1. **Churn hotspots** - what changes the most.
2. **Contributors & bus factor** - who built this, and is the knowledge concentrated or gone.
3. **Bug clusters** - where bugs keep getting patched.
4. **Velocity** - is the project accelerating or dying.
5. **Firefighting** - how often the team is in crisis mode (reverts/hotfixes).
6. **Cross-reference** - files that are high-churn **and** high-bug are the single biggest risk.

You coordinate; **five readonly subagents** each run one git diagnostic in its own context window (the raw output is large and noisy) and return a compact, interpreted fragment. Keep your own context lean: launch all five in parallel, then assemble their fragments into the report. Read the `git-history-diagnostics` skill for the exact commands, interpretation rules, and output template.

## The subagents

One subagent per diagnostic - launch all five with the Task tool in a single message (parallel), each passed the repository root path:

- `commit-churn-analyst` - diagnostic 1: churn hotspots (detects the source dir).
- `commit-contributors-analyst` - diagnostic 2: contributors & bus factor.
- `commit-bug-cluster-analyst` - diagnostic 3: bug clusters.
- `commit-velocity-analyst` - diagnostic 4: velocity (commits per month).
- `commit-firefighting-analyst` - diagnostic 5: firefighting / crisis patterns.

Each returns only its own fragment (defined in `git-history-diagnostics`). The cross-reference (diagnostic 6) is computed by you from the churn and bug-cluster fragments.

## Workflow

Copy this checklist and track progress:

```
- [ ] Step 0: confirm this is a git repo; detect existing report -> initial vs update run
- [ ] Launch the 5 diagnostic subagents in parallel (one git command each)
- [ ] Assemble the fragments into the report template; compute the high-risk cross-reference
- [ ] Write docs/commit-analysis.md (merge if updating)
- [ ] Summarize the verdict: top risks, bus factor, velocity trend, and any data caveats
```

### Step 0 - Preconditions and run type

1. Confirm the workspace is a git repository (`git rev-parse --is-inside-work-tree`). If not, stop and tell the user this tool needs git history.
2. Check whether `docs/commit-analysis.md` already exists.
   - **It does not exist** - **initial run**. Proceed normally.
   - **It exists** - **update run**. Read it first and carry forward human-authored content (notes, answered questions, manual interpretation). Refresh the data-derived sections against the current history and conform the output to the **current** template; note in your summary anything human-authored that no longer has a home.

### 1 - Run the diagnostics (5 parallel subagents)

Launch all five diagnostic subagents with the Task tool **in a single message** (parallel), each passed the **repository root path**:

- `commit-churn-analyst` (diagnostic 1)
- `commit-contributors-analyst` (diagnostic 2)
- `commit-bug-cluster-analyst` (diagnostic 3)
- `commit-velocity-analyst` (diagnostic 4)
- `commit-firefighting-analyst` (diagnostic 5)

Each runs only its own git command in its own context window and returns only its fragment (defined in `git-history-diagnostics`), including any data caveats it detected (e.g. squash-merge workflow, sparse commit messages, shallow clone).

### 2 - Assemble

1. Load the template from the `git-history-diagnostics` skill (`assets/template.md`).
2. Fill each section from the matching subagent fragment. Keep the raw top-N lists compact (file path + count).
3. **Compute the cross-reference yourself**: intersect the top ~5 churn files with the bug-cluster files. Files on both lists are the highest-risk code - list them explicitly in the "Highest-risk files" section.
4. Write the **verdict / executive summary** at the top: the 3-5 things the reader should know before opening the code (e.g. "`X` is high-churn and high-bug - read it first", "bus factor is 1: `author` wrote 70% and last committed 8 months ago", "velocity halved in `<month>`", "12 reverts in the last year - the team doesn't trust its deploys").
5. Carry forward every **data caveat** the subagents flagged - they change how the numbers should be read.

### 3 - Write and summarize

1. Write the report to `docs/commit-analysis.md` (create `docs/` if needed).
   - **Initial run:** write the assembled document.
   - **Update run:** reconcile with the existing file - refresh data sections, preserve human-authored notes; only fall back to a full overwrite (after confirming with the user) if it cannot be cleanly merged.
2. Report a short summary to the user: the verdict (top risks, bus factor, velocity trend, firefighting frequency) and any caveats that limit confidence.

## Rules

- **Read-only on the repo.** Only run the `git log` / `git shortlog` diagnostics; never mutate history or working tree.
- **Black-box.** No assumptions about language, framework, or layout. Detect the source directory for the churn command rather than hardcoding `src/`.
- **Evidence-or-gap.** Every claim ties back to the git output. State data caveats (squash-merge compresses authorship, sparse commit messages weaken bug clustering, shallow clones truncate history) instead of overclaiming.
- **Interpret, don't just dump.** The value is the verdict and the cross-reference, not the raw lists. Keep the report concise and scannable.
